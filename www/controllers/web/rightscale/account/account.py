from django.shortcuts import render
from django.shortcuts import redirect
from django.views.generic import TemplateView
from django.http import HttpResponse, HttpResponseNotFound
from www.models.rightscale_account import rightscale_account

import logging

class account(TemplateView):
    template_name = 'rightscale/account/account.html'

    def get_context_data(self, **kwargs):
        if 'id' in kwargs:
            id = kwargs['id']

            account = rightscale_account.objects.get(id=id)
            logger = logging.getLogger(__file__)
            active_sessions = account.terminate_session_set.extra(select={
                'end_is_null': 'cat_end_time is NULL',
            }, order_by=['-end_is_null','-cat_end_time'])
            logger.debug(active_sessions.query)
            active_sessions[0].resources_aggregate()
            return {"account": account, "recent_resources": [], "active_sessions": active_sessions}
