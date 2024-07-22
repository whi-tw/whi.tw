FROM hugomods/hugo:go-git-0.129.0 AS build
ARG HUGO_BASEURL=/ell
ARG HUGO_BUILDDRAFTS=false

ADD src /src/src

WORKDIR /src/src

RUN mkdir /build/ \
    && hugo -d /build/ell

FROM nginx:1.27.0-alpine
ENV PORT=8080

COPY --from=build /build/ell /usr/share/nginx/html/ell

ADD nginx/default.conf /etc/nginx/templates/default.conf.template

EXPOSE 8080
