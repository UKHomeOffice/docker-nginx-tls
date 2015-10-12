FROM nginx:1.9.5
MAINTAINER Rohith <gambol99@gmail.com>

RUN DEBIAN_FRONTEND=noninteractive apt update && \
    DEBIAN_FRONTEND=noninteractive apt install -y bash inotify-tools

ADD config/nginx/proxy.conf /etc/nginx/conf.d/proxy.conf
ADD config/nginx/nginx.conf /etc/nginx/nginx.conf
ADD config/bin/run.sh /run.sh

CMD [ "/run.sh" ]
