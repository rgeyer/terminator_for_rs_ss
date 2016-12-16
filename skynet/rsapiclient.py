import rightscale, copy

class rsapiclient:
    def __init__(self, refresh_token, cmuri, ssuri, account_id):
        self.refresh_token = refresh_token
        self.cmuri = cmuri
        self.ssuri = ssuri
        self.account_id = account_id
        self.base_client = rightscale.RightScale(
            refresh_token = self.refresh_token,
            api_endpoint = self.cmuri
        )
        self.base_client.health_check()
        self.cmclient = self.base_client.client

        self.ssclient = copy.deepcopy(self.cmclient)
        self.ssclient.s.headers.pop('X-API-Version')
        authuri = "%s/api/catalog/new_session?account_id=%s" % (self.ssuri,self.account_id)
        ss_auth_response = self.ssclient.request('get', '/', authuri)
        self.ssclient.s.headers['X-API-Version'] = '1.0'
