FROM tnwhitwell/docker-nginx-no-kube-probelogs:1.13.12

LABEL "tw.whi"="Tom Whitwell"
LABEL maintainer="tom@whi.tw"

COPY build /usr/share/nginx/site
COPY deploy/nginx/default.conf /etc/nginx/conf.d/default.conf

RUN chown -R nginx:nginx /usr/share/nginx

CMD nginx -g 'daemon off;' || cat /etc/nginx/conf.d/default.conf
