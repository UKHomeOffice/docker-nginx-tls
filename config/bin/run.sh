#!/bin/bash

CERTS_DIR=${CERTS_DIR:-/etc/secrets}
NGINX=${NGINX:-/usr/sbin/nginx}
NGINX_DIR=${NGINX_DIR:-/etc/nginx}
NGINX_CONF=${NGINX_CONF:-${NGINX_DIR}/nginx.conf}
NGINX_CONFD=${NGINX_COND:-${NGINX_DIR}/conf.d}
PROXIES=()

usage() {
  cat <<EOF
  Usage: $(basename $0)
    -c|--confd DIRECTORY      : the path of the nginx conf.d directory (default $NGINX_CONFD)
    -d|--dir DIRECTORY        : the directory which contains the certificates (default $CERTS_DIR)
    -p|--proxy SPEC           : the specification for a proxy
    -h|--help                 : display this usage menu
EOF
  [ -n "$@" ] && {
    echo ""
    echo "[error] $@";
    exit 1;
  }
  exit 0
}

annonce() {
  [ -n "$@" ] && { echo "[v] $@"; }
}

start_nginx() {
  annonce "starting the nginx service"
  nginx -c $NGINX_CONF || usage "unable to start the nginx service"
}

# validate_specs ... validates the proxy spec are good to go
validate_specs() {
  for i in "${PROXIES[@]}"; do
    if [[ "$i" =~ ^([0-9]{2,5}):([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}):([0-9]{2,5}):(.*)$ ]]; then
      annonce "proxy spec: '$i' is valid"
    else
      usage "the spec: '$i' is invalid, format: <LISTEN_PORT>:<IP>:<LOCAL_PORT>:<CERT>"
    fi
  done
}

# watch_certificates ... monitors the directory and looks for any changes in the certs
watch_certificates() {
  annonce "watching the directory: $CERTS_DIR for changes"
  inotifywait -q -m -r -e close_write -e moved_to $CERTS_DIR |
  while read line; do
    # step: check this a certificate change
    [[ "${line}" =~ ^.*\.crt$ ]] || continue
    annonce "${line} has changed, reconfiguring the service now"
    # step: reconfigure the nginx proxy
    nginx_config
    # step: reload the service
    nginx_reload
  done
}

# nginx_config ... reconfigure the nginx configs
nginx_config() {
  annonce "reconfiguring the nginx service"
  for name in "${PROXIES[@]}"; do
    annonce "configuring the nginx proxy: $name"
    # step: we need to parse the proxy spec and extract the arguments
    [[ "$name" =~ ^([0-9]{2,5}):([0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}):([0-9]{2,5}):(.*)$ ]]
    remote_port=${BASH_REMATCH[1]}
    local_address=${BASH_REMATCH[2]}
    local_port=${BASH_REMATCH[3]}
    certificate=${BASH_REMATCH[4]}
    filename="${NGINX_CONFD}/${certificate}.conf"
    protocol="http"

    # step: attempt to guess the protocol
    [[ "${local_port}" =~ ^443$ ]] && protocol="https"

    # step: check the certificate files are there
    [ -e "${CERTS_DIR}/${certificate}.crt" ] || {
      annonce "the certificate file: ${CERTS_DIR}/${certificate}.crt does not exist";
      continue;
    }
    [ -e "${CERTS_DIR}/${certificate}.key" ] || {
      annonce "the certificate file: ${CERTS_DIR}/${certificate}.key does not exist";
      continue;
    }

    cat <<-EOF > "${filename}"
server {
  listen ${remote_port};
  server_name ${certificate};

  ssl on;
  ssl_certificate      ${CERTS_DIR}/${certificate}.crt;
  ssl_certificate_key  ${CERTS_DIR}/${certificate}.key;

  location / {
    proxy_pass ${protocol}://${local_address}:${local_port};
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto $scheme;
  }
}
EOF
  done
}

# nginx_config ... check the config and if everthing is ok, reload nginx
nginx_reload() {
  # step: check the nginx config and if ok, restart the service
  if ! $NGINX -c $NGINX_CONF -t >/dev/null 2>/dev/null; then
    annonce "the nginx config test failed, refusing to restart the nginx service"
    $NGINX -c $NGINX_CONF -t
    return
  fi
  annonce "nginx config passed validation, reloading service"
  # step: restart the service
  $NGINX -s reload || annonce "failed to reload the nginx service"
}

# step: grab the command line options
while [ $# -gt 0 ]; do
  case "$1" in
    -d|--dir)     CERTS_DIR=$2; shift 2 ;;
    -p|--proxy)   PROXIES=("${PROXIES[@]}" "$2"); shift 2 ;;
    -d|--dryrun)  DRYRUN=1; shift 1 ;;
    -h|--help)    usage; ;;
    *)            shift 1 ;;
  esac
done

# step: validate the options
[ -z "$CERTS_DIR" ] && usage "you have not specified a certificates directory"
[ -d "$CERTS_DIR" ] || usage "the certificates directory: $CERTS_DIR is not a directory"
[ ${#PROXIES[@]} -le 0 ] && usage "you have not specified any proxy specifications"

# step: validate the proxy specs
validate_specs
# step: kick off a configure
nginx_config
# step: start the nginx process
start_nginx
# step: jump into the watch_certificates
watch_certificates
