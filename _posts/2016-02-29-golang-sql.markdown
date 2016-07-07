---
layout: post
title:  "SQL query in Golang"
subtitle:  "golang中的sql语句"
author: 姚延栋
date:   2016-02-20 14:20:43
categories: golang sql
published: true
---

## golang sql

sql package 提供 API 给client使用； driver package 提供了不同数据库的驱动接口，并为 sql package 所有。
每个数据库要有自己的 driver 实现。 也就是实现所有 driver package中的接口。

### driver package

#### Value 接口

    // Value 是 driver 必须能处理的数据类型，可以是 int64,float64,bool,[]byte,string,time.Time
    type Value interface{}

#### Driver 接口

    // 数据库驱动必须实现的接口
    type Driver interface{
        // Open 返回一个数据库连接，可能返回cached 的连接，但是没有必要，因为 sql
        // package 维护了idle 连接池。
        //
        // 返回的连接某一个时刻只能被一个 goroutine 使用。
        Open(name string) (Conn, error)
    }

#### Conn 接口

    // Conn 是一个数据库连接，不能被多个 goroutines 并发使用。
    // Conn 是有状态的。
    type Conn interface {
        // 返回一个 prepared statement，绑定到当前连接
        Prepare(query string) (Stmt, error)

        // Close
        Close() error

        // Begin 启动一个新的事务
        Begin() (Tx, error)
    }

#### Execer 接口

    // Execer 可选接口，如果没有实现，则使用sql 包中的 DB.Exec 先prepare，execute，
    // 然后 close statement
    type Execer interface {
        Exec(query string, args []Value) (Result, error)
    }

#### Queryer 接口

    可选实现接口，否则使用 DB.Query
    type Queryer interface {
        Query(query string, args []Value) (Rows, error)
    }

### Result 接口

    // Result 是执行查询的结果
    type Result interface {
        LastInsertId() (int64, error)
        RowsAffected() (int64, error)
    }

### Stmt 接口

    // Stmt is a prepared statement. It is bound to a Conn and not used by
    // multiple goroutines concurrently.
    type Stmt interface {
        Close() error

        // NumInput returns the number of placeholder parameters
        NumInput() int

        // Exec executes a query that does not return rows, such as INSERT/UPDATE
        Exec(args []Value) (Result, error)

        // Query execute a query that may return rows, such as a SELECT
        Query(args []Value) (Rows ,error)
    }

#### ColumnConverter

    type ColumnConverter interface {
        ColumnConverter(idx int) ValueConverter
    }

    type ValueConverter interface {
    	// ConvertValue converts a value to a driver Value.
    	ConvertValue(v interface{}) (Value, error)
    }

    // Valuer is the interface providing the Value method.
    //
    // Types implementing Valuer interface are able to convert
    // themselves to a driver Value.
    type Valuer interface {
    	// Value returns a driver Value.
    	Value() (Value, error)
    }

#### Rows

    // Rows is an iterator over an executed query's results.
    type Rows interface {
        // Columns returns the names of columns.
        Columns() []string

        // Close closes the rows iterator
        Close() error

        // Next is called to populate the next row of data into the povided slice.
        //
        // The dest slice maybe populated only with a driver Value type, but excluding string.
        // All string values must be converted to []byte.
        //
        // Next should return io.EOF when there is no more rows
        Next(dest []Value) error
    }

#### Tx

    type Tx interface {
        Commit() error
        Rollback() error
    }

### sql package

sql package 如何实现查询执行（主要是 Exec和Query）？

如果 driver 的 connection 实现了 driver.Queryer 或者 driver.Execer 接口，则会调用 driver 的代码，
否则使用通用的 prepare, 执行， close 的方式。

每一个 driver 的connection必须实现 Conn 接口，其中包括 Prepare, Close, Begin. 其中 Prepare 返回 Stmt 接口。
Stmt 接口必须实现 Exec 和 Query。

这样也就成了是调用 driver.Conn 的 Exec/Query 还是调用 Stmt 的 Exec/Query 的问题了。

#### 使用例子

- 使用 Query 发送查询请求给数据库，返回 Rows 结构。
- Rows 通过 Next() 获得下一个 row 的数据, 这个方法返回后，数据已经读出来了。
- 如果还有数据，则调用 rows.Scan(dest ...interface{}) 获得rows 里面的信息，也就是各个字段的实际数值。主要作用就是讲
  Next() 读出来的数据转换成期望的类型。

Next() 的是由 driver 实现的。

    age := 27
    rows, err := db.Query("SELECT name FROM users WHERE age=?", age)
    if err != nil {
            log.Fatal(err)
    }
    defer rows.Close()
    for rows.Next() {
            var name string
            if err := rows.Scan(&name); err != nil {
                    log.Fatal(err)
            }
            fmt.Printf("%s is %d\n", name, age)
    }
    if err := rows.Err(); err != nil {
            log.Fatal(err)
    }


### RawBytes

    // RawBytes is a byte slice that holds a reference to memory owned by
    // the database itself. After a Scan into a RawBytes, the slice is only
    // valid until the next call to Next, Scan, or Close.
    type RawBytes []byte

### `convertAssigned(dest, src interface{})`

执行一次拷贝操作，将原来 connection 上的数据(来自driver）拷贝到 golang 自己的新空间中。

Nullxxx 类型大量使用 `convertAssigned` 实现 Scan 接口。

### Scanner 接口


    // Scanner is an interface used by Scan.
    type Scanner interface {
        // Scan assigns a value from a database driver
        //
        // src 可以是先面受限的类型（SQL 支持的类型）
        //      int64
        //      float64
        //      bool
        //      []byte
        //      string
        //      time.Time
        //      nil - for NULL values
        //
        // An error should be returned if the value can not be stored without
        // loss of information
        Scan(src interface{}) error
    }

Rwos.Scan 的例子：

    func (rs *Rows) Scan(dest ...interface{}) error {
    	if rs.closed {
    		return errors.New("sql: Rows are closed")
    	}
    	if rs.lastcols == nil {
    		return errors.New("sql: Scan called without calling Next")
    	}
    	if len(dest) != len(rs.lastcols) {
    		return fmt.Errorf("sql: expected %d destination arguments in Scan, not %d", len(rs.lastcols), len(dest))
    	}
    	for i, sv := range rs.lastcols {
    		err := convertAssign(dest[i], sv)
    		if err != nil {
    			return fmt.Errorf("sql: Scan error on column index %d: %v", i, err)
    		}
    	}
    	return nil
    }

## pq (PostgreSQL driver)

### buffer

pq package 实现了读写buffer，可以方便的在 []byte int32, int16, string, byte, []byte 间进行转换。 相当于封装了 []byte。

1) Reader 怎么转换成 []byte?
2) `type readBuf []byte` 不涉及到slice长度，相关长度问题，怎么解决？

    每次处理数据后，通过slice操作，移动指针： *b = (*b)[4:]

3) 和 bytes.Buffer 有啥异同？


### Dialer interface

Dialer interface 负责网络连接。 并且提供了一个 defaultDialer 的结构体。 defaultDialer 直接调用 net.Dial 和 net.DialTimeout

    type Dialer interface {
        Dial(network, address string) (net.Conn, error)
        Dialtimeout(network, address string, timeout time.Duration) (net.Conn, error)
    }

一个接口，一个结构体实现该接口。  超时使用  time.Duration 而不是 int。

### pq conn 结构体

pq 的conn封装了 net.Conn, bufio.Reader, 事务状态，参数状态，message及一些标记 等信息。

Driver.Open() 调用 DialOpen(defaultDialer{}, name), 而 DialOpen(d Dialer, name string) (_ driver.Conn, err error) 做实际
的工作。

        cn.c, err = dial(d, o)
    	if err != nil {
    		return nil, err
    	}
    	cn.ssl(o)
    	cn.buf = bufio.NewReader(cn.c)
    	cn.startup(o)

    	// reset the deadline, in case one was set (see dial)
    	if timeout := o.Get("connect_timeout"); timeout != "" && timeout != "0" {
    		err = cn.c.SetDeadline(time.Time{})
    	}

把 connection 转换成 Reader

    // c         net.Conn
    // buf       *bufio.Reader
    cn.buf = bufio.NewReader(cn.c)

#### 启动握手


cn.startup(o): 启动握手处理，直到出错，或者 connection ready for query.

##### 建立TCP连接后，给server发送 startup 包

    启动包数据：

        scratch [512]byte

        c.scratch[0] = b
        return &writeBuf{
            buf: c.scratch[:5], // buf 是从第 5 个字节开始，第一个字节有特殊使用，后面是长度。
            pos: 1              // 第一个字节总是 0， 不会被使用.
        }

    PostgreSQL 启动包格式：
        byte 0:                     0   // 不用, 不会发给server。
        byte 1-4:                   196608, 0x30000 // (libpq version 3?)
        byte array terminated by 0: string (key)
        byte array terminated by 0: string (value)
        ... more key/value pair terminated by '\0' each.
        byte:                       0


##### 握手时等待server响应，并进行对应的处理

响应包的格式和意义：

- K, S: 返回server的版本和 TimeZone， 设置 currentLocation。
- R: 处理认证信息，目前支持 password 和 md5.
- w: 处理 QE details 的信息，主要是获得 listener port
- z: 处理 QEWriter 信息 （xact状态， DtxId，cmdid， dirty），并进入 ready 状态
- Z: 获得事务状态，并进入 ready 状态。
- A, N: 忽略了

部分代码：

    	for {
    		t, r := cn.recv()
    		switch t {
    		case 'K':
    		case 'S':
    			cn.processParameterStatus(r)
    		case 'R':
    			cn.auth(r, o)
    		case 'w':
    			cn.processQEDetails(r)
    		case 'z':
    			cn.processReadyForQueryWithQEWriterInfo(r)
    			return
    		case 'Z':
    			cn.processReadyForQuery(r)
    			return
    		default:
    			errorf("unknown response for startup: %q", t)
    		}
    	}

如何从 socket 连接上接受数据，一次接收一个完整的 message：

    消息格式：

    byte 0:   消息类型
    byte 1-4: 长度
    payload

处理流程：

        (cn *conn) recv() (t byte, r *readBuf)

        (cn *conn) recvMessage(r *readBuf) (byte, error)

        io#ReadFull(r Reader, buf []byte) (n int, err error)

        io#ReadAtLeast(r Reader, buf []byte, min int) (n int, err error)  # for loop

        Reader.Read(p []byte) (n int, err error)



    首先读 5 个字节：io.ReadFull(r Reader, buf []byte) (n int, err error) -> ReadAtLeast() -> r.Read(buf).

    第一个字节是消息类型， 此后四个字节是消息长度，长度包括消息长度的4个字节。

            func ReadFull(r Reader, buf []byte) (n int, err error) {
            	return ReadAtLeast(r, buf, len(buf))
            }


        	func ReadAtLeast(r Reader, buf []byte, min int) (n int, err error) {
            	if len(buf) < min {
            		return 0, ErrShortBuffer
            	}
            	for n < min && err == nil {
            		var nn int
            		nn, err = r.Read(buf[n:])
            		n += nn
            	}
            	if n >= min {
            		err = nil
            	} else if n > 0 && err == EOF {
            		err = ErrUnexpectedEOF
            	}
            	return
            }


    然后根据读取消息体长度个字节，根据消息长度，或者重用 scratch buffer 或者创建一个长度为 n的 slices，并读入这些信息。

        var y []byte
    	if n <= len(cn.scratch) {
    		y = cn.scratch[:n]
    	} else {
    		y = make([]byte, n)
    	}
    	_, err = io.ReadFull(cn.buf, y)


##### 执行不返回rows的查询，例如BEGIN等: simpleExec()


    请求格式：

        byte 0: Q
        byte 1-4: 长度，包括长度的四个字节本身
        payload: query string terminated with '\0'

    响应格式： 使用 recvMessage() 返回一个完整的消息，如果消息不完整或者出错，则返回错误。
    持续处理响应包，直到收到 Z，表示connection可以处理查询。

        C (CommandComplete msg): 包括受影响的行数，及一个字符串标识执行的命令，例如“ALTER TABLE”
            byte 0: C
            byte 1-4: 长度
            payload: commandTag rows

        Z
            byte 0: Z
            byte 1-4: 长度
            payload: 一个字节的事务状态

        E: ErrorMessage
            byte 0: E
            payload:
                TypeChar followed with string.
                S/C/M/D/H/P/p/q/W/s/t/c/d/n/F/L/R

        T/D/I: results. ignore for simpleExec.

##### 执行返回rows的查询： simpleQuery()

返回的 rows 数据结构没有实际数据，需要调用 next() 函数确定是否有实际数据。

    请求格式：

        byte 0: Q
        byte 1-4: 长度，包括长度本身的四个字节
        payload: query string terminated with '\0'

    响应格式： 使用 recvMessage 接受完整的消息。

        C/I: 允许不反悔 result 的查询使用 Query 执行，返回一个 fake 的 rows 对象。

        Z:
            byte 0: Z
            byte 1-4: 长度
            payload: 一个字节的事务状态

        E: ErrorMessage
            byte 0: E
            payload:
                TypeChar followed with string.
                S/C/M/D/H/P/p/q/W/s/t/c/d/n/F/L/R

        D: DataRow is not allowed in simple query execution

        T: 解析 PortalRowDescribe

            byte 0-1: 2 个字节，表示 column 的个数
            byte array terminated by '\0': column name
            6 个字节： 跳过
            oid
            6 个字节： 跳过
            2 个字节： 字段格式

##### Prepare stmt

        byte 0: 'P'
        byte array: string st.name
        byte array: query itself
        2个字节: 0
        D    // next('D')
        S
        stmt.name
        S    // next('S')

##### Queryer#Query 实现

如果不带 bind 参数，则直接使用 simpleQuery； 否则确定是否发送 binaryModeQuery。
非binary模式下，使用 prepare/exec:

    st := cn.prepareTo(query, "")
    st.exec(args)
    return &rows {
        cn: cn,
        colNames: st.colNames,
        colTypes: st.colTypes,
        colFmts:  st.colFmts,
    }, nil


##### Execer#Exec 实现

如果不带 bind 参数，则直接使用 simpleExec； 否则确定是否发送 binaryModeQuery。
非binary模式下，使用 prepare/exec:

##### Rows#Next()

直接从 connection 上读取数据：

        E:  ErrorMessage
        C/I: continue
        Z:  conn.processReadyForQuery(&rs.rb)
            rs.done = true

        D:
            2个字节表示字段个数
            对每个字段：
                4个字节：该字段数据的长度
                decode(parameterStatus *, s []byte, type oid.Oid, f format)
                    分别调用 binaryDecode() 或者 textDecode() 进行解码。
                    内部根据返回的类型的 oid 进行分别处理。


