---
layout: post
title:  "Greenplum的流数据加载"
author: Jasper Li
date:   2018-09-12 15:44 +0800
published: true
---

# Greenplum的流数据加载

## 数据的时效性

在数据爆发式增长的今天，我们已经有越来越多的数据分析工具和模型，来帮助我们全方位提取数据中的隐含价值。但问题在于，这是否意味着，任何人只要有了同样的工具、模型和数据之后，就可以获取到同样的价值呢？对于关注于算法和模型本身的学术领域来说，这一论断可能是肯定的；但对于实际生产中，答案却是否定的，因为它忽略了数据本身一个非常重要的特性，即数据的时效性。 

数据时效性指的是，数据的价值不是一成不变的，数据的价值会随着数据产生后时间的增加而逐步递减。下图就是来自**Nucleus Research**的一份报告显示的数据价值的“半衰期”[1]。

![数据半衰期]({{ site.url }}/assets/images/streaming_01.png)

这里借用了物理学里的半衰期一词，表示数据的价值损失到原来一半，所需要的时间。从图中可以看出，价值衰减最快的是“战术”型决策的数据，它的特点是需要几乎实时（以分钟，甚至秒为单位）的做出决策，例如根据交通状况规划路线等。

数据时效性最常见的影响是，如果捕获到的数据无法得到及时的利用，数据的价值会迅速衰减从而只能被抛弃。如何第一时间“榨取”数据的最大价值，成为今天流数据处理的一个重要问题。得益于Greenplum的大规模分布式并行计算的架构，很多在传统数据库中需要数小时来执行的查询可以由Greenplum在几分钟之内完成，从而满足了最苛刻战术型决策的要求。由此可见，具备了流数据加载能力的Greenplum无疑会为我们发掘出前所未有价值。

## 实时数据与流数据

尽管如今流数据在很多场合被认为是实时数据的同义词，但二者本身还是有严格的区别，不同的应用对其也有不同的定义和理解。这里首先对实时数据和流数据做明确的定义，并对Greenplum的流数据加载功能做一个简单的描述。

### 实时数据定义

**实时数据**这一概念已经出现很久，[Real-Time Systems][2]中将其分为两种，即硬实时（hard）和软实时（soft）。硬实时指的是特定事件发生后，必须在严格的时间期限内进行实时（微秒到毫秒级别）处理；一旦超过这个时间期限，将会产生严重的（性命攸关）的后果。例如心脏起搏器，核电站运行监控等，都属于硬实时。对于硬实时，有专门的从硬件到软件的设计研究，并不在我们的讨论和处理范畴。软实时指的是对处理时延的容忍性相对宽松（毫秒到秒级），一旦处理不及时也不会产生严重的后果。无论软实时还是硬实时，对时延的要求都还是相对严格的，因此[Streaming data][3]引入了第三种实时场景的定义：近实时（near）。它允许的时延更加宽松，可以到分钟级，但对处理的及时性要求比起软实时也有所提高。简单说，近实时允许更多的延时，同时严格要求在允许时延内完成处理操作。

严格意义上讲，Greenplum处理的流数据属于大致属于近实时的范畴，即在用户允许的决策时间内，数据是有足够价值的；一旦超过这个期限，数据价值就严重衰减。

### 流数据的管道

讨论完实时数据，这里再讲流数据。首先流数据针对的只是软实时和近实时数据。其次，流数据并不侧重严格要求在数据产生后多长时间内完成，它强调的是在用户任意需要的时候将结果呈现出来。就像自来水的管道，我们并不关心水从自来水公司流到我们家里需要多长时间，而需要的是在拧开水龙头的时候，会有自来水流出来。因此对于流数据系统，最重要的是搭建流数据处理的管道。[Streaming data][3]中给出的流数据系统的定义如下：

```text
In many scenarios, the computation part of the system is operating in a non-hard real-time fashion, but the clients may not be consuming the data in real time due to network delays, application design, or a client application that isn’t even running. Put another way, what we have is a non-hard real-time service with clients that consume data when they need it. This is called a streaming data system—a non-hard real-time system that makes its data available at the moment a client application needs it. It’s neither soft nor near—it is streaming. 
```

Greenplum的流数据加载同样遵循这一模式，利用`gpkafka`在Kafka和Greenplum集群之间搭建流数据管道[4]。

## Greenplum与Kafka

### Kafka简介

Kafka是一个分布式的日志系统，有着非常好的性能和扩展性，广泛应用于消息中间件服务。Kafka的核心组件设计简单高效，适合于很多消息队列的场景，因此成为基于消息的流式数据的理想平台。它将消息的发送和接受解耦，同时提供了并发和高可用的保证，越来越多的用户逐渐将其作为数据池（data lake）的解决方案。

它提供了官方的消息发布（producer）和处理（consumer）接口，从0.11版本之后也提供了exactly-once语义的支持，从而解决了分布式环境下消息一致性的问题[5]。

Kafka背后的商业公司Confluent，在Kafka的核心组件之上，提供了各种高附加值组件，简化各种场景的使用。例如Kafka-connect，提供了连接第三方数据库/数据仓库的框架，可以完成很多传统ETL的工作。KStream为应用程序提供了流式处理的接口，KSQL为实时数据提供了SQL的查询接口[6]。

Kafka不仅仅是一个简单的消息队列，它已经成为流数据消息中间件的事实标准，并开始逐渐提供流数据处理和计算的能力。Greenplum的分布式大数据处理能力与Kafka的流处理能力相结合之后，我们便有了更强大的工具，可以在数据价值快速衰减之前，完成重要的分析决策。

### Kafka连接器

Greenplum从5.10开始加入了一个实验性的功能：**Kafka Connector**，即Greenplum-Kafka的连接器。它利用`gpkafka`搭建流数据加载的管道，使得Kafka中的数据可以持续加载到Greenplum中。gpkafka的系统架构图如下：

![架构图]({{ site.url }}/assets/images/streaming_02.png)

Greenplum5.11中的gpkafka，功能有了大幅增强，可以满足实际生产环境的不同流数据加载需求，其主要功能介绍如下：

* 完整的Key、Value支持

  Kafka是<Key，Value>的存储系统，通常我们使用的主要是value部分，用来进行区分不同partition。但事实上key和value在Kafka中都是可用的，Greenplum可以同时加载key和value里有用信息。

* 完整的数据格式支持：json，avro，分隔的文本，二进制数据等

  作为流式消息引擎，Kafka使用最多的是json和avro两种消息格式。json有很好的数据组织结构和很好的可读性，但缺乏严格的scheam定义，没有官方的压缩机制。Confluent官方推荐使用的是avro格式，并推出了schema registry service，用来集中管理avro的头信息。对于特殊场景，用户可能仍然需要使用分隔符分割的文本格式。除了通用型数据格式外，gpkafka还可以加载任意二进制数据，比如加密后的数据，PDF文档，甚至GIS数据。gpkafka除了支持内置消息格式外，还提供自定义格式的扩展接口，可以自己实现新的消息格式。

* 持续批量加载，可“断点续传”

  gpkafka本身是无状态的，它从配置文件中获取kafka和Greenplum的集群信息，利用Greenplum外部表将Kafka消息转发到Greenplum，并将加载进度和元信息保存在Greenplum中。任何正常或异常退出后，gpkafka都可以从上次中断的地方继续加载。

* 根据时间间隔和消息数量控制加载频率

  为提高加载性能，gpkafka的加载是采用mini-batch，将一定数量或者一定时间间隔内的消息，通过一次`insert into ... from ext_table` 的方式进行加载。用户可以通过配置文件设置每次读取的消息数量和等待的间隔。

* Exactly-once保证

  gpkafka加载时会记录此操作的偏移（offset），确保不会将同一个offset的消息加载两次。加载历史记录在Greenplum中并在同一个transaction中更新，gpkafka可以确保在退出重启时仍可以从正确的位置开始继续。

* 支持数据变换

  得益于Greenplum强大的外部表功能，gpkafka还可以对kafka的消息在加载时进行变换处理，例如单位变换，删除冗余列，甚至执行复杂UDF等。

关于详细信息，可以参考官方[文档][https://gpdb.docs.pivotal.io/5110/main/index.html]。

此外，关于Greenplum，Kafka以及Spring更多相关的新闻，可以关注9月25日的Spring2018大会：https://springoneplatform.io/

## 参考文献

【1】 “Business Data Has a Half-Life of Usefulness: Nucleus Research.” Accessed September 3, 2018. https://insights.dice.com/2012/07/03/business-data-has-a-half-life-of-usefulness-nucleus-research/.

【2】 Kopetz, Hermann, and Springer Science+Business Media. Real-Time Systems: Design Principles for Distributed Embedded Applications. New York: Springer, 2011.

【3】Akidau, Tyler, Slava Chernyak, and Reuven Lax. Streaming Systems: The What, Where, When, and How of Large-Scale Data Processing, 2018.

【4】Psaltis, Andrew G. Streaming Data: Understanding the Real-Time Pipeline. Shelter Island, NY: Manning Publications, 2017.

【5】 “Exactly-Once Semantics Is Possible: Here’s How Apache Kafka Does It.” Accessed September 12, 2018. https://www.confluent.io/blog/exactly-once-semantics-are-possible-heres-how-apache-kafka-does-it/.

【6】“Documentation — Confluent Platform.” Accessed September 12, 2018. <https://docs.confluent.io/current/index.html>.