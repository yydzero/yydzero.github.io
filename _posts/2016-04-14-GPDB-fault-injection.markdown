---
layout: post
title:  "gp\_faultinjector: GPDB Fault Injection"
subtitle:  "GPDB 错误注入工具 gp\_faultinjector"
author: TangPengzhou
date:   2016-04-13 15:07:24
categories: gpdb fault injection 
published: true
---

# GPDB Fault Injection

## OverView
gpfaultinjector is a internal-used only fault injection framework used by GPDB, users can inject 17 kinds of faults into
more than 150 locations which cover bellow 5 areas:

> File Replication

> Fault Tolerance System

> PG2Phase

> Transaction

> Crash Recovery

#### Usage
** gp_faultinjector -f StartPrepareTx -y fault -r primary -s 10 -H sdw2 -c create_table -D gpadmin -t testtable -o 10 **

#### Test example

```python
 def test_postmaster_reset(self):
        ''' Test FTS :Postmaster reset fails on mirror, transition is not copied to local memory.'''
        outfile=mkpath('fault_mpp.out')
        command = "gpfaultinjector -f filerep_flush -y panic -m async -r primary -H ALL > %s 2>&1" % (outfile)
        shell.run(command)
        print "\n Done Injecting Fault"
        psql.runfile(mkpath('test_ddl.sql'),'-a')
        self.postmaster_reset_test_validation('sync1','mirror’)

```

This command says users want to enable an injector named "StartPrepareTx" in host sdw2 for segment 10 and want injector to report a panic error. So next time users run create table queries, a panic will be raised.

More usage can refer to gp_faultinjector --help

### Example of fault injection

Following is an example log when fault name 'workfile_creation_failure' with type 'error' triggered. 

fault triggered, fault name:'workfile_creation_failure' fault type:'error' (faultinjector.c:675)", ... , "faultinjector.c",675

    2016-06-17 22:12:27.944750 CST,"yyao","zlib",p3441,th2080523024,"127.0.0.1","61226",2016-06-17 22:10:14 CST,697,con20,cmd15,seg0,slice2,,x697,sx1,"ERROR","XX000","fault triggered, fault name:'workfile_creation_failure' fault type:'error' (faultinjector.c:675)",,,,,,"SELECT COUNT(t1.*) FROM test_zlib_hashjoin AS t1, test_zlib_hashjoin AS t2 WHERE t1.i1=t2.i2;",0,,"faultinjector.c",675,"Stack trace:
    1    0x1065a1bde postgres errstart + 0x5ee
    2    0x1065e005e postgres FaultInjector_InjectFaultIfSet + 0x6ee
    3    0x106649d59 postgres workfile_mgr_create_fileno + 0xe9
    4    0x1061b4005 postgres ExecHashJoinSaveTuple + 0xc5
    5    0x1061afa37 postgres ExecHashTableInsert + 0x357
    6    0x1061af2b1 postgres MultiExecHash + 0x141
    7    0x106182907 postgres MultiExecProcNode + 0x367
    8    0x1061b332b postgres ExecHashJoin + 0x28b
    9    0x106182210 postgres ExecProcNode + 0x530
    10   0x1061a61b3 postgres agg_retrieve_direct + 0x223
    11   0x1061a59d9 postgres ExecAgg + 0x2d9
    12   0x10618224f postgres ExecProcNode + 0x56f
    13   0x1061d2edb postgres execMotionSender + 0x14b
    14   0x1061d1f1e postgres ExecMotion + 0x1ce
    15   0x1061822b8 postgres ExecProcNode + 0x5d8
    16   0x106173ed3 postgres ExecutePlan + 0x193
    17   0x106173a66 postgres ExecutorRun + 0x4d6
    18   0x10640ff22 postgres PortalRunSelect + 0x152
    19   0x10640f9e7 postgres PortalRun + 0x367
    20   0x106409483 postgres exec_mpp_query + 0x1263
    21   0x10640689c postgres PostgresMain + 0x166c
    22   0x1063794b7 postgres BackendRun + 0x2f7
    23   0x106378862 postgres BackendStartup + 0x192
    24   0x106373a54 postgres ServerLoop + 0x554
    25   0x106371baf postgres PostmasterMain + 0x155f
    26   0x106247aa6 postgres main + 0x346
    27   0x7fff92c8e5fd libdyld.dylib start + 0x1
    28   0xf <symbol not found>
    "


## Implementation of gpfaultinjector.

### 1. What gp_faultinjector utility actually do?
gp_primarymirror is mostly used to send primary/mirror role changing command, but can also be used by gp_faultinjector for fault injection. In this mode, a message like "faultInject filerep_resync_in_progress fault create_table gpadmin testtable 10" will be sent
to specified segments.

In segment, postmaster receive the message and recognize it as faultInjection type, then insert a record into hash table in shared memory.
Notice that postmaster will not fork a backend, it just update the hash table

The pseudo looks like:

```c
ProcessStartupPacket
{
  if (proto == PRIMARY_MIRROR_TRANSITION_REQUEST_CODE
    ->  processPrimaryMirrorTransitionRequest(port, buf);
         -> if (strcmp("faultInject", targetModeStr) == 0)
            {
                processTransitionRequest_faultInject(buf, &offset, length);
                  -> FaultInjector_SetFaultInjection()
                      -> FaultInjector_NewHashEntry()
                        -> FaultInjector_InsertHashEntry()
            }
}
```

### 2. How injector is triggered
A injector is pre-added into source code, for example, if you want to inject function StartPrepare() in GPDB, you need to
add bellow lines to StartPrepare:

```
StartPrepare()
{
  ......

#ifdef FAULT_INJECTOR
        FaultInjector_InjectFaultIfSet(
                StartPrepareTx, //injector name, it's the search key of hash table in shared memory
                                //and users need to specified in gp_faultinjector utility
                DDLNotSpecified,
                "",  // databaseName
                ""); // tableName
#endif

  .....
}
```

When queries run and StartPrepare() is called, FaultInjector_InjectFaultIfSet() will search hash table with key "StartPrepareTx" to see if any users enabled this injector before (specified by gp_faultinjector). If not, no fault is created, otherwise it will create faults users specified.

the logic looks like:

```c
switch (entryLocal->faultInjectorType) {
                case FaultInjectorTypeSleep:
                      pg_usleep(entryLocal->sleepTime * 1000000L);
                case FaultInjectorTypeFatal:
                      ereport(FATAL, "xxxxx");
                case FaultInjectorTypePanic:
                      ereport(FATAL, "xxxxx");
```

## How to add a new injector under current fault injection framework

We'll use internal_flush_error as a running example.

1.Add a new entry to the clsInjectFault python file. Remember the position of the new line relative to the other entries (e.g. second to last)

```c
"internal_flush_error (inject an error during internal_flush), " \
```
2.In the same relative position to the other entries as in the list, add a new entry to the enum FaultInjectorIdentifier_e in faultinjector.h       InternalFlushError
3.In the same relative position to the other entries in the list, add a new entries to the const char* FaultInjectorIdentifierEnumToString[]: in faultinjector.c

```c
("internal_flush_error"),
```
4.Go to the part of the code where you want the fault to be injected.
Include the fault injector header  **#include "utils/faultinjector.h"**

In our case, I injected the following code in internal_flush():

```c
#ifdef FAULT_INJECTOR
    FaultInjector_InjectFaultIfSet(
        InternalFlushError,
        DDLNotSpecified,
        "", // databaseName
        ""); // tableName
#endif
```
5.To inject the fault, use the gpfaultinjector script
> E.g. to inject on the master: gpfaultinjector -f internal_flush_error -y error --seg_dbid 1
