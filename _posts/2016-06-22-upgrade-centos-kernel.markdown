---
layout: post
title:  "Resolve gpdb hanging on getaddrinfo() && Upgrade linux kernel to latest version"
subtitle: linux 内核升级
author: PengzhouTang
date:   2016-06-22 11:49
categories: gpdb
published: true
---

## Problem

On centos7/rhel7, gpdb may hangs on recvmsg()/getaddrinfo() because of linux kernel bug, to address this we need to upgrade the kernel to latest version.

```
(gdb) bt
#0  0x00007fbef526a18d in recvmsg () from /lib64/libc.so.6
#1  0x00007fbef528c9fd in make_request () from /lib64/libc.so.6
#2  0x00007fbef528cef4 in __check_pf () from /lib64/libc.so.6
#3  0x00007fbef5252fb9 in getaddrinfo () from /lib64/libc.so.6
#4  0x0000000000a70f99 in setupUDPListeningSocket (listenerSocketFd=listenerSocketFd@entry=0x201e0fc,
    listenerPort=listenerPort@entry=0x7ffe2f22ca30, txFamily=txFamily@entry=0x201e100) at ic_udpifc.c:1233
#5  0x0000000000a7dcf2 in startOutgoingUDPConnections (pOutgoingCount=<synthetic pointer>,
    sendSlice=<optimized out>, transportStates=<optimized out>) at ic_udpifc.c:2991
#6  SetupUDPIFCInterconnect_Internal (estate=<optimized out>) at ic_udpifc.c:3470
#7  SetupUDPIFCInterconnect (estate=estate@entry=0x200e2e0) at ic_udpifc.c:3531
#8  0x0000000000a6f685 in SetupInterconnect (estate=estate@entry=0x200e2e0) at ic_common.c:672
#9  0x00000000006c85e7 in ExecutorStart (queryDesc=queryDesc@entry=0x1fc9f70, eflags=0) at execMain.c:559
#10 0x00000000008acceb in PortalStart (portal=portal@entry=0x200c2c0, params=params@entry=0x0,
    snapshot=snapshot@entry=0x0, seqServerHost=seqServerHost@entry=0x200517c "10.153.101.106",
    seqServerPort=seqServerPort@entry=10143, ddesc=ddesc@entry=0x20599d0) at pquery.c:832
#11 0x00000000008a4345 in exec_mpp_query (
    query_string=query_string@entry=0x2004be2 "SELECT ow_sale.pn,ow_sale.vn, TO_CHAR(COALESCE(MIN(floor(ow_sale.prc)) OVER(win1),0),'99999999.9999999')\nFROM (SELECT ow_sale_ord.* FROM ow_sale_ord,ow_customer,ow_vendor WHERE ow_sale_ord.cn=ow_custo"..., serializedQuerytree=serializedQuerytree@entry=0x0,
    serializedQuerytreelen=serializedQuerytreelen@entry=0,
    serializedPlantree=serializedPlantree@entry=0x2004d18 "d\017",
    serializedPlantreelen=serializedPlantreelen@entry=924, serializedParams=serializedParams@entry=0x0,
    serializedParamslen=serializedParamslen@entry=0,
    serializedQueryDispatchDesc=serializedQueryDispatchDesc@entry=0x20050b4 "\314\001",
    serializedQueryDispatchDesclen=serializedQueryDispatchDesclen@entry=200,
    seqServerHost=seqServerHost@entry=0x200517c "10.153.101.106", seqServerPort=seqServerPort@entry=10143,
    localSlice=localSlice@entry=2) at postgres.c:1351
#12 0x00000000008a9d5d in PostgresMain (argc=<optimized out>, argv=argv@entry=0x1e213a0,
    dbname=0x1e21300 "regression", username=<optimized out>) at postgres.c:5152
#13 0x000000000083a6f2 in BackendRun (port=0x1e31530) at postmaster.c:6716
#14 BackendStartup (port=0x1e31530) at postmaster.c:6403
#15 ServerLoop () at postmaster.c:2458
#16 0x000000000083b939 in PostmasterMain (argc=argc@entry=15, argv=argv@entry=0x1dfe430) at postmaster.c:1537
#17 0x00000000004c91ff in main (argc=15, argv=0x1dfe430) at main.c:20
```


## Upgrade steps

###Add ELRepo

```
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
```

###Install Linux Kernel

```
yum --enablerepo=elrepo-kernel install kernel-ml
```

###Config grub2

```
1. check current default boot option
[gpadmin@sdw6 ~]$ sudo grub2-editenv list
saved_entry=Red Hat Enterprise Linux Server (3.10.0-327.26.1.el7.x86_64) 7.2 (Maipo)

2. list all available boot option
[gpadmin@sdw6 ~]$ sudo cat /boot/grub2/grub.cfg|grep "Red Hat"
menuentry 'Red Hat Enterprise Linux Server (4.6.2-1.el7.elrepo.x86_64) 7.2 (Maipo)' --class red --class gnu-linux --class gnu --class os --unrestricted $menuentry_id_option 'gnulinux-3.10.0-327.el7.x86_64-advanced-fadf9432-61f2-4e1a-a082-f953f096b835' {
menuentry 'Red Hat Enterprise Linux Server (3.10.0-327.26.1.el7.x86_64.debug) 7.2 (Maipo)' --class red --class gnu-linux --class gnu --class os --unrestricted $menuentry_id_option 'gnulinux-3.10.0-327.el7.x86_64-advanced-fadf9432-61f2-4e1a-a082-f953f096b835' {
menuentry 'Red Hat Enterprise Linux Server (3.10.0-327.26.1.el7.x86_64) 7.2 (Maipo)' --class red --class gnu-linux --class gnu --class os --unrestricted $menuentry_id_option 'gnulinux-3.10.0-327.el7.x86_64-advanced-fadf9432-61f2-4e1a-a082-f953f096b835' {

3. change first boot option to 4.6.2
[gpadmin@sdw6 ~]$ sudo  grub2-set-default "Red Hat Enterprise Linux Server (4.6.2-1.el7.elrepo.x86_64) 7.2 (Maipo)"

[gpadmin@sdw6 ~]$ sudo grub2-editenv list
saved_entry=Red Hat Enterprise Linux Server (4.6.2-1.el7.elrepo.x86_64) 7.2 (Maipo)

4. Reboot

```
