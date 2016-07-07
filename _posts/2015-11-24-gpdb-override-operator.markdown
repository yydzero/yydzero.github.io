---
layout: post
title:  "How to override operators in GPDB"
subtitle:  "GPDB 中如何重载操作符"
author: 姚延栋
date:   2015-11-24 17:20:43
categories: GPDB operator
---

### GPDB 中重载操作符

GPDB 提供了多种操作符，譬如 +, -, || 等。此外还提供了操作符重载的功能。 下面以一个例子说明下如何重载操作符。

场景： GPDB中 || （concat）两个 varchar 返回的结果是 text 类型。有些时候这回造成不便，特别是跨数据库时，譬如Oracle自动将 text 类型
转换成 blob，因而某些操作不方便。 本例将重载这个操作符，使得两个varchar的 concat 返回的类型仍然是 varchar。

    postgres=# SELECT pg_typeof('abc'::varchar || 'def'::varchar);
     pg_typeof
    -----------
     text
    (1 row)

#### 重载操作符

重载操作符或者自定义操作符很简单，使用 `CREATE OPERATOR 即可。

    CREATE OPERATOR || (PROCEDURE=varchar_cat,
                        LEFTARG=varchar,
                        RIGHTARG=varchar);

#### 实现自定义函数

上面操作符使用了 varchar_cat 函数，下面定义这个函数。

    CREATE OR REPLACE FUNCTION varchar_cat(varchar, varchar)
    RETURNS varchar AS
    $$
            BEGIN
                    RETURN ($1 || $2)::varchar;
            END;
    $$ LANGUAGE 'plpgsql' IMMUTABLE;

#### 测试

    test=# SELECT pg_typeof('abc'::varchar || 'def'::varchar);
         pg_typeof
    -------------------
     character varying
    (1 row)
