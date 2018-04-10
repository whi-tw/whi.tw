FROM nginx:alpine

MAINTAINER Tom Whitwell version: 1.0.2

COPY dev /usr/share/nginx/dev
COPY prod /usr/share/nginx/prod
COPY deploy/nginx/default.conf /etc/nginx/conf.d/default.conf.template
COPY deploy/nginx/nginx.conf /etc/nginx/nginx.conf

RUN chown -R nginx:nginx /usr/share/nginx

EXPOSE 80

STOPSIGNAL SIGKILL

CMD /bin/sh -c "envsubst < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;' || cat /etc/nginx/conf.d/default.conf"
