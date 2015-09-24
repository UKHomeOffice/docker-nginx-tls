FROM alpine:latest
MAINTAINER Rohith <gambol99@gmail.com>

RUN apk --update add nginx bash inotify-tools

ADD config/nginx/proxy.conf /etc/nginx/conf.d/proxy.conf
ADD config/nginx/nginx.conf /etc/nginx/nginx.conf
ADD config/bin/run.sh /run.sh

CMD [ "/run.sh" ]
