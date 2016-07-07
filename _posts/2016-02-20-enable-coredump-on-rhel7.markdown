---
layout: post
title:  "Enable RHEL7 core dump"
subtitle:  "开启 RHEL7 core dump"
author: 姚延栋
date:   2016-02-20 14:20:43
categories: makefile
published: true
---

RHEL7 的 `systemd` 默认阻止任何用户或者系统 daemon 产生 core 文件。传统的 /etc/security/limits.conf
对用户进程仍然有效，但是对 systemd 处理的系统进程则无效了。

### coredump 文件位置

可以设置下面的 sysctl 变量，或者创建下面文件：

    /etc/sysctl.d/core.conf
        kernel.core_pattern = /var/lib/coredumps/core-%e-sig%s-user%u-group%g-pid%p-time%t
        kernel.core_uses_pid = 1
        fs.suid_dumpable = 2

创建coredump目录：

    $ sudo mkdir -p /var/lib/coredumps
    $ sudo chmod 773 /var/lib/coredumps

### 为用户进程激活 coredump

    /etc/security/limits.d/core.conf
        *       hard        core        unlimited
        *       soft        core        unlimited

重新登录即可生效。

### 为守护进程激活 coredump

systemd 允许所有服务在自己的 .service 文件中设置自己的 limits，如果没有设置，则使用 /etc/systemd/system.conf

    /etc/systemd/system.conf
        DefaultLimitCORE=infinity
