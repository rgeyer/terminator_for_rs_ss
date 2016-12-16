#!/bin/bash -e
python manage.py runserver 0.0.0.0:80 &
/usr/bin/wstunnel/wstunnel cli -tunnel 'wss://wstunnel1-1.rightscale.com' -server http://localhost -token "$WSTUNNEL_TOKEN"
