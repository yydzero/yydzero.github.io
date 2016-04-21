---
layout: post
title:  "Disable GPDB Unix Domain Socket Access"
author: 姚延栋
date:   2016-04-18 09:20:43
categories: gpdb domain socket
published: true
---

有些时候希望强制 psql 使用 TCP 连接 GPDB，而非 UNIX domain socket。

    listen_addresses = '*'      # what IP address(es) to listen on;
                                # comma-separated list of addresses;
                                # defaults to 'localhost'; use '*' for all
                                # (change requires restart)
    #port = 5432                # (change requires restart)

    max_connections = 100           # (change requires restart)
    unix_socket_directories = ''    # comma-separated list of directories
                                    # (change requires restart)


访问方式：

    psql postgres -p 9500 -h localhost