---
layout: post
title:  "golang internal"
date:   2016-08-08 09:54 +0800
categories: docker 
published: true
---

# golang internal

## golang runtime

golang runtime 提供了 GC，goroutine 调度，timers，network polling 等。此外还提供了丰富的调试能力。

### runtime debugging env variables

#### GOGC

GOGC 控制 gc 的时机，缺省值是100， 意味着heap从上次 GC 后增长一倍时，触发GC。 增大或者缩小这个变量，可以延缓或者提前进行GC

#### GOTRACEBACK

GOTRACEBACK 控制 panic 的详细程度， 缺省值是1， 表示显示所有goroutines的stack，但是和 runtime 相关的stack frames 会省略。

GOTRACEBACK=crash 会造成segfault，如果OS允许，会生成 core。

从 golang 1.6， GOTRACEBACK 的值变为 none, single, all, system, crash.

#### GOMAXPROCS

从 1.5 开始， GOMAXPROCS 是在启动时， 程序可用的 CPU 的个数。

#### GODEBUG

GODEBUG 可以设置名字、值对以控制对不同组件的调试。 例如：

    $ env GODEBUG=gctrace=1,schedtrace=1000 godoc -http=:8080

支持的参数：

* gctrace： heap scavenger 的输出很有意义，它的目的是周期性清除掉os未用的pages。
* schedtrace: 和 scheddetail=1 合用会输出每个goroutine的信息。 

## goroutine scheduler

调度器的职责是将等待运行、处于就绪状态的 goroutines 分发给工作线程。 设计文档： https://golang.org/s/go11sched

主要概念有：

* G - goroutine
* M - worker thread 或者 machine
* P - processor, a resource that is required to execute Go code

## 5 things make golang fast from Dave

* Values are compact, so that CPU cache could have better hits.
* Inline automatically for some functions to avoid function call cost, like stack frame handling, registers, call jump
* Escape analysis to allocate on stack or heap automatically to avoid unnecessary GC
* Goroutines provide better performance for concurrency than processes/threads. cost avoid include registers handling, MMU handling, kernel space switch. Goroutines only switch at well defined points (basically when need block)
* Segmented and copying stacks, no guard pages, dynamically grow

[Original article](http://dave.cheney.net/2014/06/07/five-things-that-make-go-fast)