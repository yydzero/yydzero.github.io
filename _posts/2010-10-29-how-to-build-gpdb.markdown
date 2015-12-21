---
layout: post
title:  "如何编译开源 Greenplum Database (GPDB) 代码"
author: 姚延栋
date:   2015-10-29 14:20:43
categories: GPDB
---

本文以 RHEL7 为例介绍如何编译、安装和运行开源 GPDB。 最新的代码（2015/12) 也可以在 RHEL6 上编译了。


### 1. 下载 Greenplum Database 源代码

    $ git clone https://github.com/greenplum-db/gpdb

### 2. 安装依赖库

Greenplum Database 编译和运行依赖于各种系统库和Python库。需要先安装这些依赖。

    $ sudo yum install curl-devel bzip2-devel python-devel openssl-devel
    $ sudo yum install perl-ExtUtils-Embed  # If enable perl
    $ sudo yum install libxml2-devel        # If enable XML support
    $ sudo yum install openldap-devel       # If enable LDAP
    $ sudo yum install pam pam-devel        # If enable PAM

    $ sudo yum install perl-Env             # If need installcheck-good

    $ wget https://bootstrap.pypa.io/get-pip.py
    $ sudo python get-pip.py

    $ sudo pip install psi lockfile paramiko setuptools epydoc

### 3. 编译 Greenplum Database 源代码并安装

假定安装到 $HOME/gpdb.master 目录下

    $ ./configure --prefix=/home/gpadmin/build/gpdb.master --with-gssapi --with-pgport=5432 --with-libedit-preferred --with-perl --with-python --with-openssl --with-pam --with-krb5 --with-ldap --with-libxml --enable-cassert --enable-debug --enable-testutils --enable-debugbreak --enable-depend

    $ make

    $ make install

### 4. 初始化 Greenplum Database 集群

安装了二进制文件后，需要初始化数据库集群。下面在一台笔记本上安装一个GPDB的集群。集群包括一个master，两个segment。

    $ source $HOME/gpdb.master/greenplum_path.sh
    $ gpssh-exkeys -h `hostname`

#### 4.1 生成三个配置文件

    $ cat env.sh
    source $HOME/gpdb.master/greenplum_path.sh
    export PGPORT=5432
    export MASTER_DATA_DIRECTORY=$HOME/data/master/gpseg-1

    $ cat hostfile
    <your_hostname>

    $ cat gpinitsystem_config
    ARRAY_NAME="Open Source GPDB"

    SEG_PREFIX=gpseg
    PORT_BASE=40000

    # 根据需要，修改下面的路径和主机名
    declare -a DATA_DIRECTORY=(/path/to/your/data /path/to/your/data)
    MASTER_HOSTNAME=your_hostname
    MASTER_DIRECTORY=/path/to/your/data/master
    MASTER_PORT=5432

    TRUSTED_SHELL=ssh
    CHECK_POINT_SEGMENTS=8
    ENCODING=UNICODE
    MACHINE_LIST_FILE=hostfile

#### 4.2 初始化 GPDB cluster

    $ source env.sh
    $ gpinitsystem -c gpinitsystem_config -a

初始化成功后，运行一下命令验证系统状态：

    $ psql -l
    $ gpstate

### 5. 简单测试

    $ createdb test
    $ psql test
    test# CREATE TABLE t1 AS SELECT * FROM generate_series(1, 1000);

    test# SELECT gp_segment_id, count(1) FROM t1 GROUP BY gp_segment_id
    gp_segment_id  |  count
    ---------------+---------
            0      |  501
            1      |  499

### 6. 可能问题

* 如果你的系统上已经安装了 PostgreSQL，有可能会有冲突。还没来得及看问题原因
** 这个问题已经解决，GPDB 默认安装路径为 /usr/local/gpsql, 或者可以自定义安装路径，不和 pg 安装目录冲突既可。
* GPDB github 主页上有怎么样初始化 demo cluster 的步骤，不过这个步骤假定安装 3 个primary，3 个mirror，一般笔记本上吃不消。
如果机器够强大，使用 demo cluster 更简单些。
* 如果有什么问题，欢迎使用 GPDB 的邮件列表报告bug： greenplum.org
* 本网站仅是临时GPDB中文网站，请以 greenplum.org 信息为准。
