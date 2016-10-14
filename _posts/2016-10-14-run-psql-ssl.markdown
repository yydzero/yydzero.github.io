---
layout: post
title:  "psql with SSL"
subtitle:  "使用 psql SSL 方式连接GPDB"
author: Peifeng Qiu, Haozhou Wang
date:   2016-10-14 13:23 +0800
categories: tools
published: true
---

To enable SSL connection in sql, we can follow the instruction in below:

1. Generate certificate

```sh
openssl req -new -text -out server.req -nodes
openssl rsa -in privkey.pem -out server.key
rm privkey.pem
openssl req -x509 -in server.req -text -key server.key -out server.crt
chmod og-rwx server.key
```

2. Copy server.* to both master data and segment data directory

3. sync gpdb configuration to enable ssl

```
gpconfig -c ssl -v on
```

4. Restart gpdb to enable SSL connection

5. Connect with SSL

```
psql -h hostname
```

or

```
psql "sslmode=require host=hostname dbname=dbname"
```

Then psql console will show:

```
psql (8.2.15)
SSL connection (cipher: DHE-RSA-AES256-SHA, bits: 256)
Type "help" for help.

test=#
```


