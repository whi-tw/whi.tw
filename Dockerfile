FROM tnwhitwell/docker-nginx-no-kube-probelogs:1.13.12

MAINTAINER Tom Whitwell version: 1.0.3

RUN mkdir /usr/share/nginx/dev /usr/share/nginx/prod
COPY dev /usr/share/nginx/dev/ell
COPY prod /usr/share/nginx/prod/ell
COPY run.sh /run.sh
COPY deploy/nginx/default.conf /etc/nginx/conf.d/default.conf.template

RUN chown -R nginx:nginx /usr/share/nginx && chmod +x /run.sh

CMD /run.sh
