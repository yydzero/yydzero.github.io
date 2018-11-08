---
layout: post
title:  "用时 3 周 Greenplum 内核升级到 PostgreSQL 9.4"
author: Greenplum 中国研发中心
date:   2018-10-22 10:58 +0800
categories: greenplum postgresql 内核 MPP
published: true
---


用时3周，Greenplum 开源数据平台内核成功升级到 PostgreSQL 9.4!!! 

[9.1 70天](http://greenplum.cn/tools/2018/07/12/postgresql-upgrade-from-9.0-to-9.1.html)，[9.2 用时约72天](http://greenplum.cn/greenplum/2018/08/03/greenplum_has_pg92_kernel.html)，[9.3 用时16天](http://greenplum.cn/greenplum/2018/09/21/greenplum_has_pg93_kernel.html) 

继9.3以创纪录的速度完成合并后，Greenplum内核团队又顺利的完成了 PostgreSQL 9.4 的升级, 有关这次升级的细节请[看这里](https://github.com/greenplum-db/gpdb/commit/1617960e8ab077988c26bc8d59c5cfbfa608a3fb) 

9.4 有如下主要特性和改进：

* JOSNB: 通过 JOSNB，在SQL数据库中也可以畅享 document store 带来的灵活性，应用中可以同时使用关系模型和文档模型，并且可以在两者之间join。
* 多核并行优化：大幅提升短查询高并发下的性能
* 表修改锁优化：大大降低了事务等待的时间
* 逻辑解码：为 CDC、DR 等方案奠定了基础
* Replication Slot：大大提高了基于流复制高可用性方案的可用性
* Catalog MVCC 支持：提高了元数据处理的并行度和一致性
* 聚集中使用 filter 子句。例如： SELECT id, count(id), count(id) FILTER (where id < 5) FROM tbl GROUP BY id;
* 支持 WITHIN GROUP， unnest 和 WITH ORDINALITY 等增强
* GIN 索引性能和压缩大幅增强
* 物化视图刷新优化：目前还不支持 MPP
* background 进程动态注册：灵活启停后台进程
* pg_stat_statements 视图
* pl/pgsql 支持 stacktrace


感谢 PostgreSQL 社区！

## 关于 Greenplum

Greenplum 是全球领先的开源大数据平台，是能够提供包含实时处理、弹性扩容、弹性计算、混合负载、云原生和集成数据分析等强大功能的大数据引擎。

Greenplum 基于MPP（大规模并行处理）架构构建，具有良好的弹性和线性扩展能力，并内置并行存储、并行通讯、并行计算和优化技术。同时，Greenplum还兼容 SQL 标准，具备强大、高效、安全的PB级结构化、半结构化和非结构化数据存储、处理和实时分析能力，可部署于企业裸机、容器、私有云和公有云中。值得一提的是，作为OLAP型的大数据平台, Greenplum同时还能够支持涵盖OLTP型业务的混合负载，从而帮助客户真正打通业务-数据-洞见-业务的闭环。

 目前，Greenplum 已经为国内外各行各业客户所广泛使用,支撑着全球各大行业的核心生产系统，其涉及领域涵盖金融、保险、证券、通信、航空、物流、零售、媒体、政府、医疗、制造、能源等。

如果你对分布式数据库内核感兴趣，希望成为贡献者或commiter，[可以从这儿开始！](https://github.com/greenplum-db/gpdb/issues?q=is%3Aissue+is%3Aopen+label%3A%22help+wanted%22)Greenplum社区期待您的参与！

