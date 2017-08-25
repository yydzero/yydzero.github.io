---
layout: post
title:  "gpinitsystem troubleshooting"
author: 姚延栋
date:   2016-07-15 09:49
categories: gpdb gpinitsystem
published: true
---

有时候 gpinitsystem 会失败，但是不清楚失败原因是什么。 下面提供一些思路来 RCA：

* 查看 ~/gpAdmin/gpinitsystem_*** 日志文件
* 进入 master 的日志目录 （例如 /data/master/gpseg-1/pg_log/) 查看日志。 这里面有2种类型的日志：
  * startup.log
  * gpdb-<date>.csv

## 如果使用 mac，则首先 disable MAC 的 SIP 特性

    https://www.igeeksblog.com/how-to-disable-system-integrity-protection-on-mac/

## 初始化 master 数据库失败

手动执行查看错误信息：

    $ initdb -E UNICODE -D /data/master/gpseg-1 --locale=en_US.utf8 --max_connections=250 \
     --shared_buffers=128000kB --is_filerep_mirrored=no --backend_output=/data/master/gpseg-1.initdb


## 如果master 起不来

手动启动master观看日志是否有问题：


Utility mode 启动 master，仅仅允许utility 模式连接。

     $ postgres -D /data/master/gpseg-1 -i -p 5432 -c gp_role=utility -M master -b 1 -C -1 -z 0 -m

## 创建segment

     /home/gpadmin/build/gpdb.master/bin/lib/gpcreateseg.sh 40584 1 sdw13~40006~/data2/primary/gpseg18~20~18~0 
	IS_PRIMARY no 13 /home/gpadmin/gpAdminLogs/gpinitsystem_20160717.log 
	::1~10.153.101.115~192.168.101.115~fe80::92e2:baff:feb1:7904~fe80::ce46:d6ff:fe58:e10c


     cmd='export LD_LIBRARY_PATH=/home/gpadmin/build/gpdb.master/lib:/lib:;/home/gpadmin/build/gpdb.master/bin/initdb  
	-E UNICODE -D /data2/primary/gpseg18 --locale=en_US.utf8  --max_connections=750 --shared_buffers=128000kB 
	--is_filerep_mirrored=no --backend_output=/data2/primary/gpseg18.initdb'

     /bin/ssh sdw13 export 'LD_LIBRARY_PATH=/home/gpadmin/build/gpdb.master/lib:/lib:;/home/gpadmin/build/gpdb.master/bin/initdb' 
	-E UNICODE -D /data2/primary/gpseg18 --locale=en_US.utf8 --max_connections=750 --shared_buffers=128000kB 
	--is_filerep_mirrored=no --backend_output=/data2/primary/gpseg18.initdb


## 启动 segment

     export LD_LIBRARY_PATH=/home/gpadmin/build/gpdb.master/lib:/lib:;export PGPORT=40006; 
     /home/gpadmin/build/gpdb.master/bin/pg_ctl -w -l /data2/primary/gpseg18/pg_log/startup.log 
   	-D /data2/primary/gpseg18 -o "-i -p 40006 -M mirrorless -b 20 -C 18 -z 0" start

## 启动segment出错：

    $ /usr/bin/ssh yydzero.local 'export DYLD_LIBRARY_PATH=/Users/yydzero/work/build/master/lib:/lib:/Users/yydzero/work/build/master/lib:/lib:;export PGPORT=40000; \
        /Users/yydzero/work/build/master/bin/pg_ctl -w -l /Users/yydzero/work/data/master/primary/gpseg0/pg_log/startup.log \
             -D /Users/yydzero/work/data/master/primary/gpseg0 -o "-i -p 40000 -M mirrorless --gp_dbid=2 \
             --gp_contentid=0 --gp_num_contents_in_cluster=0" start'
    waiting for server to start... failed
    pg_ctl: could not wait for server because of misconfiguration

发现上面的命令使用 ssh 运行报 misconfiguration 的错误， 而不使用 ssh 则可以成功运行。

这通常是由于 ssh 改变了环境变量造成的，查看 .bash_profile, .bashrc, 发现 .bashrc 设置了不同的默认 PGHOST，删除这个配置后就可以了。

## gp_bash_functions.sh 函数出错

     /home/gpadmin/build/gpdb.master/bin/lib/gp_bash_functions.sh: line 493: [: -gt: unary operator expected

## 不能连接到server：找不到domain socket

	○ → PGOPTIONS='-c gp_session_role=utility' /Users/yydzero/work/build/master/bin/psql postgres
	psql: could not connect to server: No such file or directory
	Is the server running locally and accepting
	connections on Unix domain socket "/var/pgsql_socket/.s.PGSQL.5432"?

这个通常是由于不同的 psql binary 造成的，也就是说自己编译的 psql 调用了系统的 libpq 库。可以通过 ldd 或者 otool -L 查看。

解决方法：

	export LD_LIBRARY_PATH=/path/to/your/psql/lib

## gpstart 失败，并且原因不明

    $ gpstart -v // 使用 verbose 模式，显示每个执行的命令以及其结果。

遇到的一个问题报错如下： unable to import module: No module named psutil

原因是 psutil 这个python包没有安装，但是使用 python 验证，发现已经安装了。 而使用 ssh 验证发现使用了不同路径的 python。

## 问题

一旦出错，不知道原因是什么。非常难于 trouble shooting。 很多错误直接重定向到 /dev/null 了。

## tricks

### set -x in bin/lib/gp_bash_functions.sh

