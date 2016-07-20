---
layout: post
title:  "Greenplum Database Sandbox and Tutorial"
subtitle:  "通过沙盒来试用GPDB数据库"
author: 刘奎恩/Kuien
date:   2016-07-20 12:08 +0800
categories: coding
published: true
---

## Where to get the GPDB Sandbox?

### Sandbox on Baidu YunPan

* [Greenplum Sandbox 4.3.6 on Baidu YunPan/百度云盘](http://pan.baidu.com/s/1i5jmn2H)

Inner it, you can find the VMWare image of GPDB 4.3.6.1, VMWare Player for windows and Sandbox tutorials. Latest release can be found on Pivotal network.

### Sandbox on Pivotal network

* [Greenplum Release List](https://network.pivotal.io/products/pivotal-gpdb)

* [GPDB 4.3.8 Sandbox](https://network.pivotal.io/products/pivotal-gpdb#/releases/1683/file_groups/411)

### Sandbox on Youtube

* [Greenplum Sandbox](https://www.youtube.com/watch?v=wqHzGxWz5sU)


## How to use it?

1. install vmware player
2. start the GPDB sandbox within vmware
3. login with gpadmin/pivotal
4. ./start\_all.sh
5. psql -l
