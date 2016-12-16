from www.models.rightscale_account import rightscale_account

def layout(request):
    accounts = rightscale_account.objects.all()
    return {'rightscale_accounts': accounts}
