---
layout: post
title:  "setup gpdb with gphdfs and kerberos in Cloudera VM"
subtitle:  "在Cloudera中搭建带gphdfs和kerberos的GPDB"
author: Kuien Liu, Yuan Zhao
date:   2016-12-01 12:53 +0800
categories: tools
published: true
---

## Setup gphdfs environment

* If you need a stand alone hdfs distribution, find the fastest mirror [here](http://www.apache.org/dyn/closer.cgi/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz).
* If you need a running hdfs service. Please refer to (hdfs)[../1.html]
* If you need to setup gphdfs with stand alone hdfs service, please refer to (Peifeng and Haozhou's blog)[http://gpdb.rocks/tools/2016/10/24/gphdfs-format.html]

In following section we record tips on how to setup gphdfs on Cloudera VM.

```sh
echo "export JAVA_HOME=/usr/java/jdk1.7.0.xxx" >> ~/.bashrc
echo "export HADOOP_HOME=/usr/lib/hadoop/client" >> ~/.bashrc

source ~/.bashrc
gpstop -arf
psql postgres
```

in gpdb

```sql
set gp_hadoop_home '/usr/lib/hadoop/client';
set gp_hadoop_target_version 'gphd-2.0';

create external table r (src text)
    location ('gphdfs://quickstart.cloudera:8082/gpdb/')
	format 'text';

select * from r;
```

## Setup kerberos environment

TBD

