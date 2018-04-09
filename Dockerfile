FROM nginx:alpine

MAINTAINER Tom Whitwell version: 0.1

COPY public /usr/share/nginx/html

RUN chown -R nginx:nginx /usr/share/nginx/html
