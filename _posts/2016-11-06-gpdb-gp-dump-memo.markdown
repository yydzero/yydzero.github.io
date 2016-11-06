---
layout: post
title:  "How gp_dump works"
author: Pivotal Engineer/姚延栋
date:   2016-11-06 09:00 +0800
categories: gpdb gp_dump pg_dump
published: true
---

# How gp_dump works

## gp_dump

gp_dump 是基于 pg_dump 的并行化 dump 工具, 它使用 utility 模式连接每个 segment, 使用 serializable 事务隔离
模式, 并行在每个节点上 dump catalog 和数据.

gp_dump 在每个 segment 上调用其 agent: gp_dump_agent, 这个工具负责具体的 dump 任务, 譬如导出哪些 catalog, 哪些schema, 哪些表等.

gp_dump.c 的主要工作是处理信号, 创建线程, 等待线程执行结束, 并最终返回等. 一个简答的调用例子:

    $ gp_dump --gp-d /tmp/dump <databaseName>

    $ gp_dump --gp-k 20161103091726_0_2_ --gp-d /tmp/dump -p 25432 -U gpadmin test


gp_dump 的线程入口是 threadProc(). 它执行一个函数来处理 dump 任务.
函数名是 gp_backup_launch, 它会 fork 一个进程来执行命令行程序 gp_dump_agent.

    psql> SELECT * FROM gp_backup_launch('', '20161103232955', '', $$$$, '')

## gp_dump_agent

gp_dump_agent 被 gp_dump 通过 UDF gp_backup_launch 启动. gp_dump_agent 以 utility mode 连接到 segment 的数据库上.

直接调用 gp_dump_agent 的例子:

    $ gp_dump_agent --gp-k 20161103233926_1_1_ --gp-d /tmp/dump -p 15432 -U test  --pre-and-post-data-schema-only test


调试时也可以自己调用 gp_backup_launch 函数. 例如在 master 上直接执行下面的代码, 然后文件中就保存了 dump 出来的 SQL.

    test=# SELECT * FROM gp_backup_launch('/tmp/dump', '20161103233926', '', $$$$, '');
               gp_backup_launch
    --------------------------------------
     /tmp/dump/gp_dump_1_1_20161103233926

从 pg_log 里面可以看到调用的详细信息, 包括所有参数.


### 监控线程

 它会启动一个监控进程: monitorThreadProc:

    /*
     * monitorThreadProc: This function runs in a thread and owns the other
     * connection to the database g_conn_status. It listens using this connection
     * for notifications.  A notification only arrives if we are to cancel.
     * In that case, we cause the interrupt handler to be called by sending ourselves
     * a SIGINT signal.  The other duty of this thread, since it owns the g_conn_status,
     * is to periodically examine a linked list of gp_backup_status insert command
     * requests.  If any are there, it causes an insert and a notify to be sent.
     */


### dumpMain

dumpMain 是其 work horse.

* 使用 `getSchemaData()` 获得 schema 的 metadata 信息, 并且设置各种属性, 譬如是否 dump 等.
* 然后使用 `dumpDumpableObject()` dump 各种类型的对象.