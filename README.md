#### **Nginx TLS Sidekick**

[![Build Status](https://travis-ci.org/UKHomeOffice/docker-nginx-tls.svg?branch=master)](https://travis-ci.org/UKHomeOffice/docker-nginx-tls)

A small utility container which is responsible to rotating the certificates on a nginx proxy.

```shell
Usage: run.sh
  -c|--confd DIRECTORY      : the path of the nginx conf.d directory (default /etc/nginx/conf.d)
  -d|--dir DIRECTORY        : the directory which contains the certificates (default /etc/secrets)
  -p|--proxy SPEC           : the specification for a proxy
  -h|--help                 : display this usage menu
```

##### **Usage**

```shell
[jest@starfury docker-nginx-tls]$ make demo
sudo docker run -ti  --name nginx-tls --rm -v /home/jest/scm/github/UKHomeOffice/docker-nginx-tls/tests:/etc/secrets gambol99/nginx-tls /run.sh -p 443:127.0.0.1:80:demo.example.com
[v] proxy spec: '443:127.0.0.1:80:demo.example.com' is valid
[v] reconfiguring the nginx service
[v] configuring the nginx proxy: 443:127.0.0.1:80:demo.example.com
[v] starting the nginx service
[v] watching the directory: /etc/secrets for changes
[v] /etc/secrets/ CLOSE_WRITE,CLOSE demo.example.com.crt has changed, reconfiguring the service now
[v] reconfiguring the nginx service
[v] configuring the nginx proxy: 443:127.0.0.1:80:demo.example.com
[v] nginx config passed validation, reloading service
```

A proxy specification takes the form for: LISTENING_PORT:PROXY_IPADDRESS:PROXY_PORT:CERTIFICATE. Multiple endpoints can be defined by repeating the -p|--proxy command line option.
