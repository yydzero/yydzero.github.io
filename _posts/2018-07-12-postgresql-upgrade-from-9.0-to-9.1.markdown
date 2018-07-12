---
layout: post
title:  "用时70天 Greenplum 内核从 PostgreSQL 9.0 升级到 9.1"
author: 姚延栋
date:   2018-07-12 12:58 +0800
categories: tools
published: true
---


今天 Greenplum master 内核成功升级到 PostgreSQL 9.1!！

```
yydzero=# SELECT version();
version
———————————————————————————————————————————————————————————————————————————————–
PostgreSQL 9.1beta2 (Greenplum Database 6.0.0-alpha.0+dev.7177.g958a672a74 build dev-oss) on x86_64-apple-darwin16.6.0, compiled by Apple LLVM version 8.1.0 (clang-802.0.42), 64-bit compiled on May 19 2018 13:33:00 (with assert checking)
(1 row)
```

从[3月9号升级到PostgreSQL 9.0](https://digitx.cn/2018/03/10/greenplum-kernel-upgrade-to-pg90/)，到今天完成 9.1 的升级，用时70天，共2034个 commits，堪称神速！有关合并细节，请参加[PR #5008](https://github.com/greenplum-db/gpdb/pull/5008)

随着Greenplum的快速发展，Greenplum受到越来越多的客户、用户、厂商、合作伙伴和教育机构的青睐，成为企业和云上大数据处理、分析和机器学习的首选基础平台。

如果你对内核感兴趣，希望成为贡献者或commiter，[可以从这儿开始！](https://github.com/greenplum-db/gpdb/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22)Greenplum社区期待您的参与！
