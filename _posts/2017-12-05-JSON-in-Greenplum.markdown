---
layout: post
title: "Greenplum中导入JSON格式的文件"
author: Jasper Li
date: 2017-12-05 18:00:00 +0800
comments: true
published: false
---

# Greenplum中导入JSON格式的文件
## JSON概述
JSON可以看作是自描述式的结构体，它非常灵活，易于理解。作为XML的高效轻量的替代品，它在web，NoSQL，IOT等领域中有广泛的应用。Greenplum 5.0正式支持了JSON格式的数据类型，可以在SQL语句中方便的检索和使用JSON结构中的各个关键字。具体的细节在这里不做深入介绍，大家可以参考RFC7159以及Greenplum的官方文档。

## JSON与表
JSON作为一个半结构化的数据格式，很容易实现与结构化的数据库表结构之间的相互转换；我们可以参考下面一个简单的例子。
```json
{ "name":"John", "age":30, "car":null }
```
显而易见它可以跟如下的表建立一一对应的映射关系：
```sql
create table person (name text, age int, car text);
```
在当用户需要把JSON格式的数据转换为数据库的记录时，每一个新的JSON对象可以理解为向表中插入新的一行数据：
```sql
insert into person values ("John", 30, NULL);
```
当用户有大量的JSON数据需要导入时，一个个的insert操作性能会很差。由于Greenplum的批量导入工具只支持text和csv两种文本格式（即使算上GPHDFS，也只有AVRO和parquet两种），直接导入JSON似乎并不是那么容易。
但是，只要需要导入的JSON数据格式满足特定的条件，利用Greenplum已有的工具和特性也是可以方便的通过外部表的方式批量导入JSON数据的。接下来我们详细讨论下如何导入JSON格式的数据。
## JSON的文件格式
JSON标准本身只是定义了对象的表示方式，因此JSON对象的保存和传输时需要一些额外的处理。如果把整个文件当成一个大的JSON对象，在把整个文件完全读完之前是无法对其进行处理的，这样既消耗系统内存也不便于流式处理。现在最常见的办法是以行为单位保存保存每个JSON对象，整个文件就是以换行符分割的JSON对象列表。接下来就以这种格式的JSON文件为例，演示如何将其导入Greenplum中。使用的JSON文件内容如下。
```json
{ "id": 1, "type": "home", "address": { "city": "Boise", "state": "Idaho" } }
{ "id": 2, "type": "fax", "address": { "city": "San Francisco", "state": "California" } }
{ "id": 3, "type": "cell", "address": { "city": "Chicago", "state": "Illinois" } }
```
## Greenplum 4的导入方法
Greenplum 4并不支持JSON格式，因此在Greenplum4中需要通过一些外部工具进行某些预处理来完成这一工作。完成这一任务大致有如下三种方式，这一篇[blog](http://dewoods.com/blog/greenplum-json-guide) （作者是Dillon Woods）介绍了前两种导入方式，这里引用来做一个简要的介绍。(这里采用的JSON文件的例子也是从该blog引用的)

### 通过可执行的外部表
可执行的外部表也叫`external web table`. 它的原理是在Master节点或者Segment节点上运行一个外部命令来获取数据，这个外部命令的标准输出作为外部表的输入，从而进行解析导入。
它的优点是灵活方便，外部命令可以由任何用户喜欢的语言实现，可以自由的指定在Master节点执行还是在Segment节点执行。主要缺点有两方面：一是安全，因为这个外部程序在Greenplum的进程空间执行，可能有潜在的安全风险；另一个是性能，外部程序的执行效率直接影响Greenplum的响应速度。
Dillon Woods 给出的例子如下：  
`parse_json.py`:
```python
import sys, json

for line in sys.stdin:
    try:
        j = json.loads( line )
    except ValueError:
        continue

    vals = map( lambda x: str( j[x] ), ['id', 'type'] )
    print '|'.join( vals ).encode('utf-8')
```
```sql
CREATE EXTERNAL WEB TABLE json_data_web_ext (
    id int,
    type text
) EXECUTE 'parse_json.py simple.json' ON MASTER
FORMAT 'CSV' (
    DELIMITER AS '|'
);
create table json_data  ( id int, type text ) ;
insert into json_data select * from json_data_web_ext;
```
结果如下：
```
SELECT * FROM json_data;
id | type
---+-----
1  | home
2  | fax  
3  | cell
(3 rows)
```
由于这个python脚本只是在master执行的，无法利用MPP的架构，性能很差。改进的办法是可以通过修改脚本的方式，利用某种切分数据的方式，让每个Segment获取整个数据的一部分，就可以实现批量导入了。
### 通过自定义的formatter
Dillon Woods 推荐的一个比较好的解决办法是利用`custome`的`formatter` （[链接](https://github.com/dewoods/greenplum-json-formatter)）。
```sql
CREATE EXTERNAL TABLE json_data_ext (
    id int,
    type text,
    "address.city" text,
    "address.state" text
) LOCATION (
    'gpfdist://localhost:8081/data/sample.json.'
) FORMAT 'custom' (
    formatter=json_formatter_read
);
```
执行结果如下：
```
select * from json_data_ext;
id | type | address.city  | address.state
----+------+---------------+--------------- 
1  | home | Boise         | Idaho 
2  | fax  | San Francisco | California 
3  | cell | Chicago       | Illinois
```
通过formatter的方式就可以利用MPP的架构，由所有Segment来执行json的解析操作；这个formatter还可以支持writable的外部表操作，详细的用法可以参考blog和github的链接。这里不做详细介绍。
### 通过gpfdist的transform
gpfdist是Greenplum的ETL工具，也提供了格式预处理的功能，即transform。通过gpfdist的`-c`参数指定一个yaml格式的配置文件，可以让gpfdist在读文件时调用指定的外部命令对每一行进行预处理。这跟`external web table`的方式类似，区别在于这个转换工作是由gpfdist完成的，而不是Greenplum的节点。利用jq工具进行预处理的参考配置例子如下：

```yaml
---
VERSION: 1.0.0.1
TRANSFORMATIONS:
  extract:
    TYPE:     input
    COMMAND:  /usr/bin/jq -c -M  -r '[.id, .type, .address.city]|@csv' %filename%
```

执行`gpfdist -c trans.yaml`启动gpfdsit服务，然后执行下面的命令创建相关的表

```sql
create external table ext_json (id int, type text, city text) location ('gpfdist://mdw:8080/json.txt#transform=extract') format 'text' (DELIMITER ',');
create table json_data  ( id int, type text, city text) ;
```
这样就可以相导入普通文本格式一样对外部表进行操作了。

```sql
select * from ext_json;
insert into json_data select * from ext_json;
```

由于transform的方式需要对每一行源数据进行处理，因此性能会比普通的文本导入差很多。Trasform主要的适用场景是由不是很大量的流式JSON数据的导入。通过管道的方式，由gpfdist将数据流预处理之后再分发到各个Greenplum节点。

## Greenplum 5的导入方法
首先，Greenplum4中所有的方法再Greenplum5中仍然是适用的。由于Greenplum5原生的支持了JSON类型，因此有了更便捷的方式导入JSON文件，例子如下：
```sql
create external table ext_json (data json) location ('gpfdist://mdw:8080/sample.json') format 'text';
create table json_data  ( id int, type text, city text) ;
```
利用内置的JSON操作符，通过如下命令即可完成JSON的导入
```sql
insert into json_data select data->'id', data->'type', data->'address'->'city' as city from ext_json;
```
由于是原生支持了JSON格式，这种方法适用于所有的Greenplum外表。需要注意的是外部表在进行行和列的切割是，会检查指定的换行和转义符号，因此尽量选择一个不会出现的符号当作转义符和列分隔符，可以参考下面的查询，指定ASCII的0x1E和0x1F来作为转义和分隔符。

```sql
create external table ext_json (data json) location ('gpfdist://mdw:8080/sample.json') format 'text'  (ESCAPE E'\x1E' DELIMITER E'\x1F');
```

### 支持RFC7464
JSON的文件格式，除了这里使用的行分割的文件外，还有一种“JSON文本序列”的格式，它也是RFC7464定义的一种对象序列化格式。对每个JSON对象它定义了开始和结束两个标志，结束标志也使用的换行符，开始标志使用了0x1E("Record Separator")字符。其格式为`RS{JSON_OBJECT}LF`。
对这种格式JSON文件，可以通过指定转义字符的方式，忽略其开始标志。
```sql
create external table ext_json (data json) location ('gpfdist://mdw:8080/example.log') format 'text' (ESCAPE E'\x1E');
```
这是因为任何JSON对象都是以`{`符号开始的，而转义后的`{`仍然是它自己。

## 小节

这里介绍了几种常用的向Greenplum中导入JSON数据的方式，由于Greenplum 5增加了原生的JSON格式支持，因此可以直接对外部的JSON文件进行复杂的解析操作，一步到位的完成数据的转换和加载。如果这些JSON文件保存在HDFS上，Greenplum5还可以通过PXF来导入，关于PXF以后会有专门的介绍。

## 参考
1. https://www.w3schools.com/js/js_json_xml.asp
2. https://tools.ietf.org/html/rfc7159
3. https://www.json.org/
4. https://gpdb.docs.pivotal.io/500/admin_guide/query/topics/json-data.html
5. https://www.w3schools.com/js/js_json_objects.asp
6. http://dewoods.com/blog/greenplum-json-guide
7. http://jsonlines.org/
8. http://specs.okfnlabs.org/ndjson/index.html
9. https://tools.ietf.org/html/rfc7464
