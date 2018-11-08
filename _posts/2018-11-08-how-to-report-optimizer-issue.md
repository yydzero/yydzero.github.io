---
layout: post
title:  "如何有效报告 Greenplum 优化器 bug"
author: 零点
date:   2018-11-07 10:58 +0800
categories: greenplum optimizer orca planner
published: true
---


## 需要收集的信息

* 使用传统优化器（常称为 planner）和 ORCA，分别测试下效果 （set optimizer = on)
* 使用 minirepo 收集需要的元数据和统计信息。  分别使用 planner 和 orca，收集问题 SQL 的minirepo。 如果使用了 filespace，则需要额外操作

    1) Add a filespace called testfilespace using:
    gpfilespace -o gpfilespace_config
    (This utility will prompt for the name and location)

    2) The run: gpfilespace --config /home/gpadmin/gpfilespace_config

    3) Then in database "bmadb", create a tablespace called:
    src_fs_01 filespace testfilespace;

    4) Rerun the minirepro.

* 运行 explain，分别针对 planner 和 orca
* 运行 explain analyze，分别针对 planner 和 orca
* 如果有可能，在不同版本的 Greenplum 上进行测试: 4.3.x vs. 5.x
* 使用 gpcheckperf 排除硬件性能问题。

* 其他有用的信息

** 对并发和系统负载进行描述
** 使用 resource group 还是resource queue
** 是否使用了连接池
** 集群大小、schema或者硬件是否发生了变化


