from django.http import HttpResponse
from django.views.generic import View

class module(View):

    def get(self, request, *args, **kwargs):
        return HttpResponse(kwargs)
