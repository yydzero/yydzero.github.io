---
layout: post
title: "Fix JVM crash in new linux kernel"
author: Haozhou Wang
date: 2017-08-07 18:00:00 +0800
comments: true
---

在最新的Redhat 6和7上，运行JVM的时候会碰到JVM崩溃的问题，JVM报告SIGBUS ERROR，然后退出。这个问题和JVM的版本无关，使用最新的java 1.7和1.8都可以复现这个问题。

导致这个问题的原因是因为为了解决一个有关stack overflow的安全问题CVE-2017-1000364，linux kernel打了一个最新的kernel补丁，提升了stack guard gap size 从 one page 到 1MB。这个patch使得JVM在默认配置下直接崩溃。

现在官方提供的workaround的方法是手动提升Java stack size的大小，在启动JVM的时候，设置参数**-Xss2M**就可以了。

### ref:
1, [Linux Patch for CVE-2017-1000364](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/commit/?id=1be7107fbe18eed3e319a6c3e83c78254b693acb)
2, [Redhat 社区问题报告](https://access.redhat.com/solutions/3091371)
3, [Workaround](https://www.cloudlinux.com/cloudlinux-os-blog/entry/jvm-crashes-occurring-after-upgrading-to-a-kernel-with-the-fix-for-stack-clash)
