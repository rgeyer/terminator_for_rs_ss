from django.db import models
from www.models.terminate_session import terminate_session

class rightscale_account(models.Model):
    class Meta:
        app_label = 'www'

    account_id = models.IntegerField()
    refresh_token = models.CharField(max_length=40)
    name = models.CharField(max_length=255)
    cm_uri = models.CharField(max_length=255)
    ss_uri = models.CharField(max_length=255)

    def active_session_count(self):
        return len(terminate_session.objects.filter(rightscale_account=self, cat_end_time__isnull=True))
