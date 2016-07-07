---
layout: post
title:  "GPDB: achive cross-database query using External Table"
subtitle:  "GPDB: 使用外部表实现跨数据库数据读写"
author: 姚延栋
date:   2015-12-16 09:20:43
categories: gpdb external table crossdatabase
published: true
---

使用 GPDB 如何实现跨数据库数据访问？

同事 Presser Marshall 分享了一个使用 WEB EXTERNAL TABLE 实现跨库数据读写的方法：



    CREATE EXTERNAL WEB TABLE faa.d_airports_ext
    (like faa.d_airports)
    EXECUTE 'psql -At -d extra -U gpadmin -c "select * from faa_extra.d_airports"' ON MASTER
    FORMAT 'TEXT' (DELIMITER '|' NULL E'\N');

写数据使用 WRITABLE 外部表即可。

这种方式可以正常工作，如果有大量数据，则性能会偏慢。
