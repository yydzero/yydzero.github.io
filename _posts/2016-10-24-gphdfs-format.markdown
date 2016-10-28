---
layout: post
title:  "setup gphdfs in docker"
subtitle:  "在docker中搭建gphdfs环境"
author: Peifeng Qiu, Haozhou Wang
date:   2016-10-24 16:23 +0800
categories: tools
published: true
---

## Setup gphdfs environment

We need a running hdfs service. Please refer to (hdfs)[../1.html]
We assume the gpdb is setup on local machine.

### Setup hadoop client

Find the fastest mirror [here](http://www.apache.org/dyn/closer.cgi/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz).

We will extract the package at home directory.
Test the hdfs service

```
~/hadoop-2.7.3/bin/hdfs dfs -ls hdfs://172.17.0.7/
```

If you encounter the following error, then the jre version is incorrect.
```
Exception in thread "main" java.lang.UnsupportedClassVersionError: org/apache/hadoop/fs/FsShell : Unsupported major.minor version 51.0
	at java.lang.ClassLoader.defineClass1(Native Method)
	at java.lang.ClassLoader.defineClass(ClassLoader.java:643)
	at java.security.SecureClassLoader.defineClass(SecureClassLoader.java:142)
	at java.net.URLClassLoader.defineClass(URLClassLoader.java:277)
	at java.net.URLClassLoader.access$000(URLClassLoader.java:73)
	at java.net.URLClassLoader$1.run(URLClassLoader.java:212)
	at java.security.AccessController.doPrivileged(Native Method)
	at java.net.URLClassLoader.findClass(URLClassLoader.java:205)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:323)
	at sun.misc.Launcher$AppClassLoader.loadClass(Launcher.java:296)
	at java.lang.ClassLoader.loadClass(ClassLoader.java:268)
	at sun.launcher.LauncherHelper.checkAndLoadMain(LauncherHelper.java:406)
```

### Set the JAVA_HOME env variable to ~/.bashrc, we need java 1.7.

```
export JAVA_HOME=/usr/java/default/

```

### Add hadoop client env variable to ~/.bashrc

```
export HADOOP_USER_NAME=gpadmin
export HADOOP_HOME=/home/gpadmin/hadoop-2.7.3
export PATH=$PATH:$HADOOP_HOME/sbin:$HADOOP_HOME/bin
```

### Restart GPDB
```
gpstop -ar
``` 

### Config gpdb to use gphdfs 2.0 and hadoop clinet

```
gpconfig -c gp_hadoop_target_version -v "'gphd-2.0'"
gpconfig -c gp_hadoop_home -v "'/home/gpadmin/hadoop-2.7.3'"
```

### Test gphdfs

```sql
createdb test
psql test

create readable external table gphdfs_r (a int) location ('gphdfs://172.17.0.7/abc.txt') format 'text';
select * from gphdfs_r

create writable external table gphdfs_w (a int) location ('gphdfs://172.17.0.7/g/') format 'text';
insert into gphdfs_w values(5);
insert into gphdfs_w select * from gphdfs_w;

create readable external table gphdfs_wr (a int) location ('gphdfs://172.17.0.7/g/') format 'text';
select * from gphdfs_wr;



create writable external table gphdfs_custom_w (a int) location ('gphdfs://172.17.0.7/g/') format 'custom' (formatter='gphdfs_export');;
insert into gphdfs_custom_w values(5);

create readable external table gphdfs_custom_wr (a int) location ('gphdfs://172.17.0.7/g/') format 'custom' (formatter='gphdfs_import');;
select * from gphdfs_custom_wr;


```

### Setup and test Parquet format

Download following libraries from [here](http://search.maven.org/#search%7Cga%7C1%7Cparquet) and copy them to $HADOOP_HOME/share/hadoop/common/lib/

```
parquet-hadoop-1.7.0.jar
parquet-common-1.7.0.jar
parquet-encoding-1.7.0.jar
parquet-column-1.7.0.jar
parquet-generator-1.7.0.jar
parquet-format-2.3.0-incubating.jar
```

Test parquet format

```sql
psql test

create writable external table gphdfs_parquet_w (a int, b text) location ('gphdfs://172.17.0.7/parquet/') format 'parquet';
insert into gphdfs_parquet_w values(1, 'aaa');

create readable external table gphdfs_parquet_r (a int, b text) location ('gphdfs://172.17.0.7/parquet/') format 'parquet';
select * from gphdfs_parquet_r
```


### Setup and test Avro format

Download following libraries from [here](http://www.apache.org/dyn/closer.cgi/avro/) and copy them to $HADOOP_HOME/share/hadoop/common/lib/

```
avro-1.8.1.jar
avro-mapred-1.8.1-hadoop2.jar
```

Test avro format

```sql
create writable external table gphdfs_avro_w (a int, b text) location ('gphdfs://172.17.0.7/test/avro/') format 'avro';
insert into gphdfs_avro_w values(1, 'aaa');

create readable external table gphdfs_avro_r (a int, b text) location ('gphdfs://172.17.0.7/test/avro/') format 'avro';
select * from gphdfs_avro_r
```

### Examine avro file using standalone tool

Download avro-tools-1.8.1.jar  from [here](http://www.apache.org/dyn/closer.cgi/avro/).

Get schema
```sh
java -jar avro-tools-1.8.1.jar getschema test.avro
```

Get Data
```sh
java -jar avro-tools-1.8.1.jar tojson test.avro
```

Generate avro file using json data
```sh
java -jar avro-tools-1.8.1.jar fromjson --schema-file test.avsc test.json >test.avro
```