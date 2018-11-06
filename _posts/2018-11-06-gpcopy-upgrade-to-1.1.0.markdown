---
layout: post
title: "Greenplum 数据迁移工具 gpcopy 升级到 1.1.0"
author: 李晓亮, 陆公瑜
date: 2018-10-30 17:58 +0800
categories: greenplum gpcopy
published: true
---

<style>
table{
    border-collapse: collapse;
    border-spacing: 0;
    border:2px solid #000000;
}

th{
    border:2px solid #000000;
}

td{
    border:1px solid #000000;
}
</style>

gpcopy 是新一代的 Greenplum 数据迁移工具，可以帮助客户在不同集群间，不同版本间，快速稳定地迁移数据。同上一代迁移工具 gptransfer 相比，gpcopy 具有巨大的优势：更快，更稳定，更易用，功能更丰富。另外，gpcopy 只包含在商业版本中。

## gpcopy 可以干什么

gpcopy 可以迁移整个集群，也可以具体传输某些数据库、某些命名空间和某些表；可以从文件读取传输或者略过的表，支持正则表达式；可以略过、追加或者替换目标集群的数据；可以并行传输；可以只迁移结构信息；可以静默自动化执行……

简单说，就是集群间迁移所存储的信息，使得用户业务可以迁移：
![]({{ site.url }}/assets/images/gpcopy-design-what.jpg)

## 和 gptransfer 的速度对比

| 数据量 | 单表10万条 | 单表100万条 | 真实客户场景（几十T数据量的集群） |
| ------------- | ------------- | ------------- | ------------- |
| gptransfer 时间 | 13.00秒 | 20.50秒 | 未成功 |
| gpcopy 时间 | 1.29秒 | 4.82秒 | 20+小时 |


## 为什么 gpcopy 可以更快速

### segment 间直接传输

gpcopy 的数据传输利用了 Greenplum 最新的 COPY ON SEGMENT 特性，首先 COPY 相较于 gptransfer 单纯使用的外部表就更快，因为它是批量操作，而外部表的 SELECT 和 INSERT 都是逐条操作；另外 COPY ON SEGMENT 特性使得 gpcopy 可以做到两个集群的多节点间并发传输，快上加快。

以下是 gpcopy 应用于相同节点数 Greenplum 集群间传输的架构，还是很简单直接的。
![]({{ site.url }}/assets/images/gpcopy-design-same.jpg)

### Snappy 压缩传输

gpcopy 默认打开压缩选项，使用 Google 的 Snappy 格式对所传输得数据进行压缩，网络传输少了很多压力，速度也更快。

Snappy 对大多数的输入比 zlib 的最快模式要快几个数量级。在 core i7 的单核64位模式下，Snappy 压缩速度可以达到250MB/s或者更快，解压缩可以达到大约500MB/s或更快。

### 更快的数据校验

判断两个数据库系统的表是否一致从来不是一个简单的问题，简单使用哈希校验的话要考虑条目的顺序，排序的话又会把速度拖得更慢。如果这两个数据库系统和 Greenplum 一样是集群系统，这个问题就更难了。而 gpcopy 灵活地解决了这个问题，不需要排序，数据校验的速度是对所导出CSV格式文件做哈希的几倍!

## 为什么 gpcopy 可以更稳定

### 没有命名管道文件

命名管道以文件的形式存在于文件系统中，任何进程只要有权限，打开该文件即可通信。命令管道遵守先进先出的规则，对命名管道读总是从开始处返回数据，读过的数据不再存在于命名管道中，对它写则是添加到末尾，不支持lseek等操作。

命名管道文件难以管理，也容易出问题。例如不限制其它进程读、读过的数据不再存在这两个特点，结合起来会发生什么？想象一下，如果用户系统中存在着杀毒软件，所有文件都会被它读取采样……（这是一个真实案例）

### 完善的日志记录和错误处理

gpcopy 在这一块花了很大力气，每一步的操作，执行的查询，命令和结果都写到了日志文件，并根据用户指定的级别显示到标准输出。

迁移操作也都在事务内，发生错误可以做到表一级的回滚。运行结束的时候会有详细的成功和失败总结，同时生成和提示用户运行命令去重试所有的错误。

可以说，万一用户环境出现了错误，结合 gpcopy 和 Greenplum 的日志文件，我们的支持人员可以迅速地定位问题和给出解决方案，最大程度保障客户顺利迁移。

### “能用”而且好用的数据校验

这个前面提过了，前代 gptransfer 的数据校验是对数据进行排序然后哈希，用户基本都因为太慢而不得不略过，“稳定和一致”也就无从谈起了。

## gpcopy 可以用于升级

Greenplum 版本升级一般会有 catalog 变化，只升级可执行文件是不兼容的。而利用 gpcopy 则可以做到原地升级，另外因为有了快速好用的数据校验，用户也可以放心地一边迁移数据一边释放空间。（即使这样也强烈建议备份）

## gpcopy 1.1.0 现已支持不同节点数的 Greenplum 集群间传输！

现阶段导出依然是最快的COPY ON SEGMENT，导入则是利用外部表。多节点间并发传输、压缩和更快的数据校验，一个特性也不少。后续还会针对这个场景做更多的优化，敬请期待。

以下是 gpcopy 从小集群到大集群传输的基本架构，图片之外我们还做了传输量倾斜的优化。
![]({{ site.url }}/assets/images/gpcopy-design-small.jpg)

以下是 gpcopy 从大集群到小集群传输的基本架构，一样也会有避免倾斜的优化。
![]({{ site.url }}/assets/images/gpcopy-design-large.jpg)

欢迎大家试用 gpcopy。下面是 gpcopy 的官方文档供大家参考。
[https://gpdb.docs.pivotal.io/5120/utility_guide/admin_utilities/gpcopy.html](https://gpdb.docs.pivotal.io/5120/utility_guide/admin_utilities/gpcopy.html)
[https://gpdb.docs.pivotal.io/5120/admin_guide/managing/gpcopy-migrate.html](https://gpdb.docs.pivotal.io/5120/admin_guide/managing/gpcopy-migrate.html)
