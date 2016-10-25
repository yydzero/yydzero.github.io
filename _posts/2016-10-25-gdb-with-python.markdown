---
layout: post
title:  "GDB python"
author: 刘奎恩/Kuien
date:   2016-10-25 17:58 +0800
categories: tools
published: true
---

By default, we cannot display debug info from Python with `gdb`
, and we do not have `pdb` either. What we need to do is (on CentOS 7.2):

```sh
yum install yum-utils
debuginfo-install glibc
yum install gdb python-debuginfo
```

**NOTE**:

make sure `/etc/yum.repos.d/debuginfo.repo` exists, otherwise `debuginfo-install` will fail.

Then we may debug python, for example:

```
gdb python

# run dumpcore.py

# py-bt
```
