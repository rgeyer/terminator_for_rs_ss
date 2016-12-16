#!/bin/sh -e
docker run --rm -v $(pwd):/tmp -i -t rightscale_selfservice rightscale_selfservice template preprocess /tmp/terminator.cat.rb -o /tmp/www/static/terminator.cat.rb --auth-file=/tmp/auth.yml
