FROM nginx:alpine

MAINTAINER Tom Whitwell version: 1.0.2

COPY public /usr/share/nginx/html
COPY deploy/nginx/default.conf /etc/nginx/conf.d/default.conf

RUN chown -R nginx:nginx /usr/share/nginx/html
