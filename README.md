# Parcel builder

Plugin for Livy to change default python to anaconda stack from parcel. Just activate the parcel and restart livy and then zeppelin already uses the anaconda as a pyspark

## Netdata

Netdata is tool for realtime monitoring server various metrics. Must be compiled with target app path in mind, you must know absolute path of parcels dir for Clouder before build it!

### 1. building
see `dependencies.env` for check dependencies versions.

```
./build netdata /opt/cloudera/parcels
```

*Note: Because of the complexity of compilation in RHEL (centos) distributions, you can use prepared bash script to build in alpine docker version. Just run build_in_docker.sh script in alpine linux distribution (3.5 is minimal version), oneline command to build within docker is simple:*
```
docker run --rm -v "$(pwd)":"$(pwd)" -w "$(pwd)" alpine:3.7 /bin/sh build_in_docker.sh
```

## TODO
- readonly dashboard, see https://docs.netdata.cloud/web/server/
