#!/bin/sh
set -eu

sed -i "s|__SERVER_NODE_NAME__|${SERVER_NODE_NAME}|g" \
  /usr/share/nginx/html/index.html \
  /etc/nginx/conf.d/default.conf

exec nginx -g "daemon off;"