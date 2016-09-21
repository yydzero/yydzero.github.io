---
layout: post
title:  "Debug psql"
date:   2016-08-09 22:24 +0800
categories: psql
published: true
---

# 调试 psql

psql 是 GPDB 和 PostgreSQL 标准的命令行工具,它提供了和数据库交互的最完整/最稳定的 API.
本文介绍如何调试 psql 以回答某些问题.譬如 psql 执行 `SELECT * FROM big_table` 时, psql 是
怎么处理大量数据的?

psql 支持交互式模式和批处理模式. 不管使用那种模式,最终都是一条语句一条语句的执行. 所以我们一交互式模式为例.

## 设置断点

psql 使用事件处理循环, 等待用户输入 -> 执行用户命令或者 query -> 读取结果并显示 -> 直到没有更多结果.

psql 执行用户命令的函数是 `PSQLexec`, 譬如 \d 时, 会调用这个函数.

psql 执行用户输入的查询的函数是 `SendQuery`, 譬如 SELECT * FROM tbl WHERE id = 1 时.

    (gdb) b PSQLexec
    Breakpoint 1 at 0x4085d0: file common.c, line 488.
    (gdb) b PrintQueryTuples
    Breakpoint 2 at 0x4091cb: file common.c, line 579.
    (gdb) b PrintQueryResults
    Breakpoint 3 at 0x408c30: file common.c, line 708.
    (gdb) b SendQuery
    Breakpoint 4 at 0x4087f0: file common.c, line 763.
    (gdb) b ExecQueryUsingCursor
    Breakpoint 5 at 0x408e6c: file common.c, line 976.

## 获取用户输入的指令:

    main -> MainLoop:

        line = gets_interactive(get_prompt(prompt_status));

## 执行命令

在 psql 里面输入:

    test=# \d

gdb 使用 bt 可以看到调用栈: main -> MainLoop -> HandleSlash -> exec_command -> listTables -> PSQLexec -> PQexec -> ...

exec_command 会根据用户输入的函数而执行不同的命令, \d 对应的是 listTables.

    (gdb) bt
    #0  PQexec (conn=0x9788b0, query=query@entry=0x448baa "select version()")
        at fe-exec.c:1782
    #1  0x0000000000408647 in PSQLexec (query=query@entry=0x448baa "select version()",
        start_xact=start_xact@entry=0 '\000') at common.c:533
    #2  0x0000000000420371 in isGPDB () at describe.c:63
    #3  listTables (tabtypes=tabtypes@entry=0x42fa41 "tvsxr",
        pattern=pattern@entry=0x0, verbose=verbose@entry=0 '\000',
        showSystem=<optimized out>) at describe.c:3096
    #4  0x0000000000407d04 in exec_command (query_buf=<optimized out>,
        scan_state=0x982760, cmd=0x996ae0 "d") at command.c:371
    #5  HandleSlashCmds (scan_state=scan_state@entry=0x982760,
        query_buf=<optimized out>) at command.c:107
    #6  0x0000000000411d48 in MainLoop (source=0x7f2d6fb19640 <_IO_2_1_stdin_>)
        at mainloop.c:301
    #7  0x0000000000404676 in main (argc=<optimized out>, argv=0x7ffde7748058)
        at startup.c:305

PQexec 是 libpq 的标准 API:

    /*
     * PQexec
     *    send a query to the backend and package up the result in a PGresult
     *
     * If the query was not even sent, return NULL; conn->errorMessage is set to
     * a relevant message.
     * If the query was sent, a new PGresult is returned (which could indicate
     * either success or failure).
     * The user is responsible for freeing the PGresult via PQclear()
     * when done with it.
     */
    PGresult *
    PQexec(PGconn *conn, const char *query)
    {
        if (!PQexecStart(conn))
            return NULL;
        if (!PQsendQuery(conn, query))
            return NULL;
        return PQexecFinish(conn);
    }

## 执行用户SQL

在 psql 里面执行一个 SQL:

    test=# SELECT * FROM small_tbl;

典型的调用栈: SendQuery 调用 PQexec 返回 results, 然后打印出来.

    (gdb) where
    #0  PrintQueryTuples (results=0xc87b50) at common.c:579
    #1  PrintQueryResults (results=0xc87b50) at common.c:715
    #2  SendQuery (query=<optimized out>) at common.c:875
    #3  0x0000000000411a35 in MainLoop (source=0x7f5c803cb640 <_IO_2_1_stdin_>)
        at mainloop.c:257
    #4  0x0000000000404676 in main (argc=<optimized out>, argv=0x7fff6d16c808)
        at startup.c:305

libpq 执行 SendQuery 来处理这种用户输入的 SQL. 其中包括对事务/savepoint/取消等的处理. SendQuery 直接调用了
libpq 的标准 API PGresult PQexec(conn, query). PQxec 返回 PGresult 结构体:

PQnfields(result) 返回多少个字段, PQntuples(result) 返回多少个 tuple.

最后 psql 调用 printQuery() 函数将结果打印出来. 内部使用 for 循环一个 tuple 一个 tuple 的打印. 每个 tuple 的每个字段
是通过 `PQgetvalue(const PGresult *res, int row_number, int column_number)` 获得的.

    (gdb) p *results
    $14 = {
      ntups = 1,                // tuple 的个数
      numAttributes = 5,        // 属性的个数
      attDescs = 0xc917b8,      // 属性的描述
      tuples = 0xc91fc0,        // tuple 数组
      tupArrSize = 128,
      numParameters = 0,
      paramDescs = 0x0,
      resultStatus = PGRES_TUPLES_OK,
      cmdStatus = "SELECT\000\"Owner\"\000\000mode=emacs\000\000\021\001\000\000\000\000\000\000\240k\310\000\000\000\000\000\270\247<\200\\\177\000\000\000\000\000\000\000\000\000\000\241\000\000\000\000\000\000\000\270\247<\200",
      binary = 0,
      noticeHooks = {
        noticeRec = 0x7f5c8083a4e0 <defaultNoticeReceiver>,
        noticeRecArg = 0x0,
        noticeProc = 0x408540 <NoticeProcessor>,
        noticeProcArg = 0x0
      },
      events = 0x0,
      nEvents = 0,
      client_encoding = 6,
      errMsg = 0x0,
      errFields = 0x0,
      null_field = "",
      curBlock = 0xc917b0,
      curOffset = 317,
      spaceLeft = 1731
    }

默认 SELECT 的模式是fetch-it-all-and-print (pset.fetch_count < 0) :

    ...

    if (pset.fetch_count <= 0 || !is_select_command(query))
    {
        results = PQexec(pset.db, query);
        ...
        OK = (AcceptResult(results) && ProcessCopyResult(results));
        ...
        if (OK)
            OK = PrintQueryResults(results)
    }

## 事务处理

默认 psql 执行的命令是 autocommit 的. 如果执行了 BEGIN; 则进入事务模式.

## Cancellation

psql 使用 SetCancelConn() 来处理 cancel. 内部它使用 PQgetCancel(connection):

    PGcancel cancelConn = PQgetCancel(conn)

    // PQgetCancel(PGconn *conn) 返回一个 PGcancel 结构体, 其中有两个重要字段, 均来自于 conn
    //      cancel->be_pid = conn->be_pid;
    //      cancel->be_key = conn->be_key;

## libpq connection status

libpq 连接有三种状态:

* conn->status: 连接本身的状态
* conn->asyncStatus: 连接处于 async 的状态
* conn->xactStatus: 连接处于的事务状态