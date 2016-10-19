---
layout: post
title:  "How to run privileged concourse containers"
author: Adam Lee
date:   2016-10-19 15:00 +0800
categories: concourse
published: true
---

For security reasons, we don't recommend enabling privileged by default, which makes some programs like GDB have no enough permissions to run. What if you want to do things like that?  

The key point is to execute a new one-off privileged task from command line.  

For example:

    ./fly -t foobar execute --privileged --config example.yml --inputs-from pipeline_foo/task_bar

This command runs task "example.yml" for one time, and inherits inputs (like gpdb_src) from a existing job "pipeline_foo/task_bar"  

Note: the yml file needs to contain all parameters it requires, you could pass to cmdline by using environment variables.  

Ref: http://concourse.ci/fly-execute.html
