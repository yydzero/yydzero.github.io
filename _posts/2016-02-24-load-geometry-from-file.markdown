---
layout: post
title:  "How to load bulk of Geometry data into GPDB"
subtitle:  "如何加载大量的geometry数据到GPDB"
author: 刘奎恩
date:   2016-02-24 11:59:24
categories: gpdb geospatial
published: true
---

最近有客户咨询如何加载大量的geometry数据到GPDB，他给的例子中数据有两列：

	integer, geometry

假设已经将PostGIS加载入了GPDB，这里要补充的一些共识：
1. On GEOMETRY data type: after you load PostGIS into GPDB, GEOMETRY is similar to other native DB types.
2. If geometric data is not in plain format, please use 'shp2pgsql' or other tools to convert them firstly.

下面给出一些例子示范如何将数据加载进GPDB：

首先，假设我们有一个文件如下：
```
[gpadmin@gpdb-sandbox demo]$ head -n4 /tmp/geom.txt
id,geom
1,POINT(119.329174182657 39.3518172582146)
2,POINT(119.351830803975 39.3154556966852)
3,POINT(119.30916877836 39.3329396557994)
```

那么，简单的数据加载方式就是：Copy. I've tried below on GPDB Sandbox:

```
--SQL-- load geometry data
CREATE TEMPORARY TABLE point_table_new (id  smallint, geom geometry) DISTRIBUTED BY(id);
COPY point_table_new FROM '/tmp/geom.csv' WITH HEADER CSV;

test=# SELECT id, st_astext(geom) FROM point_table_new ORDER BY id LIMIT 3;
 id |                st_astext
----+------------------------------------------
  1 | POINT(119.329174182657 39.3518172582146)
  2 | POINT(119.351830803975 39.3154556966852)
  3 | POINT(119.30916877836 39.3329396557994)
(3 rows)

Time: 2.544 ms
```

上面方法的效率不太好，因为数据都要从Master上加载到Segments，所以存在瓶颈。

另外一个方法就是：GPFDIST, for example:

```
--SQL--
\! gpfdist -d /tmp -p 9000 -l /tmp/geom.log &
CREATE READABLE EXTERNAL TABLE point_table_external_read(id serial, geom geometry)
    LOCATION('gpfdist://localhost:9000/point.txt') FORMAT 'CSV' (HEADER);

test=# SELECT id, st_astext(geom) FROM point_table_external_read ORDER BY id LIMIT 3;
 id |                st_astext
----+------------------------------------------
  1 | POINT(119.329174182657 39.3518172582146)
  2 | POINT(119.351830803975 39.3154556966852)
  3 | POINT(119.30916877836 39.3329396557994)
(3 rows)

Time: 3.430 ms
```

一个较为完整的测试脚本参见：[testLoad.sql]({{ site.url }}/download/testLoad.sql)
