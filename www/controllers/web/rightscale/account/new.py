from django.shortcuts import render
from django.shortcuts import redirect
from django.views.generic import TemplateView
from www.models.rightscale_account import rightscale_account

import rightscale

class new(TemplateView):
    template_name = 'rightscale/account/new.html'

    def post(self, request):
        account_id = request.POST['account_id']
        refresh_token = request.POST['refresh_token']
        ss_uri = request.POST['ss_uri']
        cm_uri = request.POST['cm_uri']
        account = rightscale_account(
            account_id=int(account_id),
            refresh_token=refresh_token,
            ss_uri=ss_uri,
            cm_uri=cm_uri
        )

        rsclient = rightscale.RightScale(refresh_token=refresh_token,api_endpoint=cm_uri)
        rsclient.health_check()
        rsacct_obj = rsclient.accounts.show(res_id=account_id)
        account.name = rsacct_obj.soul['name']

        account.save()
        return redirect('dashboard')

# import webapp2
# import rightscale
#
# from controllers.web.base import base
# from controllers.decorators.user_required import user_required
# from models.rightscale_account import rightscale_account
#
# class new(base):
#     @user_required
#     def get(self):
#         template = self.jinja_environment.get_template('templates/rightscale/account/new.html')
#
#         rsclient = rightscale.RightScale(refresh_token='60d4d3abf1cbf7ce95d5e1aa8ba84cf2cea0e6a1',api_endpoint='https://us-4.rightscale.com')
#         #rsclient.health_check()
#         rsclient.login()
#         #rsaccts = rsclient.get_accounts()
#         #creds = rsclient.credentials.index()
#
#         base_params = self.base_template_params()
#         params = base_params.copy()
#         params.update({
#             "accounts": creds
#         })
#
#         self.response.write(template.render(params))
#
#     @user_required
#     def post(self):
#         account_id = self.request.get('account_id')
#         refresh_token = self.request.get('refresh_token')
#         ss_uri = self.request.get('ss_uri')
#         cm_uri = self.request.get('cm_uri')
#         account = rightscale_account(
#             account_id=int(account_id),
#             refresh_token=refresh_token,
#             ss_uri=ss_uri,
#             cm_uri=cm_uri
#         )
#
#         rsclient = RightScale(refresh_token=refresh_token,api_endpoint=cm_uri)
#         rsclient.health_check()
#         rsacct_obj = rsclient.account.show(res_id=account_id)
#         account.name = rsacct_obj.name
#
#         account.put()
#
#         self.redirect('/')
