---
layout: post
title:  "How to implement UDFs with Pytyon innner GPDB"
subtitle:  "GPDB 中使用 plpython 实现 python 自定义函数"
author: 姚延栋
date:   2015-11-10 17:20:43
categories: GPDB python plpython
---

### GPDB plpython 入门

GPDB 基于 PostgreSQL，具有丰富的扩展能力，其中之一就是支持使用 Python 写 UDF，这在实际应用中非常方面。

## hello world

    psql> create schema s1;
    psql> create language plpythonu;
    psql> CREATE OR REPLACE FUNCTION s1.plpy_test(x int)
          returns text
          as $$
            try:
                from numpy import *
                return 'SUCCESS'
            except ImportError, e:
                return 'FAILURE'
          $$ language plpythonu;
    psql> select * from s1.plpy_test(1);

## More examples

    CREATE FUNCTION pymax (a integer, b integer)
      RETURNS integer
    AS $$
      if (a is None) or (b is None):
          return None
      if a > b:
         return a
      return b
    $$ LANGUAGE plpythonu;

使用 STRICT 防止 NULL 参数.

    CREATE FUNCTION pymax (a integer, b integer)
      RETURNS integer AS $$
    return max(a,b)
    $$ LANGUAGE plpythonu STRICT ;

执行 SQL

    CREATE TABLE sales (id int, year int, qtr int, day int, region text)
      DISTRIBUTED BY (id) ;

    INSERT INTO sales VALUES
     (1, 2014, 1,1, 'usa'),
     (2, 2002, 2,2, 'europe'),
     (3, 2014, 3,3, 'asia'),
     (4, 2014, 4,4, 'usa'),
     (5, 2014, 1,5, 'europe'),
     (6, 2014, 2,6, 'asia'),
     (7, 2002, 3,7, 'usa') ;

    CREATE OR REPLACE FUNCTION mypytest(a integer)
      RETURNS text
    AS $$
      rv = plpy.execute("SELECT * FROM sales ORDER BY id", 5)
      region = rv[a]["region"]
      return region
    $$ language plpythonu;

    SELECT mypytest(2) ;

待续

