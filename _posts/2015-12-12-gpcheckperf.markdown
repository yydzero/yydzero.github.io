---
layout: post
title:  "gpcheckperf"
author: 姚延栋
date:   2015-12-12 10:20:43
categories: gpcheckperf
---

### 1. gpcheckperf 简介

GPDB 提供了一个工具检查系统的硬件性能，这个工具名字叫 `gpcheckperf`。 它支持以下性能测试：

* 网络性能 （gpnetbench*）
* 磁盘 IO （dd 测试）
* 内存带宽 （stream 测试）

使用 gpcheckperf 之前需要使用 gpssh-exkeys 设置无密码 ssh 访问所有待测试机器。

#### 1.1 用法

    // 测试网络性能
    gpcheckperf -d temp_directory
        {-f hostfile_gpchecknet | - h hostname [-h hostname ...]}
        [ -r n|N|M [--duration time] [--netperf] ] [-D] [-v | -V]


    // 测试磁盘IO和内存带宽
    gpcheckperf -d test_directory [-d test_directory ...]
        {-f hostfile_gpcheckperf | - h hostname [-h hostname ...]}
        [-r ds] [-B block_size] [-S file_size] [-D] [-v|-V]

    -D: 显示每个测试主机的结果
    --duration: 指定运行网络测试的时间
    --netperf：使用 netperf 而不是GPDB 自带的网络测试程序，需要区 netperf.org 下载。
    -r ds{n|N|M}: 执行运行的测试程序，缺省是 dsn
    -S file_size
    -v | -V: verbose

#### 1.2 网络性能测试

gpcheckperf 使用一个网络测试程序从本机传输 5 秒的 TCP 数据流给所有待测试节点。

网络测试有三种模式.

* 并行成对测试： -r N  （默认模式）
* 串行成对测试: -r n  如果默认模式发现网络性能比较差，则可以使用这个模式找到问题所在。
* 全网测试：-r M  可用于测试swtich的能力。

如果 GPDB 集群配置了多个网口和子网，则建议对所有子网进行测试。


例子：

     gpcheckperf -f hostfile_gpchecknet_ic1 -r N -d /tmp

     # 指定 NIC 运行测试
     gpcheckperf -h sdw1-2 -h sdw4-2 -r N -d /tmp >sdw1-2andsdw4-2.out

单节点不会执行网络测试。

#### 1.3 磁盘 IO 测试和内存测试

磁盘测试使用 dd 测试磁盘顺序读写的能力。默认处理的文件大小为内存容量的 2 倍，以保证测试的是磁盘IO而不是内存缓存。

内存带宽测试使用 STREAM 程序测试，主要用来查看和 CPU 计算能力相比，内存是否是瓶颈。如果内存的带宽远低于 CPU 带宽，
则CPU需要耗费大量cycle等待系统内存。

例子：

    gpcheckperf -r ds -h r7 -d ~/tmp


### 2. 运行结果例子

#### 2.1 macpro 上 RHEL7 虚拟机性能检查结果样例

* 内存：4G
* CPU：2

磁盘测试结果：

    gpcheckperf -r dsN -D -v -h r7 -d ~/tmp

    ====================
    ==  RESULT
    ====================

     disk write avg time (sec): 8.87
     disk write tot bytes: 7938048000
     disk write tot bandwidth (MB/s): 853.47
     disk write min bandwidth (MB/s): 853.47 [r7]
     disk write max bandwidth (MB/s): 853.47 [r7]
     -- per host bandwidth --
        disk write bandwidth (MB/s): 853.47 [r7]


     disk read avg time (sec): 5.00
     disk read tot bytes: 7938048000
     disk read tot bandwidth (MB/s): 1514.06
     disk read min bandwidth (MB/s): 1514.06 [r7]
     disk read max bandwidth (MB/s): 1514.06 [r7]
     -- per host bandwidth --
        disk read bandwidth (MB/s): 1514.06 [r7]

内存测试结果

    ○ → gpcheckperf -r s -h r7 -d ~/tmp
    /home/gpadmin/gpdb/gpdb.20151212/bin/gpcheckperf -r s -h r7 -d /home/gpadmin/tmp

    --------------------
    --  STREAM TEST
    --------------------

    ====================
    ==  RESULT
    ====================

     stream tot bandwidth (MB/s): 21290.88
     stream min bandwidth (MB/s): 21290.88 [r7]
     stream max bandwidth (MB/s): 21290.88 [r7]

#### 2.2 基于 ESX 的虚拟机结果例子

配置情况

* 内存： 32G， 由于内存比较大，而磁盘空间较小，所以使用了 -S 选项。

磁盘测试结果

    -bash-4.1$ gpcheckperf -rd -h g0 -d ~/tmp -S 20480000000
    /home/gpadmin/build/gpdb.master/bin/gpcheckperf -rd -h g0 -d /home/gpadmin/tmp -S 20480000000

    --------------------
    --  DISK WRITE TEST
    --------------------

    --------------------
    --  DISK READ TEST
    --------------------

    ====================
    ==  RESULT
    ====================

     disk write avg time (sec): 30.30
     disk write tot bytes: 20480000000
     disk write tot bandwidth (MB/s): 644.60
     disk write min bandwidth (MB/s): 644.60 [g0]
     disk write max bandwidth (MB/s): 644.60 [g0]


     disk read avg time (sec): 5.40
     disk read tot bytes: 20480000000
     disk read tot bandwidth (MB/s): 3616.90
     disk read min bandwidth (MB/s): 3616.90 [g0]
     disk read max bandwidth (MB/s): 3616.90 [g0]

内存测试结果

    ± |stream ?:2 ✗| →  gpcheckperf -r s  -d ~/tmp -h g0
    /home/gpadmin/build/gpdb.master/bin/gpcheckperf -r s -d /home/gpadmin/tmp -h g0

    --------------------
    --  STREAM TEST
    --------------------

    ====================
    ==  RESULT
    ====================

     stream tot bandwidth (MB/s): 10803.10
     stream min bandwidth (MB/s): 10803.10 [g0]
     stream max bandwidth (MB/s): 10803.10 [g0]


#### 一个GPDB cluster的测试结果

配置：

* CPU： 24 cores, Dell R510, 2 X5670
* 内存： 48G  (6 x 8GB DIMMS)
* 磁盘： 5.4T, H700 Internal RAID card, 12x 3.5” 6OOGB SAS


测试结果：

    /usr/local/greenplum-db/./bin/gpcheckperf -f /home/gpadmin/gpconfigs/hostfile_segments_nosdw3 -d /data1/1 -d /data1/2 -d /data1/3 -d /data2/1 -d /data2/2 -d /data2/3

    --------------------
    --  DISK WRITE TEST
    --------------------

    --------------------
    --  DISK READ TEST
    --------------------

    --------------------
    --  STREAM TEST
    --------------------

    -------------------
    --  NETPERF TEST
    -------------------

    ====================
    ==  RESULT
    ====================

     disk write avg time (sec): 88.75
     disk write tot bytes: 1212003385344
     disk write tot bandwidth (MB/s): 13055.24
     disk write min bandwidth (MB/s): 994.23 [sdw11]
     disk write max bandwidth (MB/s): 1154.79 [sdw12]


     disk read avg time (sec): 85.11
     disk read tot bytes: 1212003385344
     disk read tot bandwidth (MB/s): 13618.27
     disk read min bandwidth (MB/s): 1022.52 [ sdw6]
     disk read max bandwidth (MB/s): 1254.84 [sdw12]


     stream tot bandwidth (MB/s): 72491.28
     stream min bandwidth (MB/s): 5984.65 [sdw10]
     stream max bandwidth (MB/s): 6136.23 [sdw15]

    Netperf bisection bandwidth test
    sdw5 -> sdw6 = 1092.750000
    sdw7 -> sdw8 = 1054.080000
    sdw9 -> sdw10 = 1074.670000
    sdw11 -> sdw12 = 1072.420000
    sdw13 -> sdw14 = 1083.420000
    sdw15 -> sdw16 = 1075.410000
    sdw6 -> sdw5 = 1096.550000
    sdw8 -> sdw7 = 1091.640000
    sdw10 -> sdw9 = 1094.260000
    sdw12 -> sdw11 = 1093.730000
    sdw14 -> sdw13 = 1088.050000
    sdw16 -> sdw15 = 1099.570000

    Summary:
    sum = 13016.55 MB/sec
    min = 1054.08 MB/sec
    max = 1099.57 MB/sec
    avg = 1084.71 MB/sec
    median = 1091.64 MB/sec

