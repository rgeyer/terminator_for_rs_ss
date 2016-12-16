from django.http import HttpResponse, HttpResponseNotFound
from django.views.generic import View
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from rest_framework import serializers, viewsets
from rest_framework.permissions import IsAuthenticated
from www.models.terminate_session import terminate_session
from datetime import datetime

import logging

@method_decorator(csrf_exempt, name='dispatch')
class session(View):

    http_method_names = ['post']

    def post(self, request, *args, **kwargs):
        acceptable_actions = ['start']
        action = kwargs['action']

        if action not in acceptable_actions:
            return HttpResponseNotFound("No action %s for sessions" % action)
        elif action == 'start':
            session = session.getblah()

        return HttpResponse(action)

class session_serializer(serializers.HyperlinkedModelSerializer):
    cat_start_time=serializers.DateTimeField(input_formats=['iso-8601','YYYY/MM/DD hh:mm:ss'])

    class Meta:
        model = terminate_session
        fields = ['id',
            'skynet_start_time',
            'cat_start_time',
            'cat_version_requested',
            'cat_version_reported',
            'cat_end_time',
            'cloud_app_href',
        ]


class session_viewset(viewsets.ModelViewSet):
    permission_classes = (IsAuthenticated,)
    queryset = terminate_session.objects.exclude(cat_end_time__isnull=False)
    serializer_class = session_serializer

    def partial_update(self, request, *args, **kwargs):
        logger = logging.getLogger(__file__)
        logger.debug("Patch Request.. "+str(request.data))
        if 'cat_start_time' in request.data:
            logger.debug("Attempting to update CAT Start Time")
            if request.data['cat_start_time'] == 'now':
                # request.data._mutable = True
                request.data['cat_start_time'] = datetime.now().isoformat()
        return super(viewsets.ModelViewSet, self).partial_update(request,args,kwargs)
