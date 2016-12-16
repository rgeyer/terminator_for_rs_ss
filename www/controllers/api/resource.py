from rest_framework import serializers, viewsets
from rest_framework.permissions import IsAuthenticated
from www.models.terminate_resource import terminate_resource

class resource_serializer(serializers.HyperlinkedModelSerializer):
    class Meta:
        model = terminate_resource
        fields = [
            'id',
            'action',
            'age',
            'tags',
            'json',
            'session',
            'rs_type',
        ]

class resource_viewset(viewsets.ModelViewSet):
    permission_classes = (IsAuthenticated,)
    queryset = terminate_resource.objects.all()
    serializer_class = resource_serializer
