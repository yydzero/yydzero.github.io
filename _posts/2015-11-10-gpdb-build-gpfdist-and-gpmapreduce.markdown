---
layout: post
title:  "GPDB: 编译 gpfdist 和 gpmapreduce"
author: 姚延栋
date:   2015-11-10 11:20:43
categories: GPDB gpfdist gpmapreduce
---

### 如何编译 gpfdist

#### 订阅 RHEL 可选repo

gpfdist 编译需要 libyaml-devel，然而默认的RHEL repo不包括 libyaml-devel, 所以需要使用可选的仓库。

    $ sudo subscription-manager repos --enable=rhel-7-server-eus-optional-rpms
    $ sudo subscription-manager repos --enable rhel-6-server-optional-rpms

#### 注册 REDHAT 订阅

    $ unset HISTFILE  
    $ sudo subscription-manager register --username <username> --password <password>
    $ sudo subscription-manager attach --auto

#### 依赖

    $ sudo yum install -y apr-devel apr-util apr-util-devel libevent libevent-devel libyaml libyaml-devel

#### 编译

    $ ./configure --prefix=$HOME/build/gpdb.master
    $ make && make install
    $ make installcheck

