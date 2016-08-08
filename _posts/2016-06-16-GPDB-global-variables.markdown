---
layout: post
title:  "GPDB global variables"
author: 姚延栋
date:   2016-06-17 15:49
categories: gpdb global variables
published: false
---

## GPDB Global Variables and Routines

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

### Inspectation

* nodeToString
* print.c
  * print
  * pprint
  * pretty_format_node_dump
  * format_node_dump
  * elog_node_display(int lev, const char *title, const void *obj, bool pretty): send pretty-printed contents of Node to postmaster log
  * print_slot(TupleTableSlot *slot):  print out the tuple with the given TupleTableSlot
  * print_tl(const List *tlist, const List *rtable): print targetlist in a more legible way.
  * print_pathkeys(const List *pathkeys, const List *rtable)
  * print_expr(const Node *expr, const List *rtable)
  * print_rt(const List *rtable): print contents of range table


## lldb tips

### lldb: How to print complete char* string

    (lldb) set set target.max-string-summary-length 10000

### vim replace \n with newline

    %:s/\\n/CTRL-VCTRL-M/g