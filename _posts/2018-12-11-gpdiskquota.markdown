---
layout: post
title: "Greenplum Diskquota: 细粒度数据库磁盘容量管理扩展"
author: Hubert Zhang
date: 2018-12-11 15:58 +0800
categories: greenplum gpdiskquota
published: true
---

<style>
table{
    border-collapse: collapse;
    border-spacing: 0;
    border:2px solid #000000;
}

th{
    border:2px solid #000000;
}

td{
    border:1px solid #000000;
}
</style>

## gpdiskquota是什么
Greenplum Diskquota 扩展用于控制schema和role等不同数据库对象的磁盘使用量。数据库管理员负责设置schema或者role的磁盘容量上限。Diskquota扩展负责维护磁盘使用量模型，模型记录了当前数据库中schema和role的磁盘使用情况，并将超出上限的schema和role放入黑名单中。Diskquota扩展支持enforcement，当相关schema或者role在diskquota黑名单时，加载数据的查询将被强制取消。

## gpdiskquota架构
gpdiskquota由四部分组成:
1. Quota Status Checker. 该模块作为独立进程，负责维护diskquota模型，计算schema和role的磁盘使用量，并将超出上限的schema和role放入黑名单。
2. Quota Change Detector. 该模块通过一系列Hook函数，负责感知由Insert，Copy，Drop，Vacuum Full等操作引起的磁盘容量变化，并生成活跃数据表的列表。
3. Quota Enforcement Operator. 该模块负责识别schema或者role的容量已经超出上限的查询，并强制取消该查询。
4. Quota Setting Store. 该模块负责存储数据库管理员设置的schema和role的磁盘容量上限。
每个模块和相关算法的详细介绍请参考: [gpdiskquota design wiki](https://github.com/greenplum-db/gpdb/wiki/Greenplum-Diskquota-Design)
![]({{ site.url }}/assets/images/GPdiskquota.png)

## 安装gpdiskquota
1. 默认配置下，编译安装gpdb会自动安装diskquota扩展。
```
cd $gpdb_src; 
make; 
make install;
```

2. 将diskquota设置为shared_preload_libraries
```
# enable diskquota in preload library.
gpconfig -c shared_preload_libraries -v 'diskquota'
# restart database.
gpstop -ar
```

3. 配置diskquota相关GUC
```
# set monitored databases
gpconfig -c diskquota.monitor_databases -v 'postgres'
# set naptime (second) to refresh the disk quota stats periodically
gpconfig -c diskquota.naptime -v 2
```

4. 在开启diskquota的数据库中创建diskquota扩展
```
create extension diskquota;
```

5. 通过GUC，配置开启diskquota扩展的数据库
```
# reset monitored database list
gpconfig -c diskquota.monitor_databases -v 'postgres, postgres2'
# reload configuration
gpstop -u
```

## 使用gpdiskquota
下面，通过一个实际例子，展示如何使用gpdiskquota扩展控制schema的磁盘使用量。
```
create schema s1;
#设置schema磁盘容量上限为1MB
select diskquota.set_schema_quota('s1', '1 MB');
set search_path to s1;
create table a(i int);
# 插入少量数据成功
insert into a select generate_series(1,100);
# 插入超过1MB数据，查询会被取消
insert into a select generate_series(1,10000000);
# Schame容量上限已达到，后续插入查询会被禁止
insert into a select generate_series(1,100);
# 删除schema磁盘容量上限
select diskquota.set_schema_quota('s1', '-1');
# 模型刷新后，可以向该schema插入新数据
select pg_sleep(5);
insert into a select generate_series(1,100);
reset search_path;
```

## 进一步阅读
关于gpdiskquota更深入的设计细节，请参考[gpdiskquota design wiki](https://github.com/greenplum-db/gpdb/wiki/Greenplum-Diskquota-Design)

