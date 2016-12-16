from django.core.management.base import BaseCommand, CommandError
from www.models.rightscale_account import rightscale_account
from www.session_manager import SessionManager
import uuid

class Command(BaseCommand):
    help = 'Starts a terminating session for all registered RightScale accounts'

    def handle(self, *args, **options):
        accounts = rightscale_account.objects.all()
        session_manager = SessionManager()
        for account in accounts:
            self.stdout.write(self.style.SUCCESS('Generated UUID "%s" for account "%s". Healthcheck is "%s"' % (uuid.uuid4(), account.name, session_manager.startSession(account))))
