import webapp2
import jinja2
import os

from models.rightscale_account import *

class base(webapp2.RequestHandler):

    jinja_environment = jinja2.Environment(
        loader=jinja2.FileSystemLoader(os.path.join(os.path.dirname(__file__),'..','..')),
        extensions=['jinja2.ext.autoescape'],
        autoescape=True)


    def base_template_params(self):
        rightscale_accounts = rightscale_account.query().fetch()
        base_params = {
            "rightscale_accounts": rightscale_accounts
        }

        return base_params
