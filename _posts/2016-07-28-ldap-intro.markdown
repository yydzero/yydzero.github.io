---
layout: post
title:  "OpenLDAP Introduction"
subtitle: OpenLDAP 介绍
author: Yandong Yao
date:   2016-07-28 11:49
categories: ldap rhel
published: true
---

# OpenLDAP

关于 OpenLDAP 的几个主要信息:

* OpenLDAP 使用树形结构管理数据, 类似文件系统, 为搜索/浏览/查询而优化, 支持修改
* OpenLDAP 的基本数据单元是 entry (类似文件系统中的文件)
* entry 可以有很多属性, entry 可以有哪些属性(或者说 entry 的 schema )由 objectClass 定义, 一个 entry 可以有多个 objectClass.

## OpenLDAP 目录服务介绍

### 什么是目录服务

目录服务（Directory）是一种特殊的数据库，其主要设计目标是搜索和浏览，此外还可以支持基本的lookup和更新。

目录包含基于属性的描述性信息，并支持负责的过滤条件。不支持复杂事物。更新比较简单。目录的主要优化目标是快速处理大量的查询和搜索操作。

有人认为 DNS 是一种分布式目录服务，然后 DNS 仅仅支持 lookup 而不支持搜索和浏览。

### 什么是 LDAP

LDAP 是轻量级目录访问协议，它是访问目录服务（特别是基于 X.500 的目录服务）的一个轻量级协议，是 IETF 标准。参见 RFC 4510.

LDAP 可以存储什么样的信息:  LDAP 中的数据基本单元是 entries。entry 是带有全局唯一标识（DN， Distinguished Name）的属性（attribute）集合。每个entry的属性
包含一个类型和一个或者多个值。类型都是表示特定数据的字符串，譬如 "cn" 表示名字，“mail” 表示邮件地址。 值的语法依赖于属性类型。

LDAP 如果组织信息：目录中 entries 以树形结构组织在一起。通常这种结构反映了地理或者组织架构。目前比较流行的树形组织方式是基于 Internet
域名的，这种方式由于可以使用 DNS 定位而变得比较流行。 这种entry的类型名字为 dc。

此外 LDAP 可以通过一个特殊属性 `objectClass` 控制一个 entry 允许那些属性及必须含有那些属性。 objectClass 属性的值决定了一个entry必须
遵守的模式规则。

entry 类似于 RDMBS 中的行，属性类似于字段，而 objectClass 属性类似于 RDMBS 中的schema。

LDAP 信息标志：entry 由 DN 标志，DN 有它自己的名字和其父节点的名字串联而成。

LDAP 是 CS 结构，LDAP 服务器可以有多台，他们共同组成 目录信息树（Directory information tree，DIT）。不管客户端连接到那个服务器，他们
看到的数据是一致的。

### X.500

X.500 是 OSI 目录服务，它比较重，使用整个 OSI 协议栈。而LDAP直接使用 TCP/IP，比较轻量级。

LDAP 的守护进程 slapd 是一个轻量级的 X.500 目录服务器，它没有实现完整的 X.500 协议。

### LDAPv3

LDAPv3 是90年代后期开发的，它引入了下面特性：

* 支持 SASL 强认证和数据安全服务
* 通过 TLS/SSL 认证
* 支持 Unicode
* Referrals 和 Continuations
* Schema Discovery
* 可扩展性

默认 LDAPv2 是不支持的。

### LDAP vs. RDMBS

LDAP 内部使用 key/value 存储，而没有使用 RDMBS。这样可以提供更好的性能和扩展性。

### slapd

slapd 是一个跨平台的 LDAP 目录服务器。它提供了下面特性：

* LDAPv3
* SASL 支持：使用了 Cyrus SASL，其中包括 DIGEST-MD5,EXTERNAL, GSSAPI 等机制
* TLS： slapd 的 TLS 实现支持 OpenSSL，GnuTLS，MozNSS
* 拓扑控制：支持基于网络拓扑信息的访问控制
* 访问控制：非常灵活的访问控制
* 国际化
* 数据库后端： slapd 可以使用多种数据库后端，包括 MDB，BDB，HDB，SHELL，Password。 MDB 使用 LMDB，BDB和HDB都是用伯克利数据库。推荐使用 MDB
* 通用模块 API
* 多线程
* 副本
* Proxy cache
* 配置简单：可以通过单个配置文件，也可以使用 LDAP 自身进行配置。

默认 slapd 数据库允许所有人读访问。

## 安装 LDAP

### 安装依赖

可能依赖 TLS、SASL，Kerberos 等包。

如果有依赖位于非系统目录，使用如下方式编译：

	$ ./configure --enable-wrappers \
		CPPFLAGS="-I/usr/local/include" \
		LDFLAGS="-L/usr/local/lib -Wl,-rpath,/usr/local/lib"

	$ make depend && make -j4
	$ make test
	$ sudo make install

## 配置 slapd

从 OpenLDAP 2.3 开始建议使用动态运行配置引擎 slapd-config 进行配置。优势：

* 使用标准 LDAP 操作管理
* 存储它的配置数据到 LDIF 数据库中，通常保存在 /usr/local/etc/openldap/slapd.d 目录下。
* 动态修改所有 slapd 配置参数，不需要重启

仍然支持通过 slapd.conf 配置 OpenLDAP，然后deprecated了，将来可能去掉。

注意： 尽管 slapd-config 使用LDIF文本文件保存配置信息，但是严禁直接编辑 LDIF 文件。务必使用 LDAP 操作修改这些配置信息，包括 ldapadd,
ldapdelete, ldapmodify.

### 配置架构

slapd 的配置信息保存在特殊的 LDAP 目录中，该目录有预定义的 schema 和 DIT（目录信息树），也就是说配置信息有自己预先定义好的 schema 和
树形架构。有特殊的 objectClass 表示全局配置信息，schema 定义，backend数据库定义等。

						cn=config
						Global config options
					/			|				\
				  /				|				 \
	cn=module{0}			cn=schema				olcDatabase={1}bdb
	A set of modules		System schema			A back-bdb instance
						   /			\
						  /				 \
					cn={0}core			cn={1}cosine
					Core schema			COSINE schema

slapd-config 的 DIT（配置树）有非常独特的结构，该树的根 entry 的名字为 cn=config, 其中包括全局配置信息。其他设置在各种子 entries 中。

* 动态加载模块：只有使用 enable-modules 才可用
* schema 定义：DN 为 `cn=schema,cn=config` 的 entry 包含系统 schema 定义 (所有硬编码到 slapd 中的 schema). `cn=schema,cn=config`
的子 entries 包含用户 schema (可以是从配置文件加载的或者运行时加入的)
* Backend/Database 相关配置

LDIF 文件基本格式:

* 注释以 # 开头
* 如果行第一个字符是单个空格,则认为是上一行的继续,即使上一行是注释,且单个空格会被删除
* entries 之间使用空行隔开

有些 entry 有{X} ,这个是用来保证 entry 顺序的,因为底层的数据库本质是无需的,通过这种方式可以提供 entries 的有序性.

slapd 配置中使用的大部分属性名字和 objectClass  名字都有一个前缀: "olc" (OpenLdap Configuration).

OpenLDAP 发布中包含例子配置文件,默认位于 /usr/local/etc/openldap, /usr/local/etc/openldap/schema 包括一些 schema 定义(属性类型和
objectclass)

### 配置指令

#### cn=config

这个 entry 中的属性指令应用于整个 slapd 服务器. entry 内大多数指令是系统级别或者 session 级别的,和数据库无关. 这个 entry 的 objectclass 必须
`olcGlobal`.

* olcIdleTimeout: 空闲 client 连接超时值, 超过这个时间,强制管理client 连接
* olcLogLevel: 设置 log 级别, log 使用 syslogged (需要 --enable-debug). `slapd -d?` 显示 debug 级别. -1 或者 any 启用所有 debugging.
  conns 启用连接管理日志. 默认级别是 stats.
* olcReferral: 指定转发 ldap 服务器, 譬如 `olcReferral: ldap://root.openldap.org`

例子:

	dn: cn=config
	objectClass: olcGlobal
	cn: config
	olcIdleTimeout: 30
	olcLogLevel: Stats
	olcReferral: ldap://root.openldap.org

#### cn=module

如果激活了动态模块加载,使用 cn=module entries 可以指定要加载的模块. objectClass 必须是 olcModuleList. 例子:

	dn: cn=module{0},cn=config
	objectClass: olcModuleList
	cn: module{0}
	olcModuleLoad: /usr/local/lib/smbk5pwd.la

	dn: cn=module{1},cn=config
	objectClass: olcModuleList
	cn: module{1}
	olcModulePath: /usr/local/lib:/usr/local/lib/slapd
	olcModuleLoad: accesslog.la
	olcModuleLoad: pcache.la

#### cn=schema

这个 entry 包含 slapd 内建支持的 schema 定义. 所以这个 entry 的值是有 slapd 生成的,所以配置文件中不需要提供信息. 但是必须
定义这个 entry, 以作为用户自定义 schema 的基础. schema entries objectClass 必须是 olcSchemaConfig.

* olcAttributeTypes: 本指令定义属性类型.
* olcObjectClasses: 本指令定义 object class.

例子:

	dn: cn=schema,cn=config
	objectClass: olcSchemaConfig
	cn: schema

	dn: cn=test,cn=schema,cn=config
	objectClass: olcSchemaConfig
	cn: test
	olcAttributeTypes: (....)

#### Backend 相关指令

Backend 指令适用所有类型的 database instances (包括mdb,bdb 等). 可以被数据库指令重载. entries objectClass 必须是 olcBackendConfig.

* olcBackend: <type>.  backend 类型可以是 bdb (伯克利 db), config ( 传统的 slapd 配置文件, slapd.conf), dnssrv, hdb, ldap, ldif, meta,
  monitor, passwd, perl shell, sql, meta. 由于没有为各种类型定义额外的指令,所以实际上很少出现这个 entry.

#### 数据库特定指令

objectClass 必须是 olcDatabaseConfig.  LDAP 可以指定多个数据库, 每个数据库使用不同的配置.

* olcDatabase: 本指令设置数据库实例, 可以通过序号区分多个同类型的数据库. 数据库类型可以上 olcBackend 列出的类型.
* olcAccess: 本指令授权对 entries 或者属性的访问权限,默认是 to * by * read. 默认允许所有用户(包括认证和匿名)读权限.
* olcReadonly: 设置数据库为只读
* `olcRootDN`: 本指令设置管理 DN, 该 DN 对本数据库访问时不受访问控制限制. 这个 DN 对应的 entry 可以不存在. 也可以是 SASL identity.
* `olcRootPW`: rootDN 的密码, 可以使用纯文本或者 SHA 哈希.  哈希密码可以使用 `slappasswd -s secret` 生成.
* olcSizeLimit: 设置搜索操作返回的 entries 的最大数目.
* olcSuffix: 设置传给当前 backend 数据库的查询的 DN 后缀, 也就是当前数据库的 DN 后缀, 也就是说如果查询 DN 的后缀和 olcSuffix 匹配,
  则由当前 backend 处理.可以指定多个后缀, 通过每个数据库定义至少配置一个后缀.

		olcSuffix: "dc=example,dc=com"
		// queries with a DN ending in "dc=example,dc=com" will be passed to this backend.

* olcSyncrepl: 指定副本信息
* oldTimeLimit: slapd 响应搜索请求的最大时间,如果不能再限制时间内返回结果,则返回超时.

例子:

	dn: olcDatabase=frontend,cn=config
    objectClass: olcDatabaseConfig
    objectClass: olcFrontendConfig
    olcDatabase: frontend
    olcReadOnly: FALSE

    dn: olcDatabase=config,cn=config
    objectClass: olcDatabaseConfig
    olcDatabase: config
    olcRootDN: cn=Manager,dc=example,dc=com

#### bdb/hdb 特定指令

详细列表参加文档

	dn: olcDatabase=hdb,cn=config
    objectClass: olcDatabaseConfig
    objectClass: olcHdbConfig
    olcDatabase: hdb
    olcSuffix: "dc=example,dc=com"
    olcDbDirectory: /usr/local/var/openldap-data
    olcDbCacheSize: 1000
    olcDbCheckpoint: 1024 10
    olcDbConfig: set_cachesize 0 10485760 0
    olcDbConfig: set_lg_bsize 2097152
    olcDbConfig: set_lg_dir /var/tmp/bdb-log
    olcDbConfig: set_flags DB_LOG_AUTOREMOVE
    olcDbIDLcacheSize: 3000
    olcDbIndex: objectClass eq

### 配置例子

下面例子定义了两个数据库,分别处理不同的 X.500 子树, 两个都是 BDB 数据库实例.

    # global configuration entry
    dn: cn=config
    objectClass: olcGlobal
    cn: config

	# internal schema, 定义 schema 子树的根,entry 内部的实际内容硬编码到了 slapd 中,所以这里不需要列出.
	dn: cn=schema,cn=config
	objectClass: olcSchemaConfig
	cn: schema

	# include the core schema
	include: file://usr/local/etc/openldap/schema/core.ldif

	# 下面定义数据,第一个数据库是 frontend 数据库,它的指令应用到所有其他数据库
	# 全局数据库参数, olcAccess 应用到所有的 entries (在数据库自己的访问控制应用之后)
	dn: olcDatabase=frontend,cn=config
	objectClass: olcDatabaseConfig
	olcDatabase: frontend
	olcAccess: to * by * read

	# 定义 config backend, 设置可以访问 config 数据库的 rootpw, 防止其他用户访问 (默认设置)
	# 定义了超级用户的密码,超级用户默认是 cn=config.
	dn: olcDatabase=config,cn=config
	objectClass: olcDatabaseConfig
	olcDatabase: config
	olcRootPW: {SSHA}XKYnrjvGT3wZFQrDD5040US592LxsdLy
	olcAccess: to * by * none

	# 定义 BDB backend, 以处理 "dc=example,dc=com" 子树, 并且定义了索引和对 userPassword 属性的保护;
	# 定义了超级用户 entry 及其密码, 这个 entry 不受访问控制限制和超时限制.
	# 定义了对 userPassword 属性的保护:只有 entry 自己和 admin entry 可以访问. 可用于认证,但是不允许读.
	# 其他属性可被自己和 admin 写,其他用户可读(不管认证与否)
	dn: olcDatabase=bdb,cn=config
	objectClass: olcDatabaseConfig
	objectClass: olcBdbConfig
	olcDatabase: bdb
	olcSuffix: dc=example,dc=com
	olcDbDirectory: /usr/local/var/openldap-data
	olcRootDN: cn=Manager,dc=example,dc=com
	olcRootPW: secret
	olcDbIndex: uid pres,eq
	olcDbIndex: cn,sn pres,eq,approx,sub
	olcDbIndex: objectClass eq
	olcAccess: to attrs=userPassword
		by self write
		by anonymous auth
		by dn.base="cn=Admin,dc=example,dc=com" write
		by * none
	olcAccess: to *
		by self write
		by dn.base="cn=Admin,dc=example,dc=com" write
		by * read

	# 下面 BDB 定义了 dc=example,dc=net 子树
	db: olcDatabase=bdb,cn=config
	objectClass: olcDatabaseConfig
	objectClass: olcBdbConfig
	olcDatabase: bdb
	olcSuffix: "dc=example,dc=net"
	olcDbDirectory: /usr/local/var/openldap-data-net
	olcRootDN: "cn=Manager,dc=example,dc=com"
	olcDbIndex: objectClass eq
	olcAccess: to * by users read

默认 slapd 中总是有 config backend, 然后默认只能  rootDN 才能访问, 并且没有默认 credentials, 所以除非配置正确,否则不可用.

### 转换 slapd.conf 为 cn=config 格式

默认 slapd 中总是有 config backend, 然后默认只能  rootDN 才能访问, 并且没有默认 credentials, 所以除非配置正确,否则不可用.

所以将下面内容加入到的 slapd.conf:

 	database config
 	rootpw VerySecret

转换 slapd.conf 为 cn=config

 	$ slaptest -f /usr/local/etc/openldap/slapd.conf -F /usr/local/etc/openldap/slapd.d

然后可以使用默认的 rootdn 和上面配置的 rootpw 访问 cn=config 子树.

 	$ ldapsearch -x -D cn=config -w VerySecret -b cn=config


## 运行 slapd

### slapd 服务器启动参数

建议直接运行 slapd, 而不要通过 inetd 启动. slapd 支持多个选项.

* -f <filename> : 指定 slapd.conf, 默认是 /usr/local/etc/openldap/slapd.conf
* -F <slapd-config-directory>: 指定 slapd 配置目录, 默认是 /usr/local/etc/openldap/slapd.d, 为 cn=config 配置方式所用. 如果 -f
  和 -F 同时指定,则 slapd 自动转换 slapd.conf 配置文件为配置目录格式. 如果没有指定,则 slapd 优先读取默认配置路径, 如果不存在,则读取默认
  配置文件. 如果合法的配置目录存在,则配置文件被忽略.
* -h <URLs>: 指定监听配置, 默认是 ldap:/// 即 TCP 监听所有 nic 的389端口. 可以指定主机端口对,或者其他协议(例如 ldaps:// 或者 ldapi://).
  例如 -h "ldaps:// ldap://127.0.0.1:666" 会创建2个监听,一个是636端口上的 ldaps://, 一个是本地主机666端口标准的 ldap schema.
  * ldap:///, LDAP, TCP port 389
  * ldaps:///, LDAP over SSL, TCP port 636
  * ldapi:///, LDAP, IPC (Unix-domain socket)
* -l <syslog-local-user> 指定 syslog 的 local user, 可以是  LOCAL0, LOCAL1, ..., LOCAL7. 默认是 LOCAL4.
* -d <level> | ?: 设置 slapd debug 级别, '?' 将显示所有的 debug 级别. 'any' 激活所有调试信息, 'conns' 启用连接管理调试信息.

### 启动和关闭 slapd

	$ /usr/local/libexec/slapd [options]

关闭 slapd

	$ kill -INT `cat /usr/local/var/slapd.pid`

## 访问控制

有两种访问控制配置方式,一种是slapd 配置文件,一种是 slapd-config.

默认的访问策略是允许所有 client 读; 不管设置何种控制策略, rootdn 总是拥有全部权限,例如 auth, search, compare, read 和 write. 参考 slapd.access(5)

access control directive:

	<access directive> ::= access to <what>
		[by <who> [<access>] [<control>] ]+

	<what> ::= * |
    	[dn[.<basic-style>]=<regex> | dn.<scope-style>=<DN>]
    	[filter=<ldapfilter>] [attrs=<attrlist>]
    <basic-style> ::= regex | exact
    <scope-style> ::= base | one | subtree | children
    <attrlist> ::= <attr> [val[.<basic-style>]=<regex>] | <attr> , <attrlist>
    <attr> ::= <attrname> | entry | children
    <who> ::= * | [anonymous | users | self
    		| dn[.<basic-style>]=<regex> | dn.<scope-style>=<DN>]
    	[dnattr=<attrname>]
    	[group[/<objectclass>[/<attrname>][.<basic-style>]]=<regex>]
    	[peername[.<basic-style>]=<regex>]
    	[sockname[.<basic-style>]=<regex>]
    	[domain[.<basic-style>]=<regex>]
    	[sockurl[.<basic-style>]=<regex>]
    	[set=<setspec>]
    	[aci=<attrname>]
    <access> ::= [self]{<level>|<priv>}
    <level> ::= none | disclose | auth | compare | search | read | write | manage
    <priv> ::= {=|+|-}{m|w|r|s|c|x|d|0}+
    <control> ::= [stop | continue | break]

	<what> 部分是访问控制的 entries 和/或属性, <who> 部分表示赋予谁权限, <access> 表示授予的具体权限.

访问控制指令的顺序很重要,越具体的指令放在前面.

### 权限级别

	none, disclose, auth, compare, search, read, write, manage

### 访问控制例子

	// 授权所有人读权限
	access to * by * read

	// 用户可以修改自己的 entry, 匿名用户可以进行认证操作, 所有其他用户可以读这些 entries (不包括匿名用户)
	// 注意只会应用第一个匹配 by <who> 的指令, 一旦匹配就不会再匹配后续的指令. 因为匿名用户具有 auth 权限,而没有 read 权限
	// 最后一行等同于 by users read.
	access to *
		by self write
		by anonymous auth
		by * read

	// 除了 dc=example,dc=com 子树, 授权 read 权限给 dc=com 子树.
	// dc=example,dc=com 子树授权 search 权限.
	access to dn.children="dc=example,dc=com"
		by * search
	access to dn.children="dc=com"
		by * read

	// 注意 access to 指令如果没有 by <who> 或者匹配不成功,则意味着 by * none, 及 access to 的最后一个子句是 by * none.

## 创建数据库

有两种方式创建数据. 一种是使用 ldap 在线创建数据库, 第二种方式使用 slapd 提供的工具一次性创建.

### 使用 LDAP 创建数据库

使用 ldap client 工具(例如 ldapadd) 添加 entries.

确保在启动 slapd 前配置文件中包含 suffix <dn>.  这个指令告诉 slapd 数据库中
保存什么样的 entries. 一般是要创建的子树的 root 的 DN, 例如 suffix "dc=example,dc=com"

确保指定了 directory <directory> 以保存索引文件.

确保添加第一个用户(超级用户)对该子树进行管理, 通常做法是指定 rootdn 和 rootpw. 例如:

	rootdn "cn=Manager,dc=example,dc=com"
    rootpw secret

指定期望的索引,例如为 cn,sn,uid 属性创建 presence, equality, approximate, substring 索引, objectClass 创建相等性索引.:

    index cn,sn,uid pres,eq,approx,sub
    index objectClass eq

### 离线创建数据库

首先保证配置文件正确.

首先设置数据库保存的子树信息:

	suffix "dc=example,dc=com"

其次设置索引数据目录,例如:

	directory /usr/local/var/openldap-data

设置期望的索引:

	index cn,sn,uid pres,eq,approx,sub
    index objectClass eq

设置好数据库的基本属性后,可以使用 slapadd 创建数据库和索引.

 	$ slapadd -l <inputfile> -f <slapdconfigfile> [-d <debuglevel>] [-n <integer> | -b <suffix>]

	// inputfile: 包含 entries 的 LDIF 文件
	// slapdconfigfile: slapd 配置文件, 其中会设定创建什么样的索引,保存在什么地方等.
	// -F <slapdconfdirectory: 指定配置目录
	// debuglevel: 调试级别
	// -n databasenumber: 修改配置文件中那个数据库, 序号依次是1, 2, ... 默认修改第一个数据库,不能喝 -b 连用
	// -b suffix: 修改那个数据库, 匹配数据库的 suffix.

slapindex 用户创建索引.

slapcat 可以 dump 数据库到 ldif 文件.

	$ slapcat -l filename -f slapdconfigfile ...

### LDIF 文件格式

	# comment
	dn: <distinguished name>
	<attrdesc>: <attrvalue>
	<attrdesc>: <attrvalue>


一个例子:

	# Barbara's Entry
    dn: cn=Barbara J Jensen,dc=example,dc=com
    cn: Barbara J Jensen
    cn: Babs Jensen
    objectClass: person
    sn: Jensen

    # Bjorn's Entry
    dn: cn=Bjorn J Jensen,dc=example,dc=com
    cn: Bjorn J Jensen
    cn: Bjorn Jensen
    objectClass: person
    sn: Jensen
    # Base64 encoded JPEG photo
    jpegPhoto:: /9j/4AAQSkZJRgABAAAAAQABAAD/2wBDABALD
     A4MChAODQ4SERATGCgaGBYWGDEjJR0oOjM9PDkzODdASFxOQ
     ERXRTc4UG1RV19iZ2hnPk1xeXBkeFxlZ2P/2wBDARESEhgVG

    # Jennifer's Entry
    dn: cn=Jennifer J Jensen,dc=example,dc=com
    cn: Jennifer J Jensen
    cn: Jennifer Jensen
    objectClass: person
    sn: Jensen
    # JPEG photo from file
    jpegPhoto:< file:///path/to/file.jpeg

## Backends

Backend 响应 LDAP 请求执行实际的数据存储和查询任务. backend 可以编译到 slapd 中,或者使用动态模块加载.

### HDB/BDB backend

hdb backend to slapd is a backend for a normal slapd database. 它使用 BDB 保存数据,大量使用索引和缓存以提高性能.

hdb 是 bdb backend 的一个变种,它使用一种树形数据库布局,以支持 subtree 重命名.

### LDAP backend

实际起 proxy 作用

### LDIF backend

LDIF backend 使用 LDIF 文件保存 entires, 使用文件系统树形结构表示 entries 的树形结构. cn=config 动态配置数据库使用的存储是
这种 backend, 详见 slapd-config.

这也是为什么使用 rpm 安装后, slapd.d 中有很多配置信息的原因.  配置数据库使用 LDIF backend.

LDAP 中 backend 和 database 是分离的,不同的数据库可以使用不同的 backend.

### LMDB

普通 slapd 数据库建议使用 mdb backend, 它使用 OpenLDAP 自己的 lightning memory-mapped database 保存数据, 将来会替换掉 BDB backend.
mdb 支持索引,但是不需要使用 cache; 和 hdb 一样,支持子树重命名.

mdb backend 配置例子:

	include ./schema/core.schema

    database mdb
    directory ./mdb
    suffix "dc=suretecsystems,dc=com"
    rootdn "cn=mdb,dc=suretecsystems,dc=com"
    rootpw mdb
    maxsize 1073741824

## Overlay

## Schame 规范

本节描述如何扩展用户自定 schema.

### 系统 schema

ldap 自带了一些 schema, 要使用这些 schema, 将他们加入到 slapd.conf 中.

	# include schema
    include /usr/local/etc/openldap/schema/core.schema
    include /usr/local/etc/openldap/schema/cosine.schema
    include /usr/local/etc/openldap/schema/inetorgperson.schema

### 扩展 schema


## 安全考虑

### 网络安全

#### 选择性监听

	$ slapd -h ldap://127.0.0.1

### 数据一致性

### 认证方法

#### simple 方法

LDAP 的 simple 认证方法支持三种操作模式:

* 匿名: 不带用户名和密码的 simple bind 操作, 匿名 bind 使用 anonymous 权限组.
* 未认证: 只带名字,没有密码的 bind 操作, 这种认证也会使用 anonymous 权限组. 默认是 disabled 的.
* 用户名/密码认证: 提供了正确的名字和密码.

#### SASL 方法

这种方法支持 SASL 认证机制.

### Password storage

LDAP 用户(entry) 的密码通常保存在 userPassword 属性中. LDAP 支持多种 storage schema.

userPassword 属性可以有多个值, 每个值可以使用不同的存储形式. ldap 认证时会遍历每一个.

* SSHA 密码存储格式
* CRYPT 密码存储格式
* md5 密码存储格式
* SHA 密码存储格式


## SASL

OpenLDAP 支持 SASL 框架,常见的 SASL 实现由 GSSAPI for Kerberos V, DIGEST-MD5, Plain/External with TLS.

标准的 client 工具(例如 ldapsearch, ldapmodify) 默认试图使用 SASL 认证.

## TLS

RHEL7 的 OpenLDAP 不在使用 OpenSSL, 而是使用 Mozilla NSS.

RHEL7 OpenLDAP 要使用 TLS, 至少需要配置:

* 服务器
  * 配置 CA 证书
  * OpenLDAP 服务器证书
  * OpenLDAP 服务器密钥
* 客户端
  * 配置可信 CA 证书列表

### 如果使用 Mozilla NSS 作为 TLS/SSL 实现, 生成服务器证书

要使用 Mozilla 证书/密钥数据库, 需要在 CA 证书目录指令中指定目录路径. 例如客户端在 ldap.conf 或者 .ldaprc 中使用 TLS_CACERTDIR 指向
/path/to/cert/key/db, 服务器在 slapd.conf 中,使用 TLSCACertificatePath 指向正确的路径. 如果服务器使用 cn=config 配置方式,则使用
olcTLSCACertificatePath 属性.

如果路径同时包含 OpenSSL 格式的 CA 证书哈希符号链接和 NSS 证书/密钥数据库, OpenLDAP 会使用 NSS 证书/密钥数据库而忽略 OpenSSL 的 CA 文件.

若要使用证书/密钥数据库中的某个具体的证书,则使用证书文件指令设置证书名字:

* ldap.conf 或者 .ldaprc: TLS_CERT
* slapd.conf: TLSCertificateFile
* cn=config: olcTLSCertificateFile

如果证书的 token 不是 NSS 内建的 token, 则 token 名字后跟冒号(:),然后是证书名字:

	TLS_CERT my token name:My Cert Name

keyfile 指令( TLS_KEY )设置包含 key 的 password/pin 的文件名. 可以使用 modutil 或者 certutil 去掉 key 数据库的密码保护.

RHEL7 默认密钥/证书数据库目录是 /etc/openldap/certs

#### NSS 数据库类型

	[root@ldapserver certs]# pwd
    /etc/openldap/certs
    [root@ldapserver certs]# tree .
    .
    |-- cert8.db
    |-- key3.db
    |-- password
    `-- secmod.db

    [root@ldapserver certs]# file cert8.db
    cert8.db: Berkeley DB 1.85 (Hash, version 2, native byte-order)

NSS 支持两种类型的数据库, 一种是legacy 的安全数据库(cert8.db, key3.db, secmod.db), 和新的 SQLite 数据库( cert8.db, key4.db, pkcs11.txt).
如果没有使用前缀 sql:, 则使用老的格式, 否则使用新的格式.

NSS 最初使用 BDB 数据库存储安全信息. BDB 性能不够好. 它包括下面数据库文件

* cert8.db 存储证书
* key3.db 存储密钥
* secmod.db 存储 PKCS#11 模块信息

从 2009 年, NSS 引入了了 SQLite 数据库, 它提供了更好的访问性和性能. SQLite 可以共享, 有限建议使用这种类型. RHEL7 默认带的是老的类型.

* cert9.db 存储证书
* key4.db 存储密钥
* pkcs11.txt 包含 PKCS #11 模块.

各种工具( certutil, pk12util, modutil) 默认使用老的 bdb 数据库类型, 如果使用 sqlite 数据库,则数据库目录需要带有 sql: 前缀, 例如:

	# pk12util -i /tmp/cert-files/users.p12 -d sql:/home/my/sharednssdb

参考:

* http://firstyear.id.au/blog/html/2014/07/10/NSS-OpenSSL_Command_How_to:_The_complete_list..html
* https://www.dragonsreach.it/2013/03/27/setting-ssl-certificates-openldap-mozilla-nss-database/


#### 管理密钥/证书数据库

NSS 提供了管理证书/密钥数据库的工具,常用的有 certutil, pk12util, modutil

* 列出证书/密钥数据库中的所有证书: `certutil -d /path/to/certdb -L`
* 列出证书的详细信息: `certutil -d /path/to/certdb -L "name of cert"`
* 导出证书到 PEM: `certutil -d /path/to/certdb -L "name of cert" -a > /path/to/filename.pem`
* Add a CA certificate for a TLS/SSL issuer CA from a PEM (ASCII) file: `certutil -d /path/to/certdb -A -n "name of CA cert" -t CT,, -a -i /path/to/cacert.pem
`
* 从 PKCS12 文件中加入证书和私钥: `pk12util -d /path/to/certdb -i /path/to/file.p12`

显示RHEL7 yum 安装 OpenLDAP 后,系统自带的证书/密钥数据库中的证书信息:


	// 显示证书
	[root@ldapserver certs]# certutil -d `pwd` -L

    Certificate Nickname                                         Trust Attributes
                                                                 SSL,S/MIME,JAR/XPI

    OpenLDAP Server                                              CTu,u,u

    // 显示名字为 "OpenLDAP Server" 的证书的详细信息. 在 RHEL7 上如果同时有密码/证书数据库
    // 和 OpenSSL 证书,则优先使用数据库中的证书, 因而经常出现 CN 不匹配的错误信息.
    [root@ldapserver certs]# certutil -d `pwd` -L -n 'OpenLDAP Server'
    Certificate:
        Data:
            Version: 3 (0x2)
            Serial Number:
                00:a7:20:82:17
            Signature Algorithm: PKCS #1 SHA-256 With RSA Encryption
            Issuer: "CN=1b8d8e1ae166"
            Validity:
                Not Before: Mon Aug 01 15:15:07 2016
                Not After : Tue Aug 01 15:15:07 2017
            Subject: "CN=1b8d8e1ae166"
            Subject Public Key Info:
                Public Key Algorithm: PKCS #1 RSA Encryption
                RSA Public Key:
                    Modulus:
                        a7:28:18:4e:24:af:87:86:c8:21:31:51:90:8c:80:c2:
                        a4:db:29:98:5b:ef:dc:71:5f:c1:90:36:b7:a7:9f:7f:
                        20:03:fb:d8:9d:58:94:02:c4:80:a1:74:a8:4f:1e:c4:
                        60:f8:0c:1a:b9:e8:81:13:69:1f:20:40:8e:ad:b4:fd:
                        9e:31:87:0a:af:75:56:5d:53:6c:db:6e:5f:e6:21:60:
                        81:79:50:9d:6a:67:4c:85:fa:03:fc:b9:34:91:d9:87:
                        a1:93:d5:01:2d:2e:57:b9:52:0b:59:da:1b:62:73:3f:
                        72:2a:53:53:78:04:33:26:5b:19:02:10:96:62:8f:8f
                    Exponent: 65537 (0x10001)
            Signed Extensions:
                Name: Certificate Subject Alt Name
                DNS name: "1b8d8e1ae166"
                DNS name: "localhost"
                DNS name: "localhost.localdomain"

        Signature Algorithm: PKCS #1 SHA-256 With RSA Encryption
        Signature:
            3b:3c:d6:79:35:3d:e3:ed:f7:64:03:57:f1:cd:29:e6:
            af:7a:3b:6d:4b:71:22:c9:33:fb:68:db:84:7a:ac:0a:
            20:36:3f:aa:95:19:4f:fb:7c:c5:f3:ef:af:6a:ea:08:
            1e:de:e2:84:5d:55:2a:5c:99:b5:dd:2a:01:8b:ab:b8:
            fe:6d:09:1d:c3:15:aa:7a:e5:5a:19:c0:87:d7:dc:39:
            39:94:63:7b:8a:8d:65:84:37:59:78:84:39:60:a5:53:
            23:6a:04:de:24:b5:93:8a:d9:ba:35:d7:19:3f:f8:34:
            b8:68:bf:2b:56:c2:2d:34:1d:09:a8:4a:b7:6c:d6:46
        Fingerprint (SHA-256):
            B9:35:DC:82:E0:FC:ED:2F:15:EC:53:17:08:24:25:66:2A:10:2C:DA:50:E3:1A:9F:C7:B0:27:47:52:0C:71:B5
        Fingerprint (SHA1):
            B2:27:A0:2C:87:75:89:A4:96:8F:1A:8F:9D:F9:4C:92:D7:83:72:C1

        Certificate Trust Flags:
            SSL Flags:
                Valid CA
                Trusted CA
                User
                Trusted Client CA
            Email Flags:
                User
            Object Signing Flags:
                User

#### 添加证书到数据库中

可以使用 "关于如何使用 OpenSSL 生成服务器证书" 小结,使用 OpenSSL 生成证书.

	certutil -d sql:/home/nssdb/sharednssdb/ -A -n "CA_certificate" -t CT,, -a -i certificate.pem

上面命令将证书 certificate.pem 加入到数据库中, -d 选项指定包含证书数据库文件和密钥数据库文件的目录, 'sql:' 是 NSS 的新数据格式,使用 SQLite,
老的数据库使用 bdb. -n 设置证书的名字, -t CT,, 表示证书是可信的,并可以用于 TLS 客户和服务器. -a 选项支持 ASCII 格式输入和输出.

### 关于如何使用 OpenSSL 生成服务器证书

参见 http://www.openldap.org/faq/data/cache/185.html

Transport Layer Security (TLS) 是 Secure Socket Layer (SSL) 的标准名字. 两个名字通常可以互换使用.

* `StartTLS` 是标准的 LDAP 操作名字,该操作会启动 TLS/SSL. StartTLS 操作成功后, TLS/SSL 就初始化成功了. 不需要额外的端口 (ldaps:// 使用636),
使用 StartTLS 不在需要该端口, 通常 ldap:// + StartTLS 使用 389 端口. 该操作也称为 TLS upgrade, 因为它将普通的 LDAP 连接升级为 TLS/SSL 保护的连接.
* `ldaps://` 指 LDAP over TLS/SSL, 或者 LDAP Secured. 它使用单独的端口(通常是636)建立 TLS/SSL 连接.

一旦初始化后, ldaps:// 和 StartTLS 之间没有区别. 他们使用相同的配置.

`从 OpenLDAP 2.1 开始, 客户端库会验证服务器证书, 这要求客户端在系统配置文件 ldap.conf 中设置正确的 TLS_CACERT 或者 TLS_CACERTDIR.
否则 LDAP 客户端不能建立 TLS/SSL 连接.

#### 获取 CA 证书

可以购买商业 CA 证书,或者创建自签名的 CA 证书.

创建一个 CA 证书. 注意 Common Name 要和 OpenLDAP 服务器的全名一样. CA.pl 默认将创建新目录 /etc/pki/CA, 并将新生成的所有 CA 相关文件
放到该目录中.

	# mkdir -p /var/myca
	# cd /var/myca

	# find /etc/pki/CA/
	/etc/pki/CA/
    /etc/pki/CA/newcerts
    /etc/pki/CA/crl
    /etc/pki/CA/private
    /etc/pki/CA/certs


	# /etc/pki/tls/misc/CA.pl -newca
    CA certificate filename (or enter to create)

    Making CA certificate ...
    Generating a 2048 bit RSA private key
    .+++
    .......................................+++
    writing new private key to '/etc/pki/CA/private/cakey.pem'
    Enter PEM pass phrase:
    Verifying - Enter PEM pass phrase:
    -----
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Country Name (2 letter code) [XX]:CN
    State or Province Name (full name) []:Beijing
    Locality Name (eg, city) [Default City]:Beijing
    Organization Name (eg, company) [Default Company Ltd]:Pivotal
    Organizational Unit Name (eg, section) []:CA
    Common Name (eg, your name or your server's hostname) []:caserver
    Email Address []:caserver@pivotal.io

    Please enter the following 'extra' attributes
    to be sent with your certificate request
    A challenge password []:
    An optional company name []:
    Using configuration from /etc/pki/tls/openssl.cnf
    Enter pass phrase for /etc/pki/CA/private/cakey.pem:
    Check that the request matches the signature
    Signature ok
    Certificate Details:
            Serial Number: 15659552188909725529 (0xd951e7bf79a7a759)
            Validity
                Not Before: Aug  2 14:52:22 2016 GMT
                Not After : Aug  2 14:52:22 2019 GMT
            Subject:
                countryName               = CN
                stateOrProvinceName       = Beijing
                organizationName          = Pivotal
                organizationalUnitName    = CA
                commonName                = caserver
                emailAddress              = caserver@pivotal.io
            X509v3 extensions:
                X509v3 Subject Key Identifier:
                    F5:CD:2F:0D:74:A7:F4:1E:0C:DC:B3:D3:36:95:96:FE:EB:E1:CF:44
                X509v3 Authority Key Identifier:
                    keyid:F5:CD:2F:0D:74:A7:F4:1E:0C:DC:B3:D3:36:95:96:FE:EB:E1:CF:44

                X509v3 Basic Constraints:
                    CA:TRUE
    Certificate is to be certified until Aug  2 14:52:22 2019 GMT (1095 days)

    Write out database with 1 new entries
    Data Base Updated

现在你有了自己的 CA, 可以为你的服务器创建数字证书了.

	[root@ldapserer CA]#  find /etc/pki/CA/
    /etc/pki/CA/
    /etc/pki/CA/newcerts
    /etc/pki/CA/newcerts/A60B9BE9F6571FC0.pem			// 新文件
    /etc/pki/CA/crlnumber								// 新文件
    /etc/pki/CA/careq.pem								// 新文件
    /etc/pki/CA/cacert.pem								// 新文件
    /etc/pki/CA/index.txt.attr							// 新文件
    /etc/pki/CA/private
    /etc/pki/CA/private/cakey.pem						// 新文件
    /etc/pki/CA/index.txt.old							// 新文件
    /etc/pki/CA/serial									// 新文件
    /etc/pki/CA/index.txt								// 新文件
    /etc/pki/CA/crl
    /etc/pki/CA/certs

为OpenLDAP服务器创建创建一个 cert 请求和私钥. -nodes 防止对私钥进行加密. OpenLDAP 只能识别未加密的私钥.

	# openssl req -new -nodes -keyout newreq.pem -out newreq.pem
    Generating a 2048 bit RSA private key
    ................................................................................+++
    .....+++
    writing new private key to 'newreq.pem'
    -----
    You are about to be asked to enter information that will be incorporated
    into your certificate request.
    What you are about to enter is what is called a Distinguished Name or a DN.
    There are quite a few fields but you can leave some blank
    For some fields there will be a default value,
    If you enter '.', the field will be left blank.
    -----
    Country Name (2 letter code) [XX]:CN
    State or Province Name (full name) []:Beijing
    Locality Name (eg, city) [Default City]:Beijing
    Organization Name (eg, company) [Default Company Ltd]:Pivotal
    Organizational Unit Name (eg, section) []:Data
    Common Name (eg, your name or your server's hostname) []:ldapserver
    Email Address []:yyao@pivotal.io

    Please enter the following 'extra' attributes
    to be sent with your certificate request
    A challenge password []:
    An optional company name []:

然后使用 CA 对这个 cert 请求进行签名:

	[root@c6f9bbb8ed04 myca]# /etc/pki/tls/misc/CA.pl -sign
    Using configuration from /etc/pki/tls/openssl.cnf
    Enter pass phrase for /etc/pki/CA/private/cakey.pem:
    Check that the request matches the signature
    Signature ok
    Certificate Details:
            Serial Number: 11374809427514836060 (0x9ddb70e872c9445c)
            Validity
                Not Before: Aug  1 13:48:35 2016 GMT
                Not After : Aug  1 13:48:35 2017 GMT
            Subject:
                countryName               = CN
                stateOrProvinceName       = Beijing
                localityName              = Beijing
                organizationName          = Pivotal
                organizationalUnitName    = Data
                commonName                = ldapserver
                emailAddress              = yyao@pivotal.io
            X509v3 extensions:
                X509v3 Basic Constraints:
                    CA:FALSE
                Netscape Comment:
                    OpenSSL Generated Certificate
                X509v3 Subject Key Identifier:
                    47:CF:6F:69:7F:12:4C:D9:C3:3E:57:1B:66:1F:82:F4:BA:97:A0:F5
                X509v3 Authority Key Identifier:
                    keyid:CB:32:C9:B0:BA:70:4D:86:42:E0:AD:DD:37:16:CA:13:F6:40:ED:F0

    Certificate is to be certified until Aug  1 13:48:35 2017 GMT (365 days)
    Sign the certificate? [y/n]:y


    1 out of 1 certificate requests certified, commit? [y/n]y
    Write out database with 1 new entries
    Data Base Updated
    Signed certificate is in newcert.pem

至此,有了 OpenLDAP 需要的 CA 和证书:

* /etc/pki/CA/cacert.pem: 自己的 CA 证书
* newcet.pem: ldap 服务器的证书,
* newreq.pem: ldap 服务器证书的密钥,  这个权限需要是 600.

Refer to http://www.openldap.org/faq/data/cache/185.html for more info.

### TLS 证书

TLS 使用 X.509 证书携带 client 和 server 身份信息. 所有服务器都需要合法的证书, client 的证书是可选的. 若要使用 SASL external 认证,则
client 必须有合法的证书.

#### 服务器证书

服务器证书的 DN ( X.509 证书也有 DN, 509 是 X.500 的一部分,所以命名方式和思路相似) 必须使用 CN 属性来命名服务器,而且 CN 必须是服务器的 FQDN 名字. 此外 subjectAltName 可以包含别名和通配符.

#### client 证书

client 证书的 DN 可以直接作为认证 DN, 由于 X.509 是 X.500 的一部分,而 LDAP 是基于 X.500 的,所以两者使用相同的 DN 格式.  通常一个
用户的 X.509 证书的 DN 和 LDAP 中它的 entry 的 DN 是相同的. 然后有些可能不同,所以需要使用 mapping 机制.

### TLS 配置

生成了证书后,需要对 client 和 server 进行配置,以使用这些证书. client 必须指定包含所有可信 CA (Certification Authority) 证书的文件 (client must be configured with
the name of the file containing all of the CA certificates it will trust).  服务器必须指定可信 CA 证书,以及他自己的服务器证书和私钥.

通常某一个 CA 会发布服务器证书和所有可信的客户端证书, 所以服务器只需要信任该 CA; 然而客户端需要连接到多个不同服务器, 而每个服务器的证书可能由不同的
CA 颁布,所以客户端需要配置文件中指定信任的 CA 列表.

#### 服务器配置

* olcTLSCACertificateFile <filename>: 指定包含了 slapd 信任的 CA 的证书的文件,文件格式是 PEM 格式. 其中必须包括为服务器证书签名的 CA 的证书.
  如果为服务器签名的 CA 不是 root CA, 则从签名 CA 到 root CA 的证书都必须包含在该文件中. 多个证书直接添加到文件末尾, 证书顺序不重要.

  如果是 Mozilla NSS, 则使用证书名字.
*  olcTLSCACertificatePath <path>: 指定包含证书的目录, 每个证书都是一个单独的文件. 这个目录必须有 OpenSSL 由 c_rehash 管理.
  使用 TLSCACertificateFile 更简单.

  如果使用了 Mozilla NSS, 则 olcTLSCACertificatePath 可以指向 Mozilla NSS 数据库.  这种情况下不需要 c_rehash. RHEL7 使用的是 Mozilla NSS.

  `certutil` 命令可以将 CA 证书加入到 NSS 数据库中.


* olcTLSCertificateFile <filename>: slapd 服务器证书文件. 证书是公开信息,不需要额外保护.

  如果使用 Mozilla NSS, 则使用证书名字. 需要使用 certutil 将服务器证书加入到证书数据库中, 然后使用这个命令指定证书的名字.

* TLSCertificateKeyFile <filename>: slapd 服务器证书的私钥,必须匹配 TLSCertificateFile 中的证书.
  TLSCertificateKeyFile 指向的文件包含 olcTLSCertificateFile 对应的证书文件的私钥. 当前实现不支持加密的私钥,所以这个文件必须保护好.

  如果使用 Mozilla NSS, olcTLSCertificateKeyFile 是包含证书私钥的密码的文件.

  modutil 命令可以关闭密码保护, 或者修改 NSS 数据库文件的密码.

* TLSCipherSuite <cipher-suite-spec>: 指定可用的 cipthers 及优先级. `openssl ciphers -v ALL` 可以列出所有 cipher. 此外还可以使用 HIGH,
  MEDIUM, LOW, EXPORT, EXPORT40.
* TLSRandFile <filename>: 设置获取随机数的文件, 默认使用 /dev/urandom.
* TLSEphemeralDHParamFile <filename>: 如果服务器使用 DSA 证书 (TLSCertificateKeyFile 是 DSA key), 则需要这个参数.
* TLSVerifyClient {never|allow|try|demand}: 是否验证 client 证书,默认是 never, 服务器不验证 client 的证书.

#### 客户端配置

大多数客户端配置和服务器配置相似, 指令名字可能不同, 此外客户端配置保存在 ldap.conf 文件中,而服务器配置保存在 slapd.conf 文件中. 用户自定义
信息可以使用 .ldaprc 文件.

LDAP 使用 LDAP Start TLS 操作开启 TLS 协商, 所有 OpenLDAP 命令都支持 -Z, -ZZ 命令以启用 Start TLS 操作. -ZZ 在 TLS 不能启动时会停止,
-Z 则不会停止.

在 LDAPv2 中, TLS 使用 ldaps:// 而不是标准的 ldap://.

* TLS_CACERT <filename>: 等价于服务器的 TLSCACertificateFile. 指向一个文件,其中包含了 client 能够识别的所有 CA. TLS_CACERT 应该总是
  在 TLS_CACERTDIR 之前.
* TLS_CACERTDIR <path>: 等价于服务器的 TLSCACertificatePath. 目录必须使用 c_rehash 管理.
  如果使用 Mozilla NSS, 则不需要使用 c_rehash.  而该目录指向包含证书和私钥数据库文件的目录.
* TLS_CERT <filename>: 指定客户端的证书, 这个指令只对某个用户有效,只能在 .ldaprc 中设置.
* TLS_KEY <filename>: 指定客户端证书的私钥,必须匹配 TLS_CERT. 只对单个用户有效.
* TLS_RANDFILE
* TLS_REQCERT {never|allow|try|demand}: 默认值是 demand.


## 维护

## 监控

## 调优

## 诊断

### checklist

* 启动 slapd 前使用 slaptest 验证配置
* 使用 ldapsearch 前确认 slapd 在监听端口 (通常是 389和636)
* 使用 ldapsearch
* 是否使用了复杂的 ACLs
* 是否使用 TLS
* 证书是否过期了

### 调试 slapd

slapd -d -1 通常可以发现简单的问题,譬如缺少 schema, 不正确的文件(例如证书)权限等.

#### 启用日志

在 slapd.conf 中设置合适的 loglevel:

	loglevel 64

然后在 /etc/syslogd.conf 中加入:

	*.debug /var/log/debug

这样所有 log 都会写入到 /var/log/debug 中.

需要重启 slapd 和 syslogd. 使用 slapd -l 显示所有可用的 loglevel.

slapd 自带一个称谓 slaptest 的工具, 它会检查配置文件是否有问题:

	$ slaptest -f testrun/slapd.1.conf

## 参考

* OpenSSL CA: https://jamielinux.com/docs/openssl-certificate-authority/sign-server-and-client-certificates.html




