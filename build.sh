#!/bin/bash
set -euxo pipefail

source "${BASH_SOURCE%/*}/dependencies.env"

CPUS=$(grep -c ^processor /proc/cpuinfo)

. "${BASH_SOURCE%/*}/src/functions.sh"

app_name="netdata"
app_base="${PARCEL_BASE:-/opt/cloudera/parcels}/$(echo "$app_name" | awk '{print toupper($0)}')"
parcel_dir_tmp="${TARGET_PARCEL}/${app_name}_tmp"
parcel_dir="${TARGET_PARCEL}/${app_name}"


function prepare_parcel_dir_tmp() {

    if [[ -d "$parcel_dir_tmp" ]]; then
        rm -rf "$parcel_dir_tmp"
        mkdir -p "$parcel_dir_tmp"
    fi

    if [[ -d "$parcel_dir" ]]; then
        rm -rf "$dir"
    fi
}


function compile_netdata() {

    download "netdata" "$NETDATA_URL" "$NETDATA_SHA"
    cd "${SRC_EXTERNAL}/netdata"

    export CFLAGS="-static -O1 -ggdb -Wall -Wextra -fstack-protector-all -D_FORTIFY_SOURCE=2 -DNETDATA_INTERNAL_CHECKS=1"

    autoreconf -ivf

    ./configure \
        --prefix="${app_base}/usr" \
        --sysconfdir="${app_base}/etc" \
        --localstatedir="${app_base}/var" \
        --with-zlib \
        --with-math \
        --with-user=root

    make clean
    make "-j${CPUS}"
    make DESTDIR="$parcel_dir_tmp" install

    # clean up
    rm -rf "${parcel_dir_tmp:?}${app_base}/share/"{doc,man,man8}
    mv "${parcel_dir_tmp}${app_base}" "${parcel_dir}"
    rm -rf "${parcel_dir_tmp:?}"
    #tmp
    cp "${SRC}/csd/${app_name}/netdata.conf" "${parcel_dir}/etc/netdata.conf"
}


function compile_bash() {

    download "bash" "$BASH_URL" "$BASH_SHA"
    cd "${SRC_EXTERNAL}/bash"
    ./configure                                             \
        --prefix="${app_base}"                              \
        --without-bash-malloc                               \
        --enable-static-link                                \
        --enable-net-redirections                           \
        --enable-array-variables                            \
        --disable-profiling                                 \
        --disable-nls

    make clean
    make "-j${CPUS}"

    (echo all:; echo clean:; echo install:) > examples/loadables/Makefile

    make DESTDIR="$parcel_dir_tmp" install
}


function  compile_curl () {

    download "curl" "$CURL_URL" "$CURL_SHA"
    cd "${SRC_EXTERNAL}/curl"

    export LDFLAGS="-static"
    export PKG_CONFIG="pkg-config --static"

    ./buildconf

    ./configure                                             \
        --prefix="${app_base}"                              \
        --enable-optimize                                   \
        --disable-shared                                    \
        --enable-static                                     \
        --enable-http                                       \
        --enable-proxy                                      \
        --enable-ipv6                                       \
        --enable-cookies

    # Curl autoconf does not honour the curl_LDFLAGS environment variable
    # hint by netdata
    sed -i -e "s/curl_LDFLAGS =/curl_LDFLAGS = -all-static/" src/Makefile

    make clean
    make "-j${CPUS}"
    make DESTDIR="$parcel_dir_tmp" install
}


function compile_fping() {

    download "fping" "$FPING_URL" "$FPING_SHA"
    cd "${SRC_EXTERNAL}/fping"

    export CFLAGS="-static"

    ./configure                                             \
        --prefix="${app_base}"                              \
        --enable-ipv4                                       \
        --enable-ipv6

    make clean
    make "-j${CPUS}"
    make DESTDIR="$parcel_dir_tmp" install
}


function compile() {
    prepare_parcel_dir_tmp
    compile_bash
    compile_curl
    compile_fping
    compile_netdata
}


function buildParcel() {
    build_cm_ext
    build_parcel "$app_name" "$NETDATA_VERSION"
}


function buildCSD() {
    build_cm_ext
    build_csd "$app_name" "$NETDATA_VERSION" "$NETDATA_VERSION"
}


case ${1:-} in
compile)
    compile
;;
parcel)
    buildParcel
;;
csd)
    buildCSD
;;
all)
    compile
    buildParcel
    buildCSD
;;
*)
  error "Usage: $0 [compile|parcel|csd|all]"
  ;;
esac
