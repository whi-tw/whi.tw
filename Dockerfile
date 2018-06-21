FROM tnwhitwell/docker-nginx-no-kube-probelogs:1.13.12

LABEL "tw.whi"="Tom Whitwell"
LABEL maintainer="tom@whi.tw"

RUN mkdir /usr/share/nginx/site
COPY public /usr/share/nginx/site/ell
COPY deploy/nginx/default.conf /etc/nginx/conf.d/default.conf

RUN chown -R nginx:nginx /usr/share/nginx

CMD nginx -g 'daemon off;' || cat /etc/nginx/conf.d/default.conf
