---
layout: post
title:  "GPDB Extension Alter Bug Case Study"
author: Pivotal Engineer/姚延栋
date:   2016-10-28 11:00 +0800
categories: gpdb extension
published: true
---

# Greenplum DB extension alter bug

## reproduce

修改了 extension 的 schema 后, 找不到 extension 原来的 type 信息.

    test=# create extension citext ;
    CREATE EXTENSION
    test=# create table t (id int, name citext);
    CREATE TABLE
    test=# INSERT INTO t VALUES (1, 'aBc');
    INSERT 0 1
    test=# SELECT * from t where name = 'abc';
     id | name
    ----+------
      1 | aBc
    (1 row)

    test=# ALTER EXTENSION citext SET SCHEMA s1;
    ALTER EXTENSION
    test=# SELECT * from t where name = 'abc';
     id | name
    ----+------
    (0 rows)

## 问题追踪

    // 首先看看 citext 类型信息
      oid   | typname | typnamespace | typowner | typlen | typbyval | typtype | typisdefined | typdelim | typrelid | typelem | typarray | typinput | typoutput | typreceive |  typsend   | typmodin | typmodout | typanalyze | typalign | typstorage | typnotnull | typbasetype | typtypmod | typndims | typdefaultbin | typdefault
    --------+---------+--------------+----------+--------+----------+---------+--------------+----------+----------+---------+----------+----------+-----------+------------+------------+----------+-----------+------------+----------+------------+------------+-------------+-----------+----------+---------------+------------
     385703 | citext  |         2200 |       10 |     -1 | f        | b       | t            | ,        |        0 |       0 |   385708 | citextin | citextout | citextrecv | citextsend | -        | -         | -          | i        | x          | f          |           0 |        -1 |        0 |               |

    // 然后看看这个类型依赖于那些对象

    test=#  SELECT classid::regclass, objid, refclassid::regclass, refobjid, deptype from pg_depend where objid = 385703;
     classid | objid  |  refclassid  | refobjid | deptype
    ---------+--------+--------------+----------+---------
     pg_type | 385703 | pg_namespace |     2200 | n
     pg_type | 385703 | pg_proc      |   385704 | n
     pg_type | 385703 | pg_proc      |   385705 | n
     pg_type | 385703 | pg_proc      |   385706 | n
     pg_type | 385703 | pg_proc      |   385707 | n

    // 可见, citext 不会依赖于 'citext' extension. 因而在 alter extension 时, 不会找到依赖该extension 的 citext 类型, 因而 citext 类型
    // 没有被成功的修改 namespace. 造成了查询时找不到正确的处理函数.

## 为什么创建 extension 时没有记录下 citext 类型对 citext 扩展的依赖关系?

`CreateExtension` 函数是 'CREATE EXTENSION citext' SQL 语句的实际执行函数, 这个函数在插入一条 tuple 到 pg_extension 表之后, 会执行扩展的脚本文件( SQL 文件).
对应的函数是 `execute_extension_script -> execute_sql_string`.



    foreach(lc2, stmt_list)
    {
        Node	   *stmt = (Node *) lfirst(lc2);

        Snapshot saveActiveSnapshot = ActiveSnapshot;
        ActiveSnapshot = CopySnapshot(GetTransactionSnapshot());

        if (IsA(stmt, PlannedStmt) && ((PlannedStmt *) stmt)->utilityStmt == NULL)
        {
            QueryDesc  *qdesc;

            qdesc = CreateQueryDesc((PlannedStmt *) stmt,
                                    sql,
                                    ActiveSnapshot, NULL,
                                    dest, NULL, false);

            ExecutorStart(qdesc, 0);
            ExecutorRun(qdesc, ForwardScanDirection, 0);
            ExecutorEnd(qdesc);

            FreeQueryDesc(qdesc);
        }
        else
        {
            ProcessUtility(stmt,
                           sql,
                           NULL,
                           false,	/* not top level */
                           dest,
                           NULL);
        }

        FreeSnapshot(ActiveSnapshot);
        ActiveSnapshot = saveActiveSnapshot;
    }



## 类型创建

创建一个类型分为两步: 第一步创建一个 shell 类型, 并插入到 pg_type 表中, 这时 tuple 的 value 都是 dummy values, typisdefined 字段
是未定义的.  shell type 类型的目的是方便定义 type 的 IO 函数. 执行完整的 CREATE TYPE 命令时, 将替换 tupe 的 value 为正确的值.

创建 shell 类型的时候, 也会更新该类型的 dependency 信息: recordDependencyOnCurrentExtension(&myself, rebuild);

## 依赖记录

创建类型的时候, 先创建 shell 类型, 然后创建完整类型. 创建 shell 类型时, 会使用 recordDependencyOnCurrentExtension() 记录依赖. 确实写入
了对 extension 的依赖, 但是由于某种原因没有记录下来.

    values:
        1247        pg_type
        16554
        0
        12          ???
        16553
        0
        101

    12 不是一个正确的relation id,  pg_extension 的 oid 应该是 3079.

recordMultipleDependencies() 调用 ObjectIdGetDatum() 时, 3079 作为参数, 返回的 Datum 是 12?

    values[Anum_pg_depend_refclassid - 1] = ObjectIdGetDatum(referenced->classId)

    使用 lldb 发现, values 内容没有问题, 大概是 clion 的一个 bug?

## citext 的脚本文件包括下面的片段

    CREATE TYPE citext;

    --
    --  Input and output functions.
    --
    CREATE FUNCTION citextin(cstring)
    RETURNS citext
    AS 'textin'
    LANGUAGE internal IMMUTABLE STRICT;

    CREATE FUNCTION citextout(citext)
    RETURNS cstring
    AS 'textout'
    LANGUAGE internal IMMUTABLE STRICT;

    CREATE FUNCTION citextrecv(internal)
    RETURNS citext
    AS 'textrecv'
    LANGUAGE internal STABLE STRICT;

    CREATE FUNCTION citextsend(citext)
    RETURNS bytea
    AS 'textsend'
    LANGUAGE internal STABLE STRICT;

    --
    --  The type itself.
    --

    CREATE TYPE citext (
        INPUT          = citextin,
        OUTPUT         = citextout,
        RECEIVE        = citextrecv,
        SEND           = citextsend,
        INTERNALLENGTH = VARIABLE,
        STORAGE        = extended
    );

## 既然 gdb 看到确实插入到了 pg_depend 中, 但是结果却没有, 怀疑类型需要两次创建和事务引起的问题?

gdb 追踪, 确实看到了构建 tuple 并加入到 pg_depend 中, 但是结果确实没有加入进去 (seqscan扫描没有).

那么做一个简答的测试, 单纯创建一个 shell 类型, 看看是否和类型的创建相关.

此外需要注意的, 除了类型, 其他如 UDF 和操作符都生成了正确的对 extension 的依赖.

修改 extension 脚本,使其仅仅包含下面内容:

        CREATE TYPE citext;

        --
        --  Input and output functions.
        --
        CREATE FUNCTION citextin(cstring)
        RETURNS citext
        AS 'textin'
        LANGUAGE internal IMMUTABLE STRICT;

        CREATE FUNCTION citextout(citext)
        RETURNS cstring
        AS 'textout'
        LANGUAGE internal IMMUTABLE STRICT;

        CREATE FUNCTION citextrecv(internal)
        RETURNS citext
        AS 'textrecv'
        LANGUAGE internal STABLE STRICT;

        CREATE FUNCTION citextsend(citext)
        RETURNS bytea
        AS 'textsend'
        LANGUAGE internal STABLE STRICT;

结果可见,生成了正确的对 extension 的依赖, 并写入到 pg_depend 表中.

    test=# SELECT  xmin, xmax, * from pg_depend where objid = 33190;
     xmin | xmax | classid | objid | objsubid | refclassid | refobjid | refobjsubid | deptype
    ------+------+---------+-------+----------+------------+----------+-------------+---------
      824 |    0 |    1247 | 33190 |        0 |       2615 |     2200 |           0 | n
      824 |    0 |    1247 | 33190 |        0 |       3079 |    33189 |           0 | e
    (2 rows)

然而一旦控制文件中加入创建完整类型的语句后, 该类型对 extension 的依赖就丢了.

    CREATE TYPE citext (
        INPUT          = citextin,
        OUTPUT         = citextout,
        RECEIVE        = citextrecv,
        SEND           = citextsend,
        INTERNALLENGTH = VARIABLE,
        STORAGE        = extended
    );

可见问题出在执行上面语句时.

## 为什么第二次执行 CREATE TYPE 会将第一次生成的 pg_depend 信息给清掉?

第一创建类型使用 `TypeShellMake`, 第二次使用 `TypeCreateWithOptions`.

TypeCreateWithOptions 其中有如下代码:

    tup = heap_modify_tuple(tup,
                           RelationGetDescr(pg_type_desc),
                           values,
                           nulls,
                           replaces);
    simple_heap_update(pg_type_desc, &tup->t_self, tup);

    typeObjectId = HeapTupleGetOid(tup);

    rebuildDeps = true;		/* get rid of shell type's dependencies */

然而在 `GenerateTypeDependencies` 中, 并没有重新生成对 extension 的依赖. 这是问题所在了.

对比 PG 代码, 发现 GPDB deleteDependencyRecordsFor 删除了对 extension 的依赖, 而 PG 中没有删除对 extension 的依赖. bingo!