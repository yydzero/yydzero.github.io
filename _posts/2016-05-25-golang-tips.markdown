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

