---
layout: post
title:  "gpcheckperf"
author: 姚延栋
date:   2015-12-12 10:20:43
categories: gpcheckperf
---

### gpcheckperf 简介

GPDB 提供了一个工具检查系统的硬件性能，这个工具名字叫 `gpcheckperf`。 它支持以下性能测试：

* 网络性能 （gpnetbench*）
* 磁盘 IO （dd 测试）
* 内存带宽 （stream 测试）

使用 gpcheckperf 之前需要使用 gpssh-exkeys 设置无密码 ssh 访问所有待测试机器。

#### 用法

    // 测试网络性能
    gpcheckperf -d temp_directory
        {-f hostfile_gpchecknet | - h hostname [-h hostname ...]}
        [ -r n|N|M [--duration time] [--netperf] ] [-D] [-v | -V]


    // 测试磁盘IO和内存带宽
    gpcheckperf -d test_directory [-d test_directory ...]
        {-f hostfile_gpcheckperf | - h hostname [-h hostname ...]}
        [-r ds] [-B block_size] [-S file_size] [-D] [-v|-V]

* -D: 显示每个测试主机的结果
* --duration: 指定运行网络测试的时间
* --netperf：使用 netperf 而不是GPDB 自带的网络测试程序，需要区 netperf.org 下载。
* -r ds{n|N|M}: 执行运行的测试程序，缺省是 dsn
* -S file_size
* -v | -V: verbose

#### 网络性能测试

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

#### 磁盘 IO 测试和内存测试

磁盘测试使用 dd 测试磁盘顺序读写的能力。默认处理的文件大小为内存容量的 2 倍，以保证测试的是磁盘IO而不是内存缓存。

内存带宽测试使用 STREAM 程序测试，主要用来查看和 CPU 计算能力相比，内存是否是瓶颈。如果内存的带宽远低于 CPU 带宽，
则CPU需要耗费大量cycle等待系统内存。

例子：

    gpcheckperf -r ds -h r7 -d ~/tmp


### 虚拟机性能检查结果

* 内存：4G
* CPU：2

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