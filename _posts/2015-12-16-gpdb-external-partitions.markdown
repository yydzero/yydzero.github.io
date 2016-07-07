---
layout: post
title:  "GPDB: External Table Partition"
subtitle:  "GPDB: 外部表分区"
author: 姚延栋
date:   2015-12-16 10:20:43
categories: gpdb external table partition
published: true
---

### GPDB 外部表分区

GPDB 具有灵活的分区支持能力，可以按照list或者range等进行分区。从 GPDB 4.3.6 之后，分区还可以是外部表。这样数据可以根据访问模式
存储在不同的系统和介质中，而且可以通过数据库进行统一访问和管理。

下面演示下怎么使用外部分区表。


#### 首先创建一个分区表，并初始化一些数据

    CREATE TABLE sales (id int, year int) DISTRIBUTED BY (id) PARTITION BY RANGE (year)
    (
        PARTITION sales2010 START (2010) INCLUSIVE,
        PARTITION sales2011 START (2011) INCLUSIVE,
        PARTITION sales2012 START (2012) INCLUSIVE,
        PARTITION sales2013 START (2013) INCLUSIVE,
        PARTITION sales2014 START (2014) INCLUSIVE,
        PARTITION sales2015 START (2015) INCLUSIVE
    );

    INSERT INTO sales (id, year) VALUES (1, 2015), (2, 2014), (3, 2015), (7, 2011);

    SELECT * FROM sales;
     id | year
    ----+------
      2 | 2014
      7 | 2011
      1 | 2015
      3 | 2015
    (4 rows)

#### 外部数据

GPDB 支持多种外部数据源和数据类型，包括本地文件，HDFS，其他数据库，脚本命令等。 下面以 gpfdist 为例，演示外部数据。

##### 编译并安装 gpfdist

如果是从 GPDB 源代码编译安装，那么默认没有编译 gpfdist。使用下面步骤安装 gpfdist。

    $ cd gpAux/extensions/gpfdist
    $ ./configure --prefix=/home/gpadmin/build/gpdb.master
    $ make && make install

#### 创建外部表

    $ cat ~/tmp/2008.txt
    "2","2008"
    "7","2008"
    "3","2008"

    // 启动 gpfdist 文件服务器
    $ cd ~/tmp
    $ gpfdist -d `pwd`




创建外部表

    CREATE EXTERNAL TABLE ext_sales2008 (LIKE sales)
    LOCATION ('gpfdist://localhost:8080/2008.txt') FORMAT 'csv';

    partition=# SELECT * FROM ext_sales2008 ;
     id | year
    ----+------
      2 | 2008
      7 | 2008
      3 | 2008
    (3 rows)


#### 外部分区

    --- 创建空 2008 分区
    ALTER TABLE sales ADD PARTITION sales2008 START (2008) INCLUSIVE END (2009) EXCLUSIVE;

    partition=# SELECT * FROM sales_1_prt_sales2008;
     id | year
    ----+------
    (0 rows)

    --- 切换分区
    ALTER TABLE sales EXCHANGE PARTITION FOR (2008) WITH TABLE ext_sales2008 WITHOUT VALIDATION;

    SELECT * FROM sales_1_prt_sales2008;
     id | year
    ----+------
      2 | 2008
      7 | 2008
      3 | 2008
    (3 rows)

    --- 一个table，包含所有数据
    SELECT * FROM sales;
     id | year
    ----+------
      2 | 2014
      7 | 2011
      1 | 2015
      3 | 2015
      2 | 2008
      7 | 2008
      3 | 2008
    (7 rows)
