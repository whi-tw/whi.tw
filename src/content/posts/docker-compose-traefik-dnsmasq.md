---
title: "Automatically generate dnsmasq config from docker-compose files"
date: 2019-01-19T12:05:00+00:00
draft: false
tags: ["docker", "ruby", "dns", "dnsmasq", "orchestration"]
---
<!-- markdownlint-disable MD002 MD022 MD026-->
## Introduction
<!-- markdownlint-enable MD002 MD022 MD026-->

Recently, I've introduced [Pi-hole](https://pi-hole.net/) into my house, both for its ad-blocking capabilities, and to act as a slightly more powerful DNS server than my current home router, a [FRITZ!Box 3490](https://en.avm.de/products/fritzbox/fritzbox-3490/). Although that router looks jazzy as anything, there is no facility to add custom DNS records.

I prefer to run my home docker containers on subdomains, rather than on a path, so having the ability to create internal DNS records is essential.

## Current Setup

So, I run all my containers in multiple docker-compose stacks, all living in one git repository. The first is a 'generic' stack, running [traefik](https://hub.docker.com/_/traefik) and [portainer](https://hub.docker.com/r/portainer/portainer/). I also initialise some networks that are shared across stacks here too.

### `generic/docker-compose.yml`

```yaml
version: '3'
services:
  traefik:
    image: traefik:latest
    command: --web --docker --docker.watch --docker.domain=${DOMAIN} \
             --docker.exposedbydefault=false --logLevel="INFO"
    hostname: traefik
    ports:
      - ${TRAEFIK_LISTEN_IP}:80:80
      - ${TRAEFIK_LISTEN_IP}:443:443
    networks:
      - boxnet
      - monitoring
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ${CONFIG}/traefik:/etc/traefik
    labels:
      traefik.enable: "true"
      traefik.frontend.rule: "Host:traefik.example.com"
      traefik.frontend.whiteList.sourceRange: ${INTERNAL_NET}
      traefik.port: "8080"
    restart: always

  portainer:
    image: portainer/portainer
    restart: always
    ports:
      - "9000:9000"
    networks:
      - boxnet
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ${CONFIG}/portainer:/data
    labels:
      traefik.enable: "true"
      traefik.frontend.rule: "Host:portainer.example.com"
      traefik.frontend.whiteList.sourceRange: ${INTERNAL_NET}

networks:
  boxnet:
    ipam:
      config:
        - subnet: 10.0.0.0/16
  monitoring:
    ipam:
      config:
        - subnet: 10.10.1.0/24
```

Other stacks are all similar to this:

### `monitoring/docker-compose.yml`

```yaml
version: '3'
services:
  grafana:
    image: grafana/grafana:latest
    restart: always
    networks:
      - monitoring
    volumes:
      - ${CONFIG}/grafana:/var/lib/grafana
    depends_on:
      - influxdb
      - prometheus
    environment:
      GF_SERVER_ROOT_URL: https://grafana.example.com
      GF_SECURITY_ADMIN_PASSWORD: ${GRAFANA_PASSWORD}
    labels:
      traefik.enable: "true"
      traefik.port: "3000"
      traefik.frontend.rule: "Host:grafana.example.com"
      traefik.frontend.whiteList.sourceRange: ${INTERNAL_NET}
      traefik.docker.network: generic_monitoring

  prometheus:
    image: prom/prometheus:v2.6.0
    restart: always
    networks:
      - monitoring
      - prometheus
    volumes:
      - ${CONFIG}/prometheus:/prometheus
    command: "--config.file=/prometheus/prometheus.yml --web.external-url=http://localhost/prometheus"
    labels:
      traefik.enable: "true"
      traefik.port: "9090"
      traefik.frontend.rule: "Host:prometheus.example.com"
      traefik.frontend.whiteList.sourceRange: ${INTERNAL_NET}
      traefik.docker.network: generic_monitoring

networks:
  monitoring:
    external:
      name: generic_monitoring
  prometheus:
```

Traefik is really easy to configure via docker labels:

```yaml
labels:
    traefik.enable: "true"
    traefik.port: "9090"
    traefik.frontend.rule: "Host:prometheus.example.com"
    traefik.frontend.whiteList.sourceRange: ${INTERNAL_NET}
    traefik.docker.network: generic_monitoring
```

## The Problem

Now, although I have the labels set up, I need to create and maintain the DNS records for them. This would be possible by just writing out the file manually, but the more containers that are added, the more complex that process would become, and I would rather my compose files be the definitive source of truth.

## The Solution

So I created `gen_docker_dns_records.rb`:

```ruby
#!/usr/bin/env ruby

configuration = {}
File.open(".env", "r") do |file_handle|
  file_handle.each_line do |line|
    e, v = line.split("=", 2)
    configuration[e] = v
  end
end

File.open("pihole/dnsmasq.d/03-docker.conf", "w") do |output_file|
  Dir.glob('../**/docker-compose.yml') do |rb_file|
    puts "Processing #{rb_file.to_s}"
    yaml = YAML.safe_load(File.read(rb_file))
    yaml['services'].each do |name, service |
      next if ! service.key?('labels')
      service['labels'].each do |label, value|
        next if label != "traefik.frontend.rule"
        value.split(";").map do |pair|
          k, v = pair.split(":", 2)
          next if k != "Host"
          if v.start_with?("${")
            v = configuration[v[/\${([a-zA-Z]*)}/,1]].rstrip
          end
          output_file.puts("host-record=#{v.to_s},#{configuration["TRAEFIK_LISTEN_IP"].to_s}")
        end
      end
    end
    yaml = nil
  end
end
```

This script lives inside a directory `networking`, and parses all the files found by glob `../**/docker-compose.yml` (each and every `docker-compose.yml` file in subdirectories of its parent directory).

Each service in these compose files is checked for `label` entries, and the `traefik.frontend.rule` label is extracted. This is then searched for a `Host` configuration variable, and the value is extracted.

A file `pihole/dnsmasq.d/03-docker.conf` is then populated with dnsmasq `host-record` entries. For the above compose files, the following file would be generated assuming `TRAEFIK_LISTEN_IP=10.40.10.2`:

```markup
host-record=traefik.example.com,10.40.10.2
host-record=portainer.example.com,10.40.10.2
host-record=grafana.example.com,10.40.10.2
host-record=prometheus.example.com,10.40.10.2
```

If the `Host` configuration variable starts with "`${`", the value is interpolated from an environment variable with the contents of the braces, ie. with `DOMAIN=example.com`, `${DOMAIN}` would be interpolated to `example.com`.

Each of my stack directories has a `.env` file, which contains environment variables for some containers, and other configuration for `docker-compose` to use. The ruby script ingests this to get access to the `TRAEFIK_LISTEN_IP` environment variable.

This script is then executed from a bash script `reloaddns.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
source .env
export DOCKER_SERVER=dockerhost.example.com
export DOCKER_HOST=tcp://${DOCKER_SERVER}:2375
ruby -ryaml gen_docker_dns_records.rb
rsync -avzP pihole/dnsmasq.d/ ${DOCKER_SERVER}:${CONFIG}/pihole/dnsmasq.d/
docker exec -it networking_pihole_1 pihole restartdns
```

This sets `DOCKER_HOST` to the docker TCP socket on my host machine, generates the dnsmasq config, rsyncs it to the host server, into the directory pihole reads its configuration from, and then runs `pihole restartdns` in the container, to reread the file.

The end result is that my containers are up, being proxied through traefik (which terminates SSL with a certificate generated by [mkcert](https://github.com/FiloSottile/mkcert)), and my DNS points correctly to the right host.

Taadaah.

![EXCITED HAPPY NEW YEAR GIF BY HAZELNUT BLVD](https://media.giphy.com/media/l46CvRFB1GqPYAOis/giphy.gif)

## Future enhancements

The rsync step isn't really ideal, so I plan on converting this code to go and wrapping it up in a container with access to the docker socket - I could then watch the labels on all images and then update the dnsmasq config and trigger the reload automatically. But that's Future Tom's problem.
