---
layout: post
title:  "libpq messages"
author: 姚延栋
date:   2016-04-18 17:20:43
categories: gpdb libpq message
published: true
---

libpq 是 PostgreSQL 服务器和客户端的通讯协议。支持简单查询（Simple Query）和扩展查询（Extended Query）。

下面以一个例子介绍扩展查询时的消息交换格式和顺序：

下面是一段 golang 代码：

        age := 20
    	rows, err := db.Query("SELECT name, age, description FROM users WHERE age > $1", age)
    	if err != nil {
    		log.Fatal(err)
    	}
    	defer rows.Close()

    	// Iterate Query Result.
    	for rows.Next() {
    		var name string
    		var desc string
    		if err := rows.Scan(&name, &age, &desc); err != nil {
    			log.Fatal(err)
    		}
    		fmt.Printf("%s is %d, %q\n", name, age, desc)
    	}

    	if err := rows.Err(); err != nil {
    		log.Fatal(err)
    	}

这段代码执行时的libpq消息顺序是

    Client                              Server

            -> Startup message
                extra_float_digits=2
                user=m
                database=test
                client_encoding=UTF8
                datastyle=ISO, MDY


            <- Authentication request
                application_name='', client_encoding=UTF8,DateStyle=ISO\,\ MDY,server_version=9.5,...

            -> P/D/S
               Parse
                    Query: SELECT name, age, description FROM users WHERE age > $1
               Describe
               Sync

            <- 1/t/T/Z
               Parse completion
               Parameter description
               Row description
               Ready for query

            -> B/E/S
               Bind
               Execute
               Sync

            <- 2/D/D/C/Z
               Bind completion
               Data row
               Data row
               Command completion
               Ready for query