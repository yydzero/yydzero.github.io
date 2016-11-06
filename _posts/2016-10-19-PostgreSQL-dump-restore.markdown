---
layout: post
title:  "PostgreSQL Dump/Restore"
author: Pivotal Engineer
date:   2016-10-18 11:00 +0800
categories: postgresql dump restore
published: false
---

# PostgreSQL dump/restore

基于 GPDB 5.0 master 代码.

pg_dump 读取系统表信息, 将数据库数据和元数据转储到一个脚本文件中. 以后可以用该文件恢复数据库.

pg_dump 以 serializable 事务隔离级别运行, 所以它看到整个数据库的一个一致性快照, 包括系统表. (PG 9.x
使用 transaction-snapshot 事务级别). 但是需要使用某些 backend 函数, 而这些函数使用 SnapshotNow, 例如 pg_get_indexdef(),
所以可能在执行某些 DDL 修改时, 产生 cache lookup failed 错误. 时间窗口是从开始 serializable 事务到 getSchemaData(),
getSchemaData 需要对所有需要 dump 的表使用 AccessShareLock. 窗口不大, 但是可能发生.

## DumpleObject

DumpableObject 保存系统 catalog 信息, 每个可以 dump 的对象都是 DumpableObject 的子类.