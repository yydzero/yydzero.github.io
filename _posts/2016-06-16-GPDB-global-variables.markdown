---
layout: post
title:  "GPDB global variables"
author: 姚延栋
date:   2016-06-17 15:49
categories: gpdb global variables
published: false
---

## GPDB Global Variables

### Process related

* Mode: NormalProcessing, InitProcessing, BootstrapProcessing
* MyProc

### Execution related

* ActivePortal:  the current running/executing portal
* ActiveSnapshot: currently acitve snapshot.

### Error related

* errordata

### Lock and Signal

* lockAwaited: 当前进程试图申请的lock.