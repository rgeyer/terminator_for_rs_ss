from django.core.management.base import BaseCommand, CommandError
from www.models.rightscale_account import rightscale_account
from www.models.terminate_session import terminate_session
from www.session_manager import SessionManager
from datetime import datetime

from skynet.rsapiclient import rsapiclient
from requests.exceptions import *

import json

class Command(BaseCommand):
    help = 'Checks the status of all running terminator sessions'

    def handle(self, *args, **options):
        accounts = rightscale_account.objects.all()
        session_manager = SessionManager()
        for account in accounts:
            self.stdout.write(self.style.SUCCESS('Dunno what yet for %s' % account.name))

        sessions = terminate_session.objects.exclude(cat_end_time__isnull=False)
        for session in sessions:
            if session.cloud_app_href:
                rsc = rsapiclient(
                    session.rightscale_account.refresh_token,
                    session.rightscale_account.cm_uri,
                    session.rightscale_account.ss_uri,
                    session.rightscale_account.account_id
                )
                try:
                    cloudapp_uri = "%s%s" % (session.rightscale_account.ss_uri, session.cloud_app_href)
                    cloudapp = rsc.ssclient.request('get', '/', cloudapp_uri)
                    cloudapp_json = json.loads(cloudapp.text)
                    # self.stdout.write(json.dumps(cloudapp_json, sort_keys=True,indent=4, separators=(',', ': ')))
                    if cloudapp_json['status'] in ['running','failed']:
                        ops_uri = "%s%s" % (session.rightscale_account.ss_uri, cloudapp_json['links']['running_operations']['href'])
                        ops = rsc.ssclient.request('get', '/', ops_uri)
                        ops_json = json.loads(ops.text)
                        # self.stdout.write(json.dumps(ops_json, sort_keys=True,indent=4, separators=(',', ': ')))
                        if len(ops_json):
                            self.stdout.write("There were running operations for %s" % (cloudapp_json['href']))
                        else:
                            terminate_uri = "%s/actions/terminate" % (cloudapp_uri)
                            term_response = rsc.ssclient.request('post', '/', terminate_uri)

                    if cloudapp_json['status'] == 'terminated':
                        delete_response = rsc.ssclient.request('delete', '/', cloudapp_uri)
                except HTTPError as httperr:
                    if httperr.response.status_code == 404:
                        self.stdout.write("Cloud App not found for session, so it's time to clean it up")
                        session.end_session()
                        session.save()
                    else:
                        raise httperr
            else:
                session.end_session()
                session.save()
