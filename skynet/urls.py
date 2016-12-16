"""skynet URL Configuration

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/1.9/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  url(r'^$', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  url(r'^$', Home.as_view(), name='home')
Including another URLconf
    1. Add an import:  from blog import urls as blog_urls
    2. Import the include() function: from django.conf.urls import url, include
    3. Add a URL to urlpatterns:  url(r'^blog/', include(blog_urls))
"""
from django.conf.urls import include, url
from django.contrib import admin
from www.controllers.web import main
from www.controllers.web.rightscale.account.new import new
from www.controllers.web.rightscale.account.account import account
from www.controllers.api.session import session, session_viewset
from www.controllers.api.resource import resource_viewset
from www.controllers.api.module import module

from rest_framework import routers

api_router = routers.DefaultRouter()
api_router.register(r'session', session_viewset)
api_router.register(r'resource', resource_viewset)

urlpatterns = [
    url(r'^api2/', include(api_router.urls)),
    url('', include('social.apps.django_app.urls', namespace='social')),
    url('', include('django.contrib.auth.urls', namespace='auth')),
    url(r'^api/sessions/(?P<sessionid>[0-9a-zA-Z\-]*)/modules/(?P<module>[a-z]*)$', module.as_view()),
    url(r'^api/sessions/(?P<sessionid>[0-9a-zA-Z\-]*)/(?P<action>[a-z]*)$', session.as_view()),
    url(r'^admin/', admin.site.urls),
    url(r'^rightscale/accounts/new', new.as_view()),
    url(r'^rightscale/accounts/(?P<id>[0-9]*)', account.as_view()),
    url(r'^', main.index, name='dashboard'),
]
