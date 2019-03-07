#!/bin/sh
set -euxo pipefail

# run with command:
# docker run --rm -v "$(pwd)":"$(pwd)" -w "$(pwd)" alpine:3.7 /bin/sh build_in_docker.sh netdata /opt/cloudera/parcels

# todo make it works with yum group install "Development Tools"
# missing uuid.so in ld
apk update
apk add                                                     \
    bash                                                    \
    wget                                                    \
    curl                                                    \
    ncurses                                                 \
    git                                                     \
    netcat-openbsd                                          \
    alpine-sdk                                              \
    autoconf                                                \
    automake                                                \
    gcc                                                     \
    make                                                    \
    libtool                                                 \
    pkgconfig                                               \
    util-linux-dev                                          \
    openssl-dev                                             \
    gnutls-dev                                              \
    zlib-dev                                                \
    libmnl-dev                                              \
    libnetfilter_acct-dev                                   \
    openjdk8

export PATH="/usr/lib/jvm/java-1.8-openjdk/bin/:$PATH"

./build.sh compile "$@"
./build.sh parcel "$@"
./build.sh csd "$@"