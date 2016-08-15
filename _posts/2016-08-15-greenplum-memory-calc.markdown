---
layout: post
title:  "golang memory calculator"
date:   2016-08-15 09:54 +0800
categories: gpdb memory calc
published: true
---

# Why use the calculator?

GPDB virtual memory calculator estimates the best virtual memory settings based on existing large scale deployments. The linux kernel is very good at optimizing its own memory, but we still have to ensure we do not overallocate GPDB memory resulting in out of memory events. This calculator helps the user reserve a conservative amount of memory for kernel while maximizing the amount of memory used by GPDB.
For more information refer to GPDB documentation.

For online calc: Access [this](http://greenplum.org/calc/)
