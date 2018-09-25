---
layout: post
title:  "惊艳：不到三周 Greenplum 内核升级到 PostgreSQL 9.3"
author: Pivotal Greenplum 团队
date:   2018-09-22 06:58 +0800
categories: greenplum
published: true
---


用时不到三周，Greenplum 开源数据平台内核成功升级到 PostgreSQL 9.3!!! 9.2 合并结束后，从8/3到9/4，团队经过了约1个月的修整和各种清理工作，主要是8.4-9.2合并期间遗留的主要 FIXME，为此次9.3顺利升级打下了基础。

```
psql (9.3beta1)
Type "help" for help.

yydzero=# select version();
version
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
PostgreSQL 9.3beta1 (Greenplum Database 6.0.0-alpha.0+dev.11158.gc7649f182f build dev-oss) on x86_64-apple-darwin16.6.0, compiled by Apple LLVM version 8.1.0 (clang-802.0.42), 64-bit compiled on Sep 21 2018 18:37:55 (with assert checking)
(1 row)
```

[9.1 70天](http://greenplum.cn/tools/2018/07/12/postgresql-upgrade-from-9.0-to-9.1.html)，[9.2 用时约72天](http://greenplum.cn/greenplum/2018/08/03/greenplum_has_pg92_kernel.html)，9.3 16天!!! 有关合并细节，请参加[PR #5805](https://github.com/greenplum-db/gpdb/pull/5805)

此次内核升级获得大量9.3新特性。譬如 Lateral 支持（有些情况下还不完善）：

```
yydzero=# SELECT * FROM generate_series(1, 4) AS x, LATERAL (SELECT array_agg(y) FROM generate_series(1, x) AS y ) AS z;
x | array_agg
---+-----------
1 | {1}
2 | {1,2}
3 | {1,2,3}
4 | {1,2,3,4}
(4 rows)
```

于此同时，PostgreSQL 9.4 内核升级的工作于2018-09-24 开始，期待~~~

感谢 PostgreSQL 社区！

## 关于 Greenplum

Greenplum 是全球领先的开源大数据平台。

Greenplum 大数据平台基于MPP（大规模并行处理）架构，具有良好的弹性和线性扩展能力，内置并行存储、并行通讯、并行计算和优化技术，兼容 SQL 标准，具备强大、高效、安全的PB级结构化、半结构化和非结构化数据存储、处理和实时分析能力，同时支持涵盖OLTP型业务的混合负载，为客户打通业务-数据-洞见-业务的闭环，可部署于企业裸机、容器、私有云和公有云中，支撑着全球金融、电信、政府、制造等各行业的大量核心生产系统。

如果你对分布式数据库内核感兴趣，希望成为贡献者或commiter，[可以从这儿开始！](https://github.com/greenplum-db/gpdb/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22)Greenplum社区期待您的参与！

