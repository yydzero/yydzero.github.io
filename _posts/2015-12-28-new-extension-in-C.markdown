---
layout: post
title:  "用C语言扩展模块实现自己的UDF"
author: 刘奎恩
date:   2015-12-28 11:39:24
categories: udf,extension
published: true
---

### Linux下可以这么做

Linux下用C扩展一个UDF，至少需要写4个文件：
1. xxxx.h
  里面是C函数代码，会编译成.so文件
2. xxxx.sql
  里面是SQL代码，会告诉数据库这个UDF调用哪个.so文件的哪个函数
3. Makefile
  告诉PG编译环境，这是哪个模块，这里面SQL叫啥，C代码叫啥，安装时会放在哪儿
4. ReadMe
  把#1~#3贴进去，作为文档

### Windows下可以这么做

  1. 参见何雄的帖子：http://blog.csdn.net/iihero/article/details/8218753
  2. 搜索CMake相关技术
