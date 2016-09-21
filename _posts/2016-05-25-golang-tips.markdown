---
layout: post
title:  "Golang Tips"
subtitle: Golang 小技巧
author: 姚延栋
date:   2016-05-25 11:49
categories: golang tips
published: true
---

## Golang 小技巧

### once.Do 保证仅仅执行一次

典型的例子是使用 once.Do 实现 singleton： http://marcio.io/2015/07/singleton-pattern-in-go/

### 使用 defer 把函数结果放到 channel 中

这样函数可以同时返回结果给调用者； 也可以使用 goroutine 执行，并通过channel获得执行结果

    func (t *TestRunner) run(cmd *exec.Cmd, completions chan RunResult) RunResult {
    	var res RunResult

    	defer func() {
    		if completions != nil {
    			completions <- res
    		}
    	}()

    	err := cmd.Start()
    	if err != nil {
    		fmt.Printf("Failed to run test suite!\n\t%s", err.Error())
    		return res
    	}

    	cmd.Wait()
    	exitStatus := cmd.ProcessState.Sys().(syscall.WaitStatus).ExitStatus()
    	res.Passed = (exitStatus == 0) || (exitStatus == types.GINKGO_FOCUS_EXIT_CODE)
    	res.HasProgrammaticFocus = (exitStatus == types.GINKGO_FOCUS_EXIT_CODE)

    	return res
    }

### 通过 defer 统一处理错误

	func handle() (err error) {
		defer cn.errRecover(&err)
	}



### bytes.buffer WriteTo() 直接写入文件

	buf.WriteTo(file)

### template

golang template package provides a simple yet powerful template manipulating libraries.

	specTemplate, err := template.New("spec").Parse(templateText)
	if err != nil {
		return err
	}

	specTemplate.Execute(f, data)
	goFmt(targetFile)

### gdb with 'info goroutines'

需要使用 -gcflags 编译选项， 然后自动加载 runtime-gdb.py 脚本。

    $ cat ~/.gdbinit
    add-auto-load-safe-path /home/gpadmin/tools/go/src/runtime/runtime-gdb.py

    $ go build -gcflags "-N -l" -o gdb_sandbox main.go

    $ gdb -p <pid>
    (gdb)
    // 如果 runtime-gdb.py 没有被加载， 则 info gorutines 会报错。尝试手动加载：
    (gdb) source /home/gpadmin/tools/go/src/runtime/runtime-gdb.py


    (gdb) info goroutines
    ...

    (gdb) goroutine 340 bt

    (gdb) b github.com/bfosberry/gdb_sandbox/main.go:9
    (gdb) b 'main.main'

### Error handling

[Stack traces and the errors package](http://dave.cheney.net/2016/06/12/stack-traces-and-the-errors-package)

* In your own code, use errors.New or errors.Errorf at the point an error occurs.
* If you receive an error from another function, it is often sufficient to simply return it.
* If you interact with a package from another repository, consider using errors.Wrap or errors.Wrapf to establish a stack trace at that point. This advice also applies when interacting with the standard library.
* Always return errors to their caller rather than logging them throughout your program.
* At the top level of your program, or worker goroutine, use %+v to print the error with sufficient detail.

### goroutine scheduling points

* channel sending and receiving operations, if those operations would block
* blocking syscall like file and network operations
* go statement
* GC

[Five things that make Go fast](http://dave.cheney.net/2014/06/07/five-things-that-make-go-fast)
