#!/bin/sh
sed 's/_ENVIRONMENT_/${ENVIRONMENT}/' /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf
nginx -g 'daemon off;' || cat /etc/nginx/conf.d/default.conf"