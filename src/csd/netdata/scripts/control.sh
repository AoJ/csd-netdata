#!/bin/bash

set -exuo pipefail

cdate() {
    echo -en "$(date -u +"%Y-%m-%-dT%H-%M-%SZ")"
}

error() {
    >&2 echo -e "$(cdate) ERROR $*"
    return 255
}

info() {
    [[ -z "${*// }" ]] && return
    >&1 echo -e "$(cdate) INFO $*"
}

info "Running netdata CSD control script..."
info "Detected CDH_VERSION of [$CDH_VERSION]"
info "Got command as $1"
info "env variables $(printenv | grep NETDATA)"

function start() {
    if [[ -z "${NETDATA_HOME:-}" ]]; then
        error "Cannot find netdata home at: $NETDATA_HOME"
    fi
    export PATH="${NETDATA_HOME}/usr/sbin:${NETDATA_HOME}/sbin:${NETDATA_HOME}/bin:${PATH}"
    cd "${NETDATA_HOME}/var/cache/netdata"
    exec netdata -D -p "$NETDATA_SERVER_PORT" -i "$NETDATA_SERVER_HOST"
}


case ${1:-} in
start)
    start
;;
*)
  error "Usage: $0 [start]"
  ;;
esac
