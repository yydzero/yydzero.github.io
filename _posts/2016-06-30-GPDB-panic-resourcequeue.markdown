---
layout: post
title:  "How to debug GPDB case study 2"
author: 姚延栋
date:   2016-06-21 09:49
categories: gpdb global variables
published: false
---

Resource queue result in panic

## Infomation

query string:

    (gdb) p debug_query_string
    select distinct  a.attrelid, a.attname, a.attnum
    from pg_catalog.pg_partition p
    join pg_catalog.pg_attribute a on a.attrelid = p.parrelid
    where a.attnum >= 0   and not a.attisdropped
    order by attrelid, attnum

call stack

    (gdb) bt
    #0  0x00007f4fc02e55db in raise ()
       from /home/gpadmin/work/cases/mpp26451/packcore-core.postgres.767165.1467114744.11.500.500/lib64/libpthread.so.0
    #1  0x0000000000b026f6 in StandardHandlerForSigillSigsegvSigbus_OnMainThread (processName=<value optimized out>, postgres_signal_arg=11)
        at elog.c:4479
    #2  <signal handler called>
    #3  ResProcLockRemoveSelfAndWakeup (proc=<value optimized out>, hashcode=<value optimized out>) at resqueue.c:1103
    #4  ResCleanUpLock (proc=<value optimized out>, hashcode=<value optimized out>) at resqueue.c:984
    #5  ResRemoveFromWaitQueue (proc=<value optimized out>, hashcode=<value optimized out>) at resqueue.c:1244
    #6  0x00000000009738c1 in ResLockWaitCancel () at proc.c:1747
    #7  0x0000000000b53e30 in ResLockPortal (portal=<value optimized out>, qDesc=<value optimized out>) at resscheduler.c:696
    #8  0x00000000009a27d1 in PortalStart (portal=<value optimized out>, params=<value optimized out>, snapshot=<value optimized out>,
        seqServerHost=<value optimized out>, seqServerPort=<value optimized out>) at pquery.c:809
    #9  0x0000000000998c33 in exec_simple_query (query_string=<value optimized out>, seqServerHost=<value optimized out>,
        seqServerPort=<value optimized out>) at postgres.c:1758
    #10 0x000000000099cbd6 in PostgresMain (argc=<value optimized out>, argv=0x1b72f70, dbname=0x1b72eb0 "pgsdwh",
        username=<value optimized out>) at postgres.c:4735
    #11 0x00000000008fa7de in BackendRun () at postmaster.c:6963
    #12 BackendStartup () at postmaster.c:6658
    #13 ServerLoop () at postmaster.c:2464
    #14 0x00000000008fd560 in PostmasterMain (argc=18, argv=0x1b1c8e8) at postmaster.c:1540
    #15 0x00000000007ff5ef in main (argc=18, argv=0x1b1c860) at main.c:206

    (gdb) p GpIdentity
    $6 = {numsegments = 64, dbid = 1, segindex = -1}

bring back portal: we could bring back portal using following method. Or simply it is stored in `ActivePortal`

    (gdb) p portal
    $13 = <value optimized out>

    (gdb) p &format
    $26 = (int16 *) 0x7fffbe02264c                                  // local variable's address on stack

    (gdb) info registers
    rax            0xffffffffffffffff	-1
    rbx            0x7f4fa04c25b8	139979968488888                 // plantree_list
    rcx            0xffffffffffffffff	-1
    rdx            0x7f4fa16de000	139979987476480
    rsi            0x0	0
    rdi            0x7f4faf21b7f0	139980217366512
    rbp            0x7fffbe022680	0x7fffbe022680
    rsp            0x7fffbe022570	0x7fffbe022570
    r8             0xffffffffffffffff	-1
    r9             0x7f4faeedb510	139980213957904
    r10            0xe61	3681
    r11            0x5	5
    r12            0x1cfc1b0	30392752
    r13            0x1cf9bb8	30383032                            // parsetree
    r14            0x1cf9f10	30383888
    r15            0x0	0
    rip            0x998c33	0x998c33 <exec_simple_query+1475>
    eflags         0x206	[ PF IF ]
    cs             0x33	51
    ss             0x2b	43
    ds             0x0	0
    es             0x0	0
    fs             0x0	0
    gs             0x0	0

    (gdb) p *(Portal) 0x1cfc1b0
    $32 = {name = 0x1c9f048 "", prepStmtName = 0x0, heap = 0x1da77d0, resowner = 0x1da2540, cleanup = 0x6e5990 <PortalCleanup>,
      createSubid = 1, portalId = 0, sourceTag = T_SelectStmt, queueId = 1376894435,
      sourceText = 0x1daa7e0 "select distinct\r\n       a.attrelid, -- 0\r\n       a.attname,  -- 1\r\n       a.attnum    -- 2\r\n  from pg_catalog.pg_partition p\r\n  join pg_catalog.pg_attribute a on a.attrelid = p.parrelid\r\n where a.attnum >= 0\r\n   and not a.attisdropped\r\n   \r\n order by attrelid, attnum", commandTag = 0xef2298 "SELECT", stmts = 0x7f4fa04c25b8, queryContext = 0x1cec2a8, portalParams = 0x0,
      strategy = PORTAL_ONE_SELECT, cursorOptions = 4, portal_status = PORTAL_QUEUE, releaseResLock = 0 '\000', queryDesc = 0x0,
      tupDesc = 0x0, formats = 0x0, holdStore = 0x0, holdContext = 0x0, atStart = 1 '\001', atEnd = 1 '\001', posOverflow = 0 '\000',
      portalPos = 0, creation_time = 520429619346225, visible = 0 '\000', is_extended_query = 0 '\000', is_simply_updatable = 0 '\000'}

    (gdb) p *ActivePortal
    $42 = {name = 0x1c9f048 "", prepStmtName = 0x0, heap = 0x1da77d0, resowner = 0x1da2540, cleanup = 0x6e5990 <PortalCleanup>,
      createSubid = 1, portalId = 0, sourceTag = T_SelectStmt, queueId = 1376894435,
      sourceText = 0x1daa7e0 "select distinct\r\n       a.attrelid, -- 0\r\n       a.attname,  -- 1\r\n       a.attnum    -- 2\r\n  from pg_catalog.pg_partition p\r\n  join pg_catalog.pg_attribute a on a.attrelid = p.parrelid\r\n where a.attnum >= 0\r\n   and not a.attisdropped\r\n   \r\n order by attrelid, attnum", commandTag = 0xef2298 "SELECT", stmts = 0x7f4fa04c25b8, queryContext = 0x1cec2a8, portalParams = 0x0,
      strategy = PORTAL_ONE_SELECT, cursorOptions = 4, portal_status = PORTAL_QUEUE, releaseResLock = 0 '\000', queryDesc = 0x0,
      tupDesc = 0x0, formats = 0x0, holdStore = 0x0, holdContext = 0x0, atStart = 1 '\001', atEnd = 1 '\001', posOverflow = 0 '\000',
      portalPos = 0, creation_time = 520429619346225, visible = 0 '\000', is_extended_query = 0 '\000', is_simply_updatable = 0 '\000'}


snapshot:

    (gdb) f 8
    (gdb) p *ActiveSnapshot
    $34 = {xmin = 812051406, xmax = 812743154, xcnt = 244, xip = 0x1dabc68, subxcnt = 31, subxip = 0x1dac038, curcid = 0,
      haveDistribSnapshot = 1 '\001', distribSnapshotWithLocalMapping = {header = {distribTransactionTimeStamp = 1466960746,
          xminAllDistributedSnapshots = 2460706, distribSnapshotId = 132030671, xmin = 2601158, xmax = 2922949, count = 243, maxCount = 1000},
        inProgressEntryArray = 0x1dac0b4}}

## Queue

### ResLockPortal

PortalSetStatus() is used to update portal status.

    switch (portal->strategy)
        {
            case PORTAL_ONE_SELECT:
                ...
                PortalSetStatus(portal, PORTAL_QUEUE);

                if (gp_resqueue_memory_policy != RESQUEUE_MEMORY_POLICY_NONE)
                    queryDesc->plannedstmt->query_mem = ResourceQueueGetQueryMemoryLimit(queryDesc->plannedstmt, portal->queueId);
                portal->releaseResLock = ResLockPortal(portal, queryDesc);

                PortalSetStatus(portal, PORTAL_ACTIVE);


ResLockPortal(Portal portal, QueryDesc *qDesc): get a resourcelock for portal execution

This function calculates resource needed to execute current query, and try to acquire a lock.

resource needed is stored in increments: count, cost, memory.

    (gdb) p incData
    $54 = {pid = 767165, portalId = 0, owner = 0x8, isHold = -48 '\320', isCommitted = 35 '#', portalLink = {prev = 31108416,
        next = 139979968488584}, increments = {1, 59516, 131072000}}

how to take lock:

    if (takeLock)
    {
        SET_LOCKTAG_RESOURCE_QUEUE(tag, queueid);

        PG_TRY();
        {
            lockResult = ResLockAcquire(&tag, &incData);
        }
        PG_CATCH();
        {
            ResLockWaitCancel();

            /* If we had acquired the resource queue lock, release it and clean up */
            ResLockRelease(&tag, portal->portalId);

            portal->queueId = InvalidOid;
            portal->portalId = INVALID_PORTALID;

            PG_RE_THROW();
        }
        PG_END_TRY();
    }


    (gdb) p errordata[0]
    $59 = {elevel = 20, output_to_server = 1 '\001', output_to_client = 1 '\001', show_funcname = 0 '\000', omit_location = 1 '\001',
      fatal_return = 0 '\000', hide_stmt = 0 '\000', send_alert = 0 '\000', filename = 0xef1f38 "postgres.c", lineno = 3605,
      funcname = 0xeedec0 "ProcessInterrupts", domain = 0xebe447 "postgres-8.2", sqlerrcode = 67371461,
      message = 0x1b207f0 "canceling statement due to user request", detail = 0x0, detail_log = 0x0, hint = 0x0, context = 0x0, cursorpos = 0,
      internalpos = 0, internalquery = 0x0, saved_errno = 4, stacktracearray = {0xb0ac2e, 0x99615c, 0x8e0590, 0x976d08, 0xb52fcd, 0xb53d04,
        0x9a27d1, 0x998c33, 0x99cbd6, 0x8fa7de, 0x8fd560, 0x7ff5ef, 0x7f4fbf7bad5d, 0x4c4de9, 0x0 <repeats 16 times>}, stacktracesize = 14,
      printstack = 0 '\000'}


### ResLockWaitCancel

Cancel any pending wait for a resource lock, when aborting a transaction.

    if (lockAwaited != NULL)
    {
        LWLockId partitionLock = LockHashPartition(lockAwaited->hashcode);
        LWLockAcquire(partitionLock, LW_EXCLUSIVE);

        if (MyProc->links.next != INVALID_OFFSET)       // MyProc->links double link
        {
            /* We could not have been granted the lock yet */
            Assert(MyProc->waitStatus == STATUS_ERROR);

            /* We should only be trying to cancel resource locks. */
            Assert(LOCALLOCK_LOCKMETHOD(*lockAwaited) == RESOURCE_LOCKMETHOD);

            ResRemoveFromWaitQueue(MyProc, lockAwaited->hashcode);
        }

        lockAwaited = NULL;

        LWLockRelease(partitionLock);
    }

    PGSemaphoreReset(&MyProc->sem);


lockAwaited: if we are waiting for a lock, lockAwaited points to the associated LOCALLOCK.

#### Local lock

Each backend also maintains a local hash table with information about each lock
it is currently interested in. In particular the local hash table counts the number of
times that lock has been acquired. This allows multiple requests for the same lock
to be executed without additional accesses to shared memory. We also track the number of
lock acquisitions per ResourceOwner, so that we can release just those locks belonging to
a particular ResourceOwner.

    (gdb) p *lockAwaited
    $62 = {tag = {lock = {locktag_field1 = 1376894435, locktag_field2 = 0, locktag_field3 = 0, locktag_field4 = 0, locktag_type = 8 '\b',
          locktag_lockmethodid = 3 '\003'}, mode = 7}, lock = 0x7f4faad5f970, proclock = 0x7f4fac73c5f0, hashcode = 4027858029,
      preparable = 0 '\000', nLocks = 0, numLockOwners = 0, maxLockOwners = 8, lockOwners = 0x1d97c60}

lockmgr's shared hash tables are partitioned to reduce contentions (By default partitioned into 16 parts).
Use hash code to determine which partition belongs to:

    hashcode % NUM_LOCK_PARTITIONS

Following code is problematic:

    partitionLock = LockHashPartition(lockAwaited->hashcode);
    LWLockAcquire(partitionLock, LW_EXCLUSIVE);

    -->

    partitionLock = LockHashPartitionLock(lockAwaited->hashcode);
    LWLockAcquire(partitionLock, LW_EXCLUSIVE);

#### predefined LWLocks

GPDB predefined a number of LWLocks, also have some LWLocks are dynamically assigned (eg: for shared buffers).
LWLock structures live in shared memory and are identified by values of this enumerated type.

    typedef enum LWLockId
    {
        NullLock = 0,
        BufFreelistLock,
        ...
        WALWriteLock,           // 10
        ControlFileLock,
        CheckpointLock,
        CheckpointStartLock,    // 13
        ...
        BgWriterCommLock,       // 20
        ...
        SeqServerControlLock,   // 30
        ...
        ResQueueLock,           // 40
        FileRepAppendOnlyCommitCountLock,
        SyncRepLock,
        ErrorLogLock,
        FirstWorkfileMgrLock,   // 44
        FirstWorkfileQuerySpaceLock = FirstWorkfileMgrLock + NUM_WORKFILEMGR_PARTITIONS (32),           // 76
        FirstBufMappingLock = FirstWorkfileQuerySpaceLock + NUM_WORKFILE_QUERYSPACE_PARTITIONS (128),   // 204
        FirstLockMgrLock = FirstBufMappingLock + NUM_BUFFER_PARTITIONS (16),                            // 220
        SessionStateLock = FirstLockMgrLock + NUM_LOCK_PARTITIONS (16),                                 // 236

        /* must be last except for MaxDynamicLWLock: */
        NumFixedLWLocks,                                                                                // 237

        MaxDynamicLWLock = 1000000000
    } LWLockId;

HashPartition: eg: LockMgrLock, it is partitioned into 16 parts, their lock id is from [221 - 236]. Thus could
reduce lock contention.

ResLockWaitCancel() need to acquire LockMgrLock to do its job.

    // Process wait state:
    proc->waitLock = NULL;
    proc->waitProcLock = NULL;
    proc->waitStatus = waitStatus;  // STATUS_WAITING, STATUS_OK or STATUS_ERROR

* ResProcWakeup(PGPROC *proc, int waitStatus): wake a sleeping process.
* ResProcSleep()
* ProcSleep()
* ProcWakeup()

### ResRemoveFromWaitQueue: remove a process from the wait queue, cleaning up any locks

    ResRemoveFromWaitQueue(MyProc, lockAwaited->hashcode);

## shared memory

POSTGRES processes share one or more regions of shared memory.  The shared memory is created by a postmaster
and is inherted by each backend via fork().

Each process must map the shared memory region at the same address. This means shared memory pointers
can be passed around directly between different processes.

* POSTGRES 有三种类型的共享内存数据结构： fixed-size structures, queues, 和 hashtable。 固定大小结构包含module的全局变量，
一旦初始化后不能再分配。 hash table 的最大大小是固定的，但是其实际大小是可变的，当加入新entries时，分配更多的空间。 Queues 将
链接数据结构称为链表。  每个共享内存数据结构都有一个字符串名字。
* 初始化的时候，每个 module 从称为 “Shmem Index”的哈希表中找自己的共享数据结构。 如果不存在，则分配一个并初始化。如果module的共享数据结构
已经存在了， 则在本地地址空间分配一个指针指向共享数据结构。  "shmem index" 一方面可以确定哪些初始化了，哪些还没有初始化，另一方面可以按需分配共享内存。
* Unix 环境下，backends 不需要重新初始化指向共享内存的本地指针，因为从 postmaster fork 时已经继承了正确的值。
* memory 分配模型： 一旦分配，不会释放。  每个 hashtable 都有自己的 freelist，所以删除后，可以被重用。但是不会释放给其他共享结构使用。

### data types

* SHMEM_OFFSET: is a data type.  `typedef unsigned long SHMEM_OFFSET;`
* ShmemBase: start of the primary shared memory region.

* SHM_QUEUE

    typedef struct SHM_QUEUE
    {
        SHMEM_OFFSET prev;
        SHMEM_OFFSET next;
    } SHM_QUEUE;

### shared memory global variables

shared memory is about 0x1680bba0 (around 380MB).

* static PGShmemHeader *ShmemSegHdr;		/* shared mem segment header */
* SHMEM_OFFSET ShmemBase;			        /* start address of shared memory */
* static SHMEM_OFFSET ShmemEnd;	            /* end+1 address of shared memory */
* slock_t    *ShmemLock;			        /* spinlock for shared memory and LWLock  allocation */
* static HTAB *ShmemIndex = NULL;           /* primary index hashtable for shmem */
* static int ShmemSystemPageSize = 0;       /* system's page size */

Shared memory access routines:

* InitShmemAccess:  设置指向共享内存的基础指针。 是使用共享内存的第一个需要做的操作。 它设置了共享内存的三个主要全局变量：SHmemSegHdr, ShmemBase, ShmemEnd
* InitShmemAllocation:  set up shared memory space allocation
* ShmemAlloc: 从共享内存中分配 max-aligned chunk
* ShmemIsValid
* InitShmemIndex:  初始化 shmem index table
* ShmemInitHash:  根据给定的参数 （名字，大小，flag等） 创建并初始化一个共享内存 hash table
* ShmemInitStructure: 在共享内存中创建一个 structure。在初始化时调用.

### PGPROC: per-process shared memory data structures

每个 Backend 在共享内存区都有一个 PGPROC 结构来描述该 backend。也有一个当前未用的 PGPROC 结构体列表。

links: PGPROC->links 表示当前 PGPROC 所处的链表。例如等待lock时，PGPROC 被链接到 lock 的 waitProcs 队列中。回收的 PGPROC 链接到
ProcGlobal的 freeProcs 列表中。

    struct PGPROC
    {
        /* proc->links MUST BE FIRST IN STRUCT (see ProcSleep,ProcWakeup,etc) */
        SHM_QUEUE	links;			/* list link if process is in a list */

        PGSemaphoreData sem;		/* ONE semaphore to sleep on */
        int			waitStatus;		/* STATUS_WAITING, STATUS_OK or STATUS_ERROR */

        Latch		procLatch;		/* generic latch for process */

        TransactionId xid;			/* transaction currently being executed by this proc */

        LocalDistribXactRef	localDistribXactRef;
                                    /* Reference to the LocalDistribXact
                                     * element. */
        TransactionId xmin;			/* minimal running XID as it was when we were
                                     * starting our xact, excluding LAZY VACUUM:
                                     * vacuum must not remove tuples deleted by
                                     * xid >= xmin ! */

        int			pid;			/* This backend's process id, or 0 */
        Oid			databaseId;		/* OID of database this backend is using */
        Oid			roleId;			/* OID of role using this backend */
        int         mppSessionId;   /* serial num of the qDisp process */
        int         mppLocalProcessSerial;  /* this backend's PGPROC serial num */
        bool		mppIsWriter;	/* The writer gang member, holder of locks */
        bool		postmasterResetRequired; /* Whether postmaster reset is required when this child exits */

        bool		inVacuum;		/* true if current xact is a LAZY VACUUM */

        /* Info about LWLock the process is currently waiting for, if any. */
        bool		lwWaiting;		/* true if waiting for an LW lock */
        bool		lwExclusive;	/* true if waiting for exclusive access */
        struct PGPROC *lwWaitLink;	/* next waiter for same LW lock */

        /* Info about lock the process is currently waiting for, if any. */
        /* waitLock and waitProcLock are NULL if not currently waiting. */
        LOCK	   *waitLock;		/* Lock object we're sleeping on ... */
        PROCLOCK   *waitProcLock;	/* Per-holder info for awaited lock */
        LOCKMODE	waitLockMode;	/* type of lock we're waiting for */
        LOCKMASK	heldLocks;		/* bitmask for lock types already held on this
                                     * lock object by this backend */

        /*
         * Info to allow us to wait for synchronous replication, if needed.
         * waitLSN is InvalidXLogRecPtr if not waiting; set only by user backend.
         * syncRepState must not be touched except by owning process or WALSender.
         * syncRepLinks used only while holding SyncRepLock.
         */
        XLogRecPtr	waitLSN;		/* waiting for this LSN or higher */
        int			syncRepState;	/* wait state for sync rep */
        SHM_QUEUE	syncRepLinks;	/* list link if process is in syncrep queue */

        /*
         * All PROCLOCK objects for locks held or awaited by this backend are
         * linked into one of these lists, according to the partition number of
         * their lock.
         */
        SHM_QUEUE	myProcLocks[NUM_LOCK_PARTITIONS];

        struct XidCache subxids;	/* cache for subtransaction XIDs */

        /*
         * Info for Resource Scheduling, what portal (i.e statement) we might
         * be waiting on.
         */
        uint32		waitPortalId;	/* portal id we are waiting on */

        /*
         * Information for our combocid-map (populated in writer/dispatcher backends only)
         */
        uint32		combocid_map_count; /* how many entries in the map ? */

        int queryCommandId; /* command_id for the running query */

        bool serializableIsoLevel; /* true if proc has serializable isolation level set */

        bool inDropTransaction; /* true if proc is in vacuum drop transaction */
    };
