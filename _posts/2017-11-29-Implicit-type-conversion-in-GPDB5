# GPDB5中的自动类型转换
## 问题
> create table test (id int, name text);  
> select * from test where id = name；

这个查询在GPDB4中是可以正常执行的，但在GDPB5中运行会报错如下：
```
ERROR:  operator does not exist: integer = text
LINE 1: select * from test where id = name;
                                    ^
HINT:  No operator matches the given name and argument type(s). You might need to add explicit type casts.
```
## 原因分析
这个问题的原因可以追溯到Postgres 8.3，它移除了很多与Text类型有关的操作符，导致的结果就是上述的等号操作符无法进行隐式类型转换。Greenplum 5.0升级到了Postgres 8.3内核，因此许多类似的查询在5.0中会运行失败。
如果在最新的Postgres10中执行同样的查询，也会得到同样的错误，这说明8.3的行为和最新的PG行为一致。  
Stackoverflow上有人贴出了下面的查询查看Postgres（和Greenplum）中允许的隐式类型转换操作符:
```
create view type_conversion as SELECT pg_catalog.format_type(castsource, NULL) AS "Source type",
       pg_catalog.format_type(casttarget, NULL) AS "Target type",
       CASE WHEN castfunc = 0 THEN '(binary coercible)'
            ELSE p.proname
       END as "Function",
       CASE WHEN c.castcontext = 'e' THEN 'no'
            WHEN c.castcontext = 'a' THEN 'in assignment'
            ELSE 'yes'
       END as "Implicit?"FROM pg_catalog.pg_cast c LEFT JOIN pg_catalog.pg_proc p
     ON c.castfunc = p.oid
     LEFT JOIN pg_catalog.pg_type ts
     ON c.castsource = ts.oid
     LEFT JOIN pg_catalog.pg_namespace ns
     ON ns.oid = ts.typnamespace
     LEFT JOIN pg_catalog.pg_type tt
     ON c.casttarget = tt.oid
     LEFT JOIN pg_catalog.pg_namespace nt
     ON nt.oid = tt.typnamespace
WHERE ( (true  AND pg_catalog.pg_type_is_visible(ts.oid)
) OR (true  AND pg_catalog.pg_type_is_visible(tt.oid)
) )
ORDER BY 1, 2;
```
查看跟text类型有关的类型转换函数，在Greenplum 4.3.17中执行结果如下：  
```
select * from type_conversion where "Source type"='text';
 Source type |         Target type         |      Function      |   Implicit?
-------------+-----------------------------+--------------------+---------------
 text        | bigint                      | int8               | no
 text        | "char"                      | char               | in assignment
 text        | character                   | (binary coercible) | yes
 text        | character varying           | (binary coercible) | yes
 text        | cidr                        | cidr               | no
 text        | date                        | date               | no
 text        | double precision            | float8             | no
 text        | inet                        | inet               | no
 text        | integer                     | int4               | no
 text        | interval                    | interval           | no
 text        | macaddr                     | macaddr            | no
 text        | name                        | name               | yes
 text        | numeric                     | numeric            | no
 text        | oid                         | oid                | no
 text        | real                        | float4             | no
 text        | regclass                    | regclass           | yes
 text        | smallint                    | int2               | no
 text        | timestamp without time zone | timestamp          | no
 text        | timestamp with time zone    | timestamptz        | no
 text        | time without time zone      | time               | no
 text        | time with time zone         | timetz             | no
(21 rows)
```
在Greenplum 5.2中执行结果如下：
```
select * from type_conversion where "Source type"='text';
 Source type |    Target type    |      Function      |   Implicit?
-------------+-------------------+--------------------+---------------
 text        | "char"            | char               | in assignment
 text        | character         | (binary coercible) | yes
 text        | character varying | (binary coercible) | yes
 text        | name              | name               | yes
 text        | regclass          | regclass           | yes
 text        | xml               | xml                | no
(6 rows) 
```
## 解决办法
由于这个问题本质上是Postgres升级导致的，因此可以复用PG的解决方案。  
如果要从根本上解决问题，这些查询是需要加上显式类型转换的，例如`select * from test where id = name::integer;`。作为work around，可以把Postgres 8.3中删掉那些转换函数’加回来‘。对上述integer类型，可以使用下面的转换函数
```
CREATE FUNCTION pg_catalog.text(integer) RETURNS text STRICT IMMUTABLE LANGUAGE SQL AS 'SELECT textin(int4out($1));';
CREATE CAST (integer AS text) WITH FUNCTION pg_catalog.text(integer) AS IMPLICIT;
```
更多的转还函数可以参考这个[连接](http://petereisentraut.blogspot.jp/2008/03/readding-implicit-casts-in-postgresql.html) 给出的代码。需要注意的是，这些毕竟是work around，可能会有潜在的副作用，正式使用前务必进行详尽的测试；最后强调一次，彻底的解决还是需要把SQL写的更加健壮。
## 参考文章
- https://dba.stackexchange.com/a/172370
- http://petereisentraut.blogspot.jp/2008/03/readding-implicit-casts-in-postgresql.html
- http://blog.ioguix.net/postgresql/2010/12/11/Problems-and-workaround-recreating-casts-with-8.3+.html

