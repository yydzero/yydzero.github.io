---
layout: post
title:  "在VMWare上运行CentOS时遇到SMBus错误的解决方法"
author: 刘奎恩
date:   2016-01-22 14:49:24
categories: sandbox, vmware
published: true
---

最近有学生问我在试用Greenplum Database的时候，启动VMWare虚拟机会遇到如下错误：

```
piix4_smbus 0000:00:007.3: Host SMBus controller not enabled! 
```

我后来发现我自己的RHEL7在Mac上启动时也有这个问题（汗，之前没注意到），张贴一下：

```
This error can be easily fixed by adding the extra line to the bottom of
/etc/modprobe.d/blacklist.conf:
    blacklist i2c_piix4
```

一些可能有用的命令：

```
sudo cat /var/log/messages |grep "Host SMBus" -b5
lsmod | grep -i i2c_piix4
lspci -v |grep -i piix -b3
```

PS: 我还顺手屏蔽了另外一个问题：

```
sd 0:0:0:0: [sda] Assuming drive cache: write through

sudo update-pciids  //更新PIC ID list
sudo dmesg -n 1     //关掉终端输出
```
