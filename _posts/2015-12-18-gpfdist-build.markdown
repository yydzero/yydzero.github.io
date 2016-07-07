---
layout: post
title:  "GPDB: compile gpfdist file server"
subtitle:  "GPDB: 编译 gpfdist 文件服务器"
author: 姚延栋
date:   2015-12-18 10:20:43
categories: gpdb gpfdist
published: true
---

gpfdist 是 GPDB 自带的一个并行文件服务器，可以实现 GPDB 高速数据加载和导出。默认不会编译。下面介绍下怎么
编译这个工具：

    $ sudo yum install apr-devel libevent-devel libyaml-devel

    // prefix 需要和 GPDB 的安装路径相同。
    $ ./configure --prefix=/home/gpadmin/gpdb/gpdb.master/

    $ make && make install
