---
layout: post
title:  How to build open-sourced Greenplum Database (GPDB) On OSX
subtitle:  "如何在OSX上编译开源 Greenplum Database (GPDB) 代码"
author: Yuan Zhao
date:   2017-02-23 
categories: GPDB
---
本文是在[如何在OSX上编译开源 Greenplum Database (GPDB) 代码](http://gpdb.rocks/gpdb/2015/10/29/how-to-build-gpdb.html)的基础上，提出一些针对OSX的小tips。
1. 首先在配置时，由于在单机上运行，不太需要一些附加的功能，如mapreduce和gpfdist, 所以可以将其禁掉：

```
./configure --with-perl --with-python --with-libxml --disable-mapreduce --disable-gpfdist
```

2. 添加`export PGHOST=localhost`至`~/.bashrc`

3. 修改`/etc/sysctl.conf`文件，并重启：

```
kern.sysv.shmmax=2147483648
kern.sysv.shmmin=1
kern.sysv.shmmni=64
kern.sysv.shmseg=16
kern.sysv.shmall=524288
kern.maxfiles=65535
kern.maxfilesperproc=65535
net.inet.tcp.msl=60
```

4. 将本机的`hostname`与`127.0.0.1`的map写到/etc/hosts中。

5. 受单机性能限制，最好不要同时启动太多个segments。若使用`gpinitsystem`来启动，可以将`clusterConfigFile`中的`CHECK_POINT_SEGMENTS`的值改小；若使用`make cluster`的方式启动，可以改变`Makefile`中的`NUM_PRIMARY_MIRROR_PAIRS`。
