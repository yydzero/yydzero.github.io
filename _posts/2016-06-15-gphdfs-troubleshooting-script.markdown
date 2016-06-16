---
layout: post
title:  "GPHDFS troubleshooting script"
subtitle: GPDB GPHDFS 调试用CLI脚本
author: 姚延栋
date:   2016-06-15 12:20
categories: gpdb gphdfs script
published: true
---

## Script to perform simple gphdfs env check


	$ cat gphdfs_check.sh

	export HADOOP_HOME=/usr/lib
	source $GPHOME/lib/hadoop/hadoop_env.sh

	export CLASSPATH=$CLASSPATH:$GPHOME/lib/hadoop/cdh4.1-gnet-1.2.0.0.jar:.
	export JAVA_HOME=/opt/jdk
	export PATH=$JAVA_HOME/bin:$PATH

	# uncomment out this if want to test writable gphdfs external table
	# java $GP_JAVA_OPT -classpath $CLASSPATH com.emc.greenplum.gpdb.hdfsconnector.HDFSWriter 1 1 TEXT cdh4.1 gphdfs://nameservice1/max/data1.txt

	java $GP_JAVA_OPT -classpath $CLASSPATH com.emc.greenplum.gpdb.hdfsconnector.HDFSReader 1 1 TEXT cdh4.1 gphdfs://ard3:9999/test/file

Adjust following variables according to your env:

* HADOOP_HOME
* CLASSPATH
* JAVA_HOME
* HDFS file url
* gphdfs version according to your hadoop version. Use 'cdh4.1' and its corresponding jar in above example.

	    {"gphd-1.0", "gphd-1.0-gnet-1.0.0.1"},
        {"gphd-1.1", "gphd-1.1-gnet-1.1.0.0"},
        {"gphd-1.2", "gphd-1.2-gnet-1.1.0.0"},
        {"gphd-2.0", "gphd-2.0.2-gnet-1.2.0.0"},
        {"gpmr-1.0", "gpmr-1.0-gnet-1.0.0.1"},
        {"gpmr-1.2", "gpmr-1.2-gnet-1.0.0.1"},
        {"cdh3u2",   "cdh3u2-gnet-1.1.0.0"},
        {"cdh4.1",   "cdh4.1-gnet-1.2.0.0"},
        {"hdp2",     "cdh4.1-gnet-1.2.0.0"},
        {"hadoop2",  "cdh4.1-gnet-1.2.0.0"},
        {"cdh5",     "cdh4.1-gnet-1.2.0.0"},
        {"gphd-3.0", "gphd-2.0.2-gnet-1.2.0.0"},
