from django.db import models
from django.db.models import Count
from django.contrib.auth.models import User
from django.db.models.signals import pre_delete
from django.dispatch import receiver
from datetime import datetime

import logging

class terminate_session(models.Model):
    class Meta:
        app_label = 'www'

    skynet_start_time = models.DateTimeField()
    cat_start_time = models.DateTimeField(blank=True, null=True)
    cat_version_requested = models.CharField(max_length=16)
    cat_version_reported = models.CharField(max_length=16, blank=True, null=True)
    cat_end_time = models.DateTimeField(blank=True, null=True)
    rightscale_account = models.ForeignKey('rightscale_account', on_delete=models.SET_NULL, null=True, blank=True)
    cloud_app_href = models.CharField(max_length=255, blank=True, null=True)
    auth_user = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True)
    # TODO: Maybe add an "ended reason" field? Did it timeout, did it never start, did the CAT finish?

    # Doesn't save, so you should do that yourself
    def delete_user(self):
        if self.auth_user:
            self.auth_user.delete()
            self.auth_user = None

    # Doesn't save, so you should do that yourself
    def end_session(self):
        self.cat_end_time = datetime.now()
        self.delete_user()

    def resources_aggregate(self):
        aggregate = {}
        logger = logging.getLogger(__file__)
        types = self.terminate_resource_set.values('rs_type').distinct()
        for rs_type in types:
            unwrapped_type = rs_type['rs_type']
            logger.debug(unwrapped_type)
            actions_query = self.terminate_resource_set.filter(rs_type=unwrapped_type).values('action').annotate(total=Count('id'))
            logger.debug(actions_query.query)
            actions = {}
            for action in actions_query:
                actions[action['action']] = action['total']
            aggregate[unwrapped_type] = actions

            logger.debug(aggregate)

        return aggregate



# TODO: Maybe this is not needed, and maybe these should not be deleted ever?
@receiver(pre_delete, sender=terminate_session, dispatch_uid='termiate_session_delete_signal')
def terminate_session_pre_delete(sender, instance, using, **kwargs):
    instance.delete_user()
    instance.save()
