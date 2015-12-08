---
layout: post
title:  "TPCH 介绍"
author: 姚延栋
date:   2015-12-04 10:20:43
categories: TPCH TPC-H
---

### 介绍

TPC-H 是一个决策支持（Decision Support）性能测试规范。它包括一组面向业务的 ad-hoc 查询和并发数据修改套件。这个规范描述了DS系统基本的
要求：

* 处理大量数据
* 执行复杂查询
* 回答关键业务问题

TPC-H通过执行一组查询来评估一个 DS 系统的性能：

* 回答真实业务问题
* 模拟 ad-hoc 查询（例如使用网页点击查询，譬如查看一个商品的库存）
* 比大多数的 OLTP 事务负责的多
* 查询包含大量的操作符和约束
* 生成大量的数据库操作

运行 TPC-H 的数据库最少需要有来自 10000 个供应商的业务数据。这需要大概10M rows，1G 原始存储空间。

TPC-H 性能指标

* QphH@Size
* $/QphH@Size

### 数据库设计

TPC-H 数据库包括8张表：

* ORDERS: orderkey, custkey, orderstatus, totalprice, orderdate, order-priority, clerk, ship-priority, comment
* LINEITEM: orderkey, partkey, suppkey, linenumber, quantity, extendedprice, discount, tax, returnflag, linestatus, shipdate, commitdate, receipdate, shipinstruct, shipmode, comment
* PARTSUPP: partkey, suppkey, availqty, supplycost, comment
* PART: partkey,name, mfgr, brand, type, size, container, retailprice, comment
* SUPPLIER: suppkey, name, address, namtionkey, phone, acctbal, comment
* CUSTOMER: custkey, name, address, nationkey, phone, acctbal, mktsegment, comment
* NATION: nationkey, name, regionkey, comment
* REGION: regionkey, name, comment

每个table的 cardinality 评估（行数）, 有些受 SF（Scale Factor) 影响

* ORDERS:   1.5M
* LINEITEM: 6M
* PARTSUPP: 800K
* PART:     200K
* SUPPLIER: 10K
* CUSTOMER: 150K
* NATION:   25
* REGION:   5


未完待续