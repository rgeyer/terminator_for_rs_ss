from www.models.terminate_session import terminate_session
from datetime import datetime, date
from www.models.rightscale_account import rightscale_account
from django.conf import settings
from rest_framework.authtoken.models import Token
from django.contrib.auth.models import User
from requests.exceptions import HTTPError
import requests
import httplib as http_client

import rightscale, copy, cookielib, sys, time

class SessionManager():

    def startSession(self, rsaccount):
        # Uncomment this to see all the requests HTTP output
        #http_client.HTTPConnection.debuglevel = 1

        newSession = terminate_session()
        newSession.skynet_start_time = datetime.now()
        newSession.cat_version_requested = "0.1"
        newSession.rightscale_account = rsaccount

        rsclient = rightscale.RightScale(
            refresh_token=rsaccount.refresh_token,
            api_endpoint=rsaccount.cm_uri
        )

        user = User.objects.create(
            password='non hashed password that you cant actually use to login',
            username='api_service_user_'+str(int(time.time())),
            is_superuser=False,
            first_name='API',
            last_name='Service User',
            email='api@service.user',
            is_staff=False,
            is_active=True,
        )
        token = Token.objects.create(user=user)
        newSession.auth_user = user
        # Save it so we get an id
        newSession.save()

        # Grab the terminator CAT content
        with open(settings.BASE_DIR+'/www/static/terminator.cat.rb', 'r') as myfile:
            cat=myfile.read()

        # Force a login
        rsclient.health_check()

        ssauthuri = "%s/api/catalog/new_session?account_id=%s" % (rsaccount.ss_uri,rsaccount.account_id)
        ssauthclient = copy.deepcopy(rsclient.client)
        ssauthclient.s.headers.pop('X-API-Version')
        resp = ssauthclient.request('get', '/', ssauthuri)

        try:
            ssauthclient.s.headers['X-API-Version'] = '1.0'
            requri = "%s/api/manager/projects/%s/executions" % (rsaccount.ss_uri,rsaccount.account_id)
            option_str = """
            [
                {
                    "name": "skynet_session_id_param",
                    "type": "string",
                    "value": "%d"
                },
                {
                    "name": "skynet_session_token_param",
                    "type": "string",
                    "value": "%s"
                }
            ]
            """
            option_str = option_str % (newSession.id, token.key)
            data = {
                'source': cat,
                'options': option_str,
            }
            req = ssauthclient.request('post', '/', requri, data=data)
            execution_href = req.headers['Location']

            newSession.cloud_app_href = execution_href
            newSession.save()
        except HTTPError as e:
            print e.response.text
            raise e

        return newSession
