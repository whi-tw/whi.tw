FROM hugomods/hugo:go-git-0.129.0 AS build
ARG HUGO_BUILDDRAFTS=false
ARG HUGO_BASEURL=/ell

ADD src /src/src

WORKDIR /src/src

RUN mkdir /build/ \
    && hugo -d /build

FROM caddy:2.8.4-alpine
ENV PORT=8080

COPY Caddyfile /etc/caddy/Caddyfile
COPY --from=build /build /srv/ell/

EXPOSE 8080
