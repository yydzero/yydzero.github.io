---
layout: post
title:  "golang 命令行工具"
author: 姚延栋
date:   2015-11-27 17:20:43
categories: golang gopath package
---

## golang 命令行工具

### gopath

    go help gopath

gopath 被 import 语句用来解决路径问题。实现和文档在 go/build 包中。

环境变量 GOPATH 列出了查找 Go 代码的所有路径: 例如 GOPATH=/home/user/gocode:/home/user/gpdb. 类似于 Java 中的 classpath。

在标准的 Go 目录外获取、编译和安装包时必须要设置 GOPATH。GOPATH 列出的每个目录必须有特定结构：

* src/ 目录包含源代码， src 下面的路径名字决定了 import 路径或者执行文件名字。
* pkg/ 目录包含安装的包。每个平台有自己对应的binary。 GOPATH/src/foo/bar 可以通过 foo/bar import，编译后
代码为 GOPATH/pkg/GOOS_GOARCH/foo/bar.a
* bin/ 目录包含编译的命令. 命令的名字是路径的最后一部分的名字。 如果设置了 GOBIN 环境变量，则安装到该路径下。

import 时通过 GOPATH 查找对应的包，但是下载的新包总是安装在第一个目录下。

### golang 包(packages)

    go help packages

很多命令以包为参数：go action [packages]。 通常 packages 是 import 是用到的路径名。

导入路径可以使 GOROOT 路径下的导入路径。如果是 . 或者 ..，则表示对应的文件系统路径下的所有包。
如果找不到，则根据 GOPATH 列出的路径查找。例如导入路径 P 表示 GOPATH 中列出的所有路径 DIR 下的第一个
DIR/src/P。

如果没有指定 import path，则对当前目录下的包执行 action 操作。

特殊路径名字：

* main: 表示最外层的包
* all：表示 GOPATH 路径下的所有包路径，例如 `go list all` 列出本地系统上的所有包。
* std: 和 all 类似，但是仅限于标准 go 库。

go 工具会忽略掉以 . 或者 _ 开头的路径或者文件，名为 testdata 的目录也会被忽略。

#### 导入路径模式

如果导入路径包括一个或者多个 `...` 则表示是一个 pattern。每个 `...` 匹配任意字符串，包括空字符串和
包含斜线的字符串。例如 net/... 匹配 net 和其所有子目录。

### importpath

    go help importpath

一个导入路径（import path）对应本地文件系统上的一个包。一般来说一个导入路径或者对应一个标准包（例如 unicode/utf8),
或者对应 GOPATH 下的一个包。