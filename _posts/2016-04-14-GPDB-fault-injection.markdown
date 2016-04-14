---
layout: post
title:  "GPDB Fault Injection"
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

#### Example
> gp_faultinjector -f StartPrepareTx -y fault -r primary -s 10 -H sdw2 -c create_table -D gpadmin -t testtable -o 10

This command says users want to enable an injector named "StartPrepareTx" in host sdw2 for segment 10 and want injector to report a panic error. So next time users run create table queries, a panic will be raised.

More usage can refer to gp_faultinjector --help


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
