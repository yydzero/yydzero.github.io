---
layout: post
title:  "golang profiling"
author: Yandong Yao
date:   2016-07-31 11:49
categories: golang profiling
published: true
---

# golang profiling

`runtime/pprof` 包提供了生成 profiling 信息的底层函数. net/http/pprof 包可以 profiling 运行的应用.

github.com/pkg/profile 使得 profiling 变得更简单,只需要在 main 中调用下面代码即可:

	defer profile.Start(profile.CPUProfile).Stop()

## 使用简介

pprof 使用 instrumentation 的方式在应用代码中加入代码,以监控程序的运行,收集运行数据.

使用 github.com/pkg/profile 并在 main 中调用上面的函数.

	$ go build
	$ ./myprogram

程序结束后会自动生成 profile 文件.

### 使用命令接口

#### 使用文本方式显示

	// 用文本方式显示 top entries (这里的 entry 可以是内存消耗,也可以是耗时, 由生成 profile 时的选择而定)
	$ go tool pprof -text ./myprogram /path/to/cpu.pprof

	// 以 cum 方式排序
	$ go tool pprof -text -cum  main /tmp/profile180024144/cpu.pprof

输出字段的含义:

* flat: 函数自身执行所用的时间, the time in a function.
* cum: 执行函数自身和其调用的函数所用的时间和, cumulative time a function and everything below it.

#### 生成 pdf

	$ go tool pprof -pdf main /tmp/profile180024144/cpu.pprof

## Profile 类型

使用 net/http/pprof 可以通过 HTTP 访问正在运行的应用程序 profile 数据:

	import _ "net/http/pprof"

	...

	http.ListenAndServe(":8080", http.DefaultServeMux)

然后可以通过 /debug/pprof 获取 profile 数据

* 内存: http://localhost:8080/debug/pprof/heap
* CPU: http://localhost:8080/debug/pprof/profile
* goroutine blocking profile: http://localhost:8080/debug/pprof/block

### HEAP profile

HEAP profile 可以用于:

* 确定某个时刻程序的 heap 里面的数据
* 定位内存泄露
* 找到程序中大量内存分配的代码

使用 top 命令显示最耗用内存的函数

	$ go tool pprof http://localhost:8080/debug/pprof/heap
	(pprof) top				// 按 flat 时间排序

	(pprof) top50 -cum		// 按 cum 时间排序

### CPU profile

	$ go tool pprof http://localhost:8080/debug/pprof/profile

### 自定义 profile

## 生成报告

pprof 工具提供了可视化方法,可以使用 web 命令保存 profile 数据到 svg 图形中.


## 参考

* A pattern for optimizing Go: https://signalfx.com/blog/a-pattern-for-optimizing-go-2/
