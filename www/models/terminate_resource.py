from django.db import models
from datetime import datetime

class terminate_resource(models.Model):
    class Meta:
        app_label = 'www'

    session=models.ForeignKey('terminate_session', on_delete=models.SET_NULL, null=True, blank=True)
    rs_type=models.CharField(max_length=255)
    action=models.CharField(max_length=64)
    age=models.PositiveIntegerField()
    tags=models.TextField()
    json=models.TextField()
