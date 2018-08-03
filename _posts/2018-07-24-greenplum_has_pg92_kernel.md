---
layout: post
title:  "用时72天 Greenplum 内核升级到 PostgreSQL 9.2"
author: Pivotal Greenplum 团队
date:   2018-08-03 09:58 +0800
categories: greenplum
published: true
---


Greenplum 开源大数据平台内核已经成功升级到 PostgreSQL 9.2!!!

```
○ → psql
psql (9.2beta2)
Type "help" for help.

yydzero=# select version();
version
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
PostgreSQL 9.2beta2 (Greenplum Database 6.0.0-alpha.0+dev.7544.g4750e1b655 build dev-oss) on x86_64-apple-darwin16.6.0, compiled by Apple LLVM version 8.1.0 (clang-802.0.42), 64-bit compiled on Aug  2 2018 23:04:02 (with assert checking)
(1 row)
```

从[5月20号升级到PostgreSQL 9.1](http://greenplum.cn/tools/2018/07/12/postgresql-upgrade-from-9.0-to-9.1.html)，到完成 9.2 的升级(2018/08/02)，用时约72天，增加32万行新代码，删除6万旧代码！有关合并细节，请参加[PR #5381](https://github.com/greenplum-db/gpdb/pull/5381)

此次内核升级获得大量新特性，包括Index-only扫描、Group commit、fast-path 锁、优化器参数化路径、SP-GiST、引入checkpoint独立进程、FDW增强、Range数据类型、CTAS等。感谢 PostgreSQL 社区！

除了内核升级，master 也在持续开发其他重要特性，譬如：

* [在线扩容和缩容](https://groups.google.com/a/greenplum.org/forum/#!searchin/gpdb-dev/Online$20expand$20spiking$20update%7Csort:date/gpdb-dev/f5bqTzAZjAs/zZ5Z55TxAwAJ): 无间断不停机不停业务实现数据节点的扩容和缩容。
* [Disk Quota](https://github.com/hlinnaka/pg_quota) 此特性将支持Greenplum和PostgreSQL。
* Greenplum 联邦 （非开源特性）：打通Greenplum集群间的数据通路

Greenplum 5.x 分支也在持续增强中，5.10 刚刚发布了如下新特性：

* [Greenplum Kafka 连接器(非开源特性)](https://content.pivotal.io/pivotal-greenplum/pivotal-greenplum-5-10-introduces-greenplum-kafka-connector-for-real-time-data-loading) 通过集成kafka流处理中枢，Greenplum 将数据分析和商业智能的时效提高到亚秒级，也为 IoT 大数据处理提供大杀器。
* [Hadoop 连接器谓词下推](https://gpdb.docs.pivotal.io/5100/relnotes/GPDB_5100_README.html#topic_xfr_4ym_ndb)：借助谓词下推，可大大提高hadoop外部表的查询效率。

随着Greenplum的快速发展，Greenplum受到越来越多的客户、用户、厂商、合作伙伴和教育机构的青睐，成为企业和云上大数据处理、分析和机器学习的首选基础平台。感谢所有参与者，共建Greenplum大数据生态。

如果你对分布式数据库内核感兴趣，希望成为贡献者或commiter，[可以从这儿开始！](https://github.com/greenplum-db/gpdb/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22)Greenplum社区期待您的参与！

