---
layout: post
title: "用JFR和JMC分析SolrCloud集群性能瓶颈"
author: Jerry Lin
date: 2018-11-15 17:00 +0800
categories: JFR JMC Profiling Solr GPText
published: true
---

<style>
table{
    border-collapse: collapse;
    border-spacing: 0;
    border:2px solid #000000;
    width: 100%;
    margin: auto auto 20px auto;
}

th{
    border:2px solid #000000;
}

td{
    border:1px solid #000000;
}
</style>

在开发甚至是生产过程中，我们的程序可能会满足不了预想中的性能要求。这种情况下我们就需要分析程序中的性能瓶颈，并针对性地解决问题。性能瓶颈的定位不仅可以在开发过程中帮助我们确定程序需要被优化的部分，亦可在性能调优过程中为参数的确定提供参考信息。

在分析性能瓶颈的过程中，除了需要进行代码分析以外，还常常需要进行profiling。Profiling是指通过收集程序运行时的信息来动态分析程序行为的方法。相比于代码分析，profiling能够利用对CPU/内存使用率、文件读写次数、各个函数的运行时间等信息更直观高效地定位性能瓶颈。

GPText是Pivotal Greenplum生态系统的一部分。它无缝集成了Greenplum数据库海量数据并行处理以及Apache Solr企业级文本检索的能力，为用户提供了一套易于使用、功能完备的文本检索、分析方案。在GPText开发过程中，我们难免需要对SolrCloud进行调优测试，以此提高GPText的性能。笔者前段时间曾使用JFR(Java Flight Recorder)和JMC(Java Mission Control)工具对SolrCloud集群进行profiling，通过分析运行时信息、定位并解决性能瓶颈，最终使得该SolrCloud集群的响应速度成倍提高。

# JFR和JMC工具简介

JFR(Java Flight Recorder，飞行记录器)是Oracle的JDK自带的profiling工具，通过该工具，我们可以收集Java虚拟机的一些运行时的信息，如CPU和内存使用率，热点方法（Hot Methods）等。

JMC（Java Mission Control）是Oracle的JDK自带的可视化工具，能够在图形界面中显示、统计JFR收集的程序运行时信息，帮助我们更直观地理解和分析JVM和Java应用程序的运行过程。

通过JFR和JMC的搭配，我们可以简单直观地对测试环境甚至是生产环境进行运行时信息的收集和分析，以此定位Java程序的瓶颈。相比于其它的Java Profiling工具，如JProfiler、YourKit Profiler、Retrace、CodePro Profiler等，JFR和JMC的搭配同时具有以下优势：

1. 支持离线模式。离线模式指的是将profiling的结果保存到文件中，之后再根据文件的内容进行分析。测试、生产环境有时不能接入互联网，甚至无法通过普通方式同本地客户端进行连接。这种情况下，我们只能先把profiling的结果保存到本机文件中，再把这些文件复制到本地环境进行分析。离线模式的支持在对有些环境的profiling中是必不可少的。

2. 支持收集的信息全面。JFR支持但不限于以下信息的收集：

    a. 机器的CPU使用信息、Java程序CPU使用信息

    b. 机器的内存使用信息、Java程序的内存使用信息

    c. 垃圾回收相关信息

    d. 载入类信息

    e. 线程信息，包括线程睡眠、阻塞等状态的信息

    f. I/O信息

    g. 方法调用信息

3. 在非生产服务器下的使用免费。（官方文档：The Java Flight Recorder (JFR) is a commercial feature. You can use it for free on developer desktops or laptops, and for evaluation purposes in test, development, and production environments. However, to enable JFR **on a production server, you must have a commercial license**. Using JMC UI for other purposes on the JDK does not require a commercial license.）

4. 无需重启Java进程即可进行profiling。(详见官方文档：[https://docs.oracle.com/javacomponents/jmc-5-5/jfr-runtime-guide/run.htm#JFRRT172](https://docs.oracle.com/javacomponents/jmc-5-5/jfr-runtime-guide/run.htm#JFRRT172))

5. 集成于JDK，无需额外安装。

# JFR和JMC工具的使用

## 生成Profiling配置文件

1. 打开JMC(装好JDK后，直接在命令行输入“*jmc*”命令即可)

2. 依次点击菜单栏中的“*窗口*”、“*飞行记录模板管理器*”，得到如下对话框。
  ![]({{ site.url }}/assets/images/jmc0.png)

3. 选中“*Setting for ‘My Recording*”后，点击右侧的“*复制*”按钮。此时我们将看到另一个飞行记录模板：“*Setting for ‘My Recording’(1)*”，如下图。
  ![]({{ site.url }}/assets/images/jmc1.png)

4. 选中新的飞行记录模板，点击“*编辑*”按钮，得到如下对话框。
  ![]({{ site.url }}/assets/images/jmc2.png)

    在该对话框中，我们可以编辑飞行记录模板的名称，以及一些参数。比如，在上述对话框中，我们将名称从“*Setting for ‘My Recording’(1)*”改为“*Test*”。将筛选器中的“*File Read*”的阈值改为0毫秒（这意味着任何大于0毫秒的文件读取都将被飞行记录器记录）。

5. 修改完参数后，我们点击下方的“*确定*”按钮，回到上一个对话框，如下。
  ![]({{ site.url }}/assets/images/jmc3.png)

    选中刚刚编辑好的模板，点击右侧“*导出文件*”按钮，即可导出配置文件到本地。

6. 用任意编辑器打开导出的文件，我们可以发现，该文件是xml格式的配置文件。通过修改该文件，我们可以修改配置参数以控制需要记录的运行时信息。

## 使用JFR记录Java程序的运行时信息

官方文档[https://docs.oracle.com/javase/8/docs/technotes/guides/troubleshoot/tooldescr004.html](https://docs.oracle.com/javase/8/docs/technotes/guides/troubleshoot/tooldescr004.html)给出了使用JFR记录Java程序运行时信息的所有方法。限于篇幅，此处仅介绍使用诊断命令来运行JFR的方式。

1. 查询要记录运行时信息的Java程序的pid。此处的pid为986。
  ![]({{ site.url }}/assets/images/jmc4.png)

2. 执行命令“**jcmd &lt;pid&gt; VM.unlock_commercial_features**”。
  ![]({{ site.url }}/assets/images/jmc5.png)

3. 执行命令“**jcmd &lt;pid&gt; JFR.start settings=&lt;setting file.jfc&gt; name=&lt;recording name&gt;**”以启动JFR对运行时信息进行记录。其中，参数settings用于指定要 使用的profiling配置文件。此处使用的是上文生成的“Test.jfc”文件。参数name用于指定本次记录的名称。该名称会在后续导出结果文件以及停止记录运行时信息时被使用。此处指定本次记录的名称为“recording1”。
  !![]({{ site.url }}/assets/images/jmc6.png)

4. 对Java程序执行需要的操作。如我们要分析SolrCloud查询时的性能瓶颈，那么此时就应该对SolrCloud集群发送查询请求。

5. 执行命令“**jcmd &lt;pid&gt; JFR.dump name=&lt;record name&gt; filename=&lt;output file.jfr&gt;**”以导出运行时结果文件。参数name用于指定本次记录的名称，此处为步骤3启动JFR时指定的名称“recording1”。参数filename用于指定导出的结果文件，此处我们将文件导出到“/home/gpadmin/output.jfr”。
  ![]({{ site.url }}/assets/images/jmc7.png)

6. 执行命令“**jcmd &lt;pid&gt; JFR.stop name=&lt;record name&gt;**”以停止JFR对运行时信息的记录。参数name用于指定本次记录的名称，此处为步骤3启动JFR时指定的名称“recording1”。
  ![]({{ site.url }}/assets/images/jmc8.png)

## 使用JMC查看Java程序的运行时信息

双击导出的结果文件，此处为“/home/gpadmin/output.jfr”，即可查看对应Java程序的运行时信息，如CPU占用信息、内存占用信息、热点方法、文件读写信息等等。
![]({{ site.url }}/assets/images/jmc9.png)

![]({{ site.url }}/assets/images/jmc10.png)

![]({{ site.url }}/assets/images/jmc11.png)

![]({{ site.url }}/assets/images/jmc12.png)

# 使用JFR和JMC分析SolrCloud集群性能瓶颈

分析SolrCloud集群的性能瓶颈，需要对集群中的每个Solr进程进行profiling。由于Solr会进行大量10毫秒以下的文件读取，所以在分析文件I/O时，需要在profiling的配置文件中把“*File Read*”的阈值改为0毫秒。由于不同参数的profiling配置会有不同的额外开销，为了得到更为准确的结果，此处根据不同的配置对SolrCloud集群进行了几次profiling。这里不再描述对Solr进程进行profiling的详细过程。

以下是本次用于profiling的SolrCloud集群环境信息：
<table cellpadding="5">
  <tr>
    <td colspan="2" align="center">机器配置</td>
  </tr>
  <tr>
    <td>主机数量</td>
    <td>8</td>
  </tr>
  <tr>
    <td>每台主机内存</td>
    <td>63GB</td>
  </tr>
  <tr>
    <td>每台主机CPU数量</td>
    <td>32核</td>
  </tr>
  <tr>
    <td colspan="2" align="center">SolrCloud集群配置</td>
  </tr>
  <tr>
    <td>Solr版本</td>
    <td>6.1.0</td>
  </tr>
  <tr>
    <td>每台主机的Solr节点数</td>
    <td>2</td>
  </tr>
  <tr>
    <td>每个Solr节点的内存配置</td>
    <td>-Xms1024M -Xmx15G</td>
  </tr>
  <tr>
    <td>Collection的数量</td>
    <td>1</td>
  </tr>
  <tr>
    <td>Collection的shard数量</td>
    <td>64</td>
  </tr>
  <tr>
    <td>Collection的文档数量</td>
    <td>800亿</td>
  </tr>
  <tr>
    <td>Collection大小</td>
    <td>1.8T</td>
  </tr>
</table>

## CPU占用率分析

CPU的占用率可以反映出很多信息。比如是否有其它程序和Java程序争夺CPU资源，Java程序是否合理利用了计算机的CPU资源等。依次点击JMC界面的“*一般信息*”按钮，和“*CPU占用率*”标签即可看到CPU的占用率。

1. 下图是第一次进行profiling时的CPU占用率折线图。这里的CPU占用率指的是机器所有的CPU占用率，而非单核CPU的占用率。蓝色的部分是该图对应的Solr节点占用的CPU。由于每个主机有2个Solr节点，所以Solr节点在每个主机上的CPU占用率应该乘以2。即便如此，我们依然可以看出有大量的CPU并非被Solr节点占用。这说明，在这台机器中，**还有其它程序在运行**，该程序和Solr不断争抢CPU资源，可能会降低Solr的响应速度。![]({{ site.url }}/assets/images/jmc13.png)

2. 关闭其它程序后，同一个Solr节点的CPU占用率如下图所示：	![]({{ site.url }}/assets/images/jmc14.png)

    将图中Solr节点占用的CPU乘以2之后，我们发现计算机的CPU占用率基本由Solr节点贡献，然而**每个主机的CPU却没有得到充分的利用**。因此，我们可以得出结论，CPU并非SolrCloud集群响应速度慢的瓶颈。这里，我们可以尝试**增加每个collection的shard数量**，以此提高查询时的并发量，更充分地利用主机的CPU资源。

3. 同一时间，另一机器的某个Solr节点CPU占用率如下图：	![]({{ site.url }}/assets/images/jmc15.png)

此时，该Solr节点CPU占用率为0，说明此节点并未执行查询操作。因此我们可以推测，**由于数据分布不均匀或是查询请求并未分配到该节点，使得该节点并未参与查询过程**。经排查，此处是由于客户端查询任务的分配逻辑有误，导致将查询任务仅仅分配给该SolrCloud集群的少数几个机器。解决该错误之后，该SolrCloud集群的相应速度提高了2倍左右。

## 内存使用量分析

内存的使用量主要用来分析程序是否占用过量内存，是否造成内存溢出等。点击JMC界面的“*内存按钮*”，可以在“*概览*”中看到机器内存使用量的信息。此外，依次点击JMC界面的“*一般信息*”按钮和“*堆使用量*”标签，还可看到该profiling对应的堆使用量信息。

由下面两图可以看出，主机内存为63GB，每个Solr节点允许的最大内存使用量为15GB。然而，此处每个Solr节点提交的堆内存(Committed Heap)仅略高于5GB，而真正使用的内存平均仅为2GB左右。可见，此时**内存并非SolrCloud集群的瓶颈**。注：由于Linux系统会大量使用内存作为文件系统缓存（File System Cache）,因此已使用的计算机物理内存接近计算机物理内存总量并不能说明此时有其它程序正在和Solr节点争抢内存资源。

![]({{ site.url }}/assets/images/jmc16.png)

![]({{ site.url }}/assets/images/jmc17.png)

## GC分析

GC（垃圾回收）有时会占用大量的时间，造成可观的延迟，尤其在内存资源不足的时候。依次点击JMC界面的“*内存*”按钮和“*GC时间*”标签，可以看到GC时间相关的信息。

由下图可以看出，在22超过22秒的时间内，GC占用的时间不到34毫秒。因此，**GC并非瓶颈**。注：由于本次profiling时间较短，并未触发年老代垃圾回收，所以缺少年老代收集时间的记录。![]({{ site.url }}/assets/images/jmc18.png)热点方法分析

热点方法指的是执行时间或次数最多的方法。通过热点方法分析，我们可以知道程序在哪部分执行时间较长，并进行针对性优化。需要注意的是，JFR的热点方法只记录真正执行的普通方法，对于那些导致线程睡眠、等待锁、等待I/O的方法以及native的方法是不会被记录的。依次点击JMC界面的“*代码*”按钮和“*热点方法*”标签，可以看到与热点方法相关的信息。

在本次的profiling中，笔者设置成每10毫秒记录一次java执行堆栈样本。然而，如下图所示，超过22秒的时间JFR总共只记录了38次样本。这说明该SolrCloud集群时间大部分都不在执行Java程序，换句话说，**Solr程序本身并非瓶颈**。因此，我们无需再过多分析热点方法。![]({{ site.url }}/assets/images/jmc19.png)

## 事件分析

事件指的是线程睡眠、等待锁、等待I/O等事件。若程序瓶颈不在于程序本身，那么通过对事件的分析，我们可以得出程序瓶颈所在。依次点击JMC界面的“*事件*”按钮和“*图形*”标签，可以看到各个线程发生过的事件，以及占用的时间。在左侧事件类型一栏中，我们可以选择包含该事件类型的线程。其中，橙色的事件表示的是文件读取。

上文我们已经分析得出Solr程序本身并非瓶颈，因此我们需要对事件进行分析。如下图所示，大量线程将大部分时间用在文件读取上（橙色部分）。因此我们可以初步判断，**Solr的性能瓶颈在于文件读取**。然而，即便如此，我们发现仍有少数线程并未将大量时间用于事件等待或事件执行上（绿色部分）。若是这些线程都在执行Solr程序，那么热点方法的样本计数应不止38次。因此我们仍需要进行线程分析，以确定这些线程是否确实在执行Solr程序。![]({{ site.url }}/assets/images/jmc20.png)

## 线程分析

线程信息包括热点线程（Hot Threads）、锁争用（Contention）以及线程堆栈信息等。本次profiling笔者设置成每分钟输出一次线程堆栈信息，可以依次点击JMC的“*线程*”按钮和“*线程转储（Thread Dumps）*”标签查看，如下图：![]({{ site.url }}/assets/images/jmc21.png)

这里，我们可以发现，上文在事件分析过程中提到的“并未将大量时间用于事件等待或事件执行上”的线程（绿色占大部分的线程），实际上是在执行native方法，导致并未被JFR记录。此处的native方法主要有两个，一个是“sun.nio.ch.EPollArrayWrapper.epollWait”，另一个是“sun.nio.ch.ServerSocketChannelImpl.accept0”。这里不再对此进行分析。

## I/O分析

I/O分析包括文件I/O分析和套接字I/O分析。利用JMC界面，我们可以直观地看出Java程序的文件读写情况（包括文件读写时间、文件名、读写字节数和读写次数等）和套接字读写情况（包括套接字读写时间、远程地址和端口、读写字节数和读写次数等）。这些信息可以通过点击JMC界面的“*I/O*”按钮以及对应的标签进行查看。

由上文的分析我们得知此SolrCloud集群的瓶颈在于文件读取，因此这里我们着重查看文件读取的信息，如下图。![]({{ site.url }}/assets/images/jmc22.png)

我们可以看到，大部分的文件读取都是对“*.dvd*”文件进行读取。在Lucene中，“*.dvd*”文件是用于保存Doc Values信息的文件。在文件读取跟踪树中，我们发现读取的Doc Values是被用于进行排序的（org.apache.lucene.search.FieldComparator$LongComparator用于对长整型类型进行比较和排序，此处作用为利用大顶堆保留值最小的前N个数据。），如下图：![]({{ site.url }}/assets/images/jmc23.png)

经过调查，笔者发现在所有查询的参数中，都指定了“sort=id asc”。**由于查询要求根据id进行排序，因此需要从保存Doc Values的文件中读取id的值，消耗了大量时间**。Solr默认根据score进行排序，这样相关度高的文档会排在前面，类似于搜索引擎返回的搜索结果。使用该SolrCloud集群的业务并无必须用id进行升序的必要，因此笔者去掉了该参数，使得该SolrCloud集群的响应速度大幅提升。去掉“sort=id asc”参数后，测试的查询返回时间在distributed模式下从10秒降到1秒，在非distributed模式下，从1秒降到300毫秒。

有趣的是，笔者发现Solr在查询中还读取了“*.fdt*”文件，这些文件是用来保存“stored field”信息的。经过调查，笔者发现读取该文件亦是为了读取id数据。因为参数中指定“fl=id,score”，所以返回结果包含id。因此除了在排序时对id进行了读取外，Solr还在生成返回结果时对id进行了第二次读取。由于查询指定每次只返回1000条记录（参数中指定“rows=1000”），因此排序时需要读取所有匹配文档的id，而生成返回结果时只需要读取这1000条记录的id，因此对“*.fdt*”文件的读取并未造成性能瓶颈。但笔者猜测，若能在排序时保存id数据，则生成文档时就不必再重新读取id数据，那么在返回记录数较多的情况下对性能的提高会有较大帮助。（由于id设置为docValues=true和stored=true，因此读取id时既可从保存Doc Values的文件中读取，亦可从保存Stored Fields的文件中读取。经测试，同样的配置在Solr 7.3.1中，排序和生成结果时都从保存Doc Values的文件中读取id数据。）

# 使用JFR和JMC分析性能瓶颈时的注意事项

JFR是非常简单、强大、实用的profiling工具。但在本次对SolrCloud集群进行分析时，笔者亦发现它有一些缺点，在profiling时必须较为小心，这些已在上文中有所提及：

1. 热点方法的采样不包括native的方法。事件类型的分析亦无法记录由native方法产生的事件。使用JFR对大量调用native方法的Java程序进行profiling可能会使profiling结果产生偏差。

2. 默认参数下，所有事件都必须超过10毫秒才会被记录。虽然可以调整参数，设置为任意事件都被记录，但这会导致在有大量事件的情况下产生较大的overhead。

若设置成文件读取时间为10毫秒才会被记录，那么JFR可能不会记录任何Solr的文件读取信息，因为虽然Solr频繁进行大量文件读取，但每次文件读取时间几乎都不超过10毫秒。若设置成所有文件读取都会被记录，则实验中同样的一次查询生成的profiling结果文件大小从500KB直接升为1.31GB。因为该查询产生超过五百一十万次的文件读取，全部记录这些信息需要大量的磁盘空间。而且，此时在热点方法的采样结果中亦会有不少被采样的方法由JFR产生。所以这种情况下可能需要根据不同的参数进行多次profling。

# 总结

Profiling是在对程序进行性能剖析、寻找性能瓶颈时的重要方法。本文向大家介绍了JDK自带的profiling工具：JFR和JMC，并举例讲解了这两工具的用法。此外，本文通过一次利用JFR和JMC工具对SolrCloud集群的profiling经历向大家详细介绍了用profiling进行性能分析的过程，也更清楚、直观地表现了profiling在进行性能分析时发挥的重要作用。最后，本文还提及了本次profiling时发现的JFR的缺点，希望读者们在使用JFR记录程序运行时信息时能够注意避开这些缺点。
