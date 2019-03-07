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

## 1. clone repo
use you own HCG creditials
```
git clone https://git.homecredit.net/bigdata/anaconda-builder.git
```

## 2. build

set path to maven in build.sh

Run buid
```
anaconda-builder/build.sh all
```


## 3. copy into CM dirs
```
scp -f target/parcel/*.parcel <CM host>:/opt/cloudera/parcel-repo/
```

## 4. distribute and activate parcel
visit page https://<CM host>:7183/cmf/parcel/status and click on button "check of New Parcels"
___... wait a minutes___ and 
set `distribute` netdata and then `activate` it


## 5. Restart Netdata app

If not alredy done, deploy latest netdata csd from 

http://cdh01.nxiii.cc:7180/cmf/csd/refresh
http://cdh01.nxiii.cc:7180/cmf/csd/install?csdName=netdata-1.12.2
http://cdh01.nxiii.cc:7180/cmf/csd/reinstall?csdName=netdata-1.12.2

https://git.homecredit.net/bigdata/zeppelin-livy-builder/tree/master/target/csd

Restart Livi


## 6. Test in zeppelin

run
```
%livy2.pyspark
spark.version
```

-> result should be 3.7.0 (default, Jun 28 2018, 13:15:42) 

Run
```
%livy2.pyspark
   def import_pandas(x):
   import pandas
   return x

int_rdd = sc.parallelize([1, 2, 3, 4])
int_rdd.map(lambda x: import_pandas(x))
int_rdd.collect()
```

-> [1, 2, 3, 4]


Example of connection to oracle database 

```
%livy2.pyspark
from __future__ import print_function

import cx_Oracle

# Connect as user "hr" with password "welcome" to the "oraclepdb" service running on this computer.
##con = cx_Oracle.connect("proxy_obi", "proxy_obi", "(description=(address=(protocol=tcp)(host=infhs02.ph.infra)(port=1521))(connect_data=(ur=a)(service_name=ph00c1hd.ph.infra)(server=dedicated)))")
con = cx_Oracle.connect("xx", "xx", "(description=(address=(protocol=tcp)(host=infid01.id.infra)(port=1521))(connect_data=(ur=a)(service_name=idtools.id.infra)(server=dedicated)))")
ver = con.version.split(".")

## db version
print(ver)


cur = con.cursor()
cur.execute('select * from global_name')
for result in cur:
    print (result)
cur.close()
con.close()

```


# TODO
- edit download function
