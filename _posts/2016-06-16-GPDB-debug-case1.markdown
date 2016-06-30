---
layout: post
title:  "How to debug GPDB"
author: 姚延栋
date:   2016-06-21 09:49
categories: gpdb global variables
published: false
---

## How to debug GPDB

zlib test case failed due to the fact that AbortTransaction is called multiple times (Abort is called during Abort),
while there is code assertion against this. so failed.

below is the case study.

    $ checkout GPDB with commit 33fa579f46ff586a81de6ad52d25831bf0bdf7f2

## zlib test case will fail


    DROP TABLE IF EXISTS test_zlib_hashjoin;
    CREATE TABLE test_zlib_hashjoin (i1 int, i2 int, i3 int, i4 int, i5 int, i6 int, i7 int, i8 int) WITH (APPENDONLY=true) DISTRIBUTED BY (i1) ;
    INSERT INTO test_zlib_hashjoin SELECT i,i,i,i,i,i,i,i FROM
        (select generate_series(1, nsegments * 333333) as i from
        (select count(*) as nsegments from gp_segment_configuration where role='p' and content >= 0) foo) bar;

    SET gp_workfile_type_hashjoin=bfz;
    SET gp_workfile_compress_algorithm=zlib;
    SET statement_mem=5000;

    --Fail after workfile creation and before add it to workfile set
    --start_ignore
    \! gpfaultinjector -f workfile_creation_failure -y reset --seg_dbid 2
    \! gpfaultinjector -f workfile_creation_failure -y error --seg_dbid 2
    --end_ignore

    SELECT COUNT(t1.*) FROM test_zlib_hashjoin AS t1, test_zlib_hashjoin AS t2 WHERE t1.i1=t2.i2;


failure log: segment encounter assertion error, thus failed, then result in master failure.

segment log:

    1823 2016-06-17 17:44:35.506375 CST,,,p67175,th1945256720,,,,0,,,seg-1,,,,,"LOG","00000","3rd party error log:
    1824  --
    1825 Warning: /usr/bin/atos is moving and will be removed from a future OS X release.
    1826 It is now available in the Xcode developer tools to be invoked via: `xcrun atos`
    1827 To silence this warning, pass the '-d' command-line flag to this tool.
    1828  --",,,,,,,,"SysLoggerMain","syslogger.c",618,
    1829 2016-06-17 17:44:35.517412 CST,"metro","zlib",p70533,th1945256720,"127.0.0.1","53731",2016-06-17 17:43:50 CST,697,con18,cmd11,seg0,slice2,,x697,sx1,"ERROR","XX000","fault triggered, fault name:'workfile_creation_failure' fault type:'error' (faultinjector.c:675)",,,,,,"SELECT COUNT(t1.*) FROM test_zlib_hashjoin AS t1, test_zlib_hashjoin AS t2 WHERE t1.i1=t2.i2;",0,,"faultinjector.c",675,"Stack trace:
    1830 1    0x10a0c0a0e postgres errstart + 0x5ee
    1831 2    0x10a0fe525 postgres FaultInjector_InjectFaultIfSet + 0x6b5
    1832 3    0x10a167b34 postgres workfile_mgr_create_fileno + 0xd4
    1833 4    0x109cdb635 postgres ExecHashJoinSaveTuple + 0xc5
    1834 5    0x109cd7067 postgres ExecHashTableInsert + 0x357
    1835 6    0x109cd68e1 postgres MultiExecHash + 0x141
    1836 7    0x109caa997 postgres MultiExecProcNode + 0x367
    1837 8    0x109cda95b postgres ExecHashJoin + 0x28b
    1838 9    0x109caa2a0 postgres ExecProcNode + 0x530
    1839 10   0x109ccdac3 postgres agg_retrieve_direct + 0x223
    1840 11   0x109ccd2e9 postgres ExecAgg + 0x2d9
    1841 12   0x109caa2df postgres ExecProcNode + 0x56f
    1842 13   0x109cf9efb postgres execMotionSender + 0x14b
    1843 14   0x109cf8f3e postgres ExecMotion + 0x1ce
    1844 15   0x109caa348 postgres ExecProcNode + 0x5d8
    1845 16   0x109c9c003 postgres ExecutePlan + 0x193
    1846 17   0x109c9bbed postgres ExecutorRun + 0x43d
    1847 18   0x109f336e2 postgres PortalRunSelect + 0x152
    1848 19   0x109f3323a postgres PortalRun + 0x30a
    1849 20   0x109f2cf3e postgres exec_mpp_query + 0x11ee
    1850 21   0x109f2a48c postgres PostgresMain + 0x166c
    1851 22   0x109e9e6f7 postgres BackendRun + 0x2f7
    1852 23   0x109e9dae2 postgres BackendStartup + 0x192
    1853 24   0x109e98d04 postgres ServerLoop + 0x554
    1854 25   0x109e96e5f postgres PostmasterMain + 0x155f
    1855 26   0x109d6d0e6 postgres main + 0x346
    1856 27   0x7fff886fb5fd libdyld.dylib start + 0x1
    1857 "
    1858 2016-06-17 17:44:35.517709 CST,"metro","zlib",p70533,th1945256720,"127.0.0.1","53731",2016-06-17 17:43:50 CST,697,con18,cmd11,seg0,slice2,,x697,sx1,"ERROR","58030","could not close temporary file base/16384/pgsql_tmp/workfile_set_HashJoin_Slice2.AAeOcZ5KV0/spillfile_f1: No such file or directory",,,,,,,0,,"bfz.c",442,
    1859 2016-06-17 17:44:35.523877 CST,,,p67175,th1945256720,,,,0,,,seg-1,,,,,"LOG","00000","3rd party error log:
    1860  --
    1861 Warning: /usr/bin/atos is moving and will be removed from a future OS X release.
    1862 It is now available in the Xcode developer tools to be invoked via: `xcrun atos`
    1863 To silence this warning, pass the '-d' command-line flag to this tool.
    1864  --",,,,,,,,"SysLoggerMain","syslogger.c",618,
    1865 2016-06-17 17:44:35.525388 CST,"metro","zlib",p70533,th1945256720,"127.0.0.1","53731",2016-06-17 17:43:50 CST,697,con18,cmd11,seg0,slice2,,x697,sx1,"FATAL","XX000","Unexpected internal error (procarray.c:284)","FailedAssertion(""!(((proc->xid) != ((TransactionId) 0)) || (((bool)(Mode == BootstrapProcessing)) && latestXid == ((TransactionId) 1)))"", File: ""procarray.c"", Line: 284)","Process 70533 will wait for gp_debug_linger=120 seconds      before termination.
    1866 Note that its locks and other resources will not be released until then.",,,,,0,,"procarray.c",284,"Stack trace:
    1867 1    0x10a0c0a0e postgres errstart + 0x5ee
    1868 2    0x10a0bef37 postgres ExceptionalCondition + 0x37
    1869 3    0x109efe916 postgres ProcArrayEndTransaction + 0xd6
    1870 4    0x109a21eb6 postgres AbortTransaction + 0x3d6
    1871 5    0x109a24307 postgres AbortCurrentTransaction + 0x87
    1872 6    0x109f29780 postgres PostgresMain + 0x960
    1873 7    0x109e9e6f7 postgres BackendRun + 0x2f7
    1874 8    0x109e9dae2 postgres BackendStartup + 0x192
    1875 9    0x109e98d04 postgres ServerLoop + 0x554
    1876 10   0x109e96e5f postgres PostmasterMain + 0x155f
    1877 11   0x109d6d0e6 postgres main + 0x346
    1878 12   0x7fff886fb5fd libdyld.dylib start + 0x1
    ...
    2642 2016-06-17 17:46:36.028746 CST,,,p67173,th1945256720,,,,0,,,seg-1,,,,,"LOG","00000","server process (PID 70533) was terminated by signal 6: Abort trap",,,,,,,0,,"postmaster.c",5639,
    2643 2016-06-17 17:46:36.028776 CST,,,p67173,th1945256720,,,,0,,,seg-1,,,,,"LOG","00000","terminating any other active server processes",,,,,,,0,,"postmaster.c",5319,
    2644 2016-06-17 17:46:36.029591 CST,,,p67173,th1945256720,,,,0,,,seg-1,,,,,"LOG","00000","sweeper process (PID 67190) exited with exit code 2",,,,,,,0,,"postmaster.c",5619,
    2645 2016-06-17 17:47:28.852214 CST,,,p71548,th1945256720,"127.0.0.1","53766",2016-06-17 17:47:28 CST,0,,,seg-1,,,,,"LOG","00000","received transition request packet. processing the request",,,,,,,0,,"postmaster.c",2710,
    2646 2016-06-17 17:47:28.852949 CST,,,p71548,th1945256720,"127.0.0.1","53766",2016-06-17 17:47:28 CST,0,,,seg-1,,,,,"LOG","00000","fault removed, fault name:'workfile_creation_failure' fault type:'error'",,,,,,,0,,"faultinject     or.c",941,
    2647 2016-06-17 17:47:33.677687 CST,,,p71560,th1945256720,"127.0.0.1","53768",2016-06-17 17:47:33 CST,0,,,seg-1,,,,,"LOG","00000","received transition request packet. processing the request",,,,,,,0,,"postmaster.c",2710,
    2648 2016-06-17 17:47:43.650720 CST,"metro","zlib",p71561,th1945256720,"127.0.0.1","53769",2016-06-17 17:47:43 CST,0,con25,,seg0,,,,,"FATAL","57P03","the database system is in recovery mode",,,,,,,0,,"postmaster.c",2967,
    2649 2016-06-17 17:48:06.051734 CST,"metro","zlib",p71838,th1945256720,"127.0.0.1","53773",2016-06-17 17:48:06 CST,0,con31,,seg0,,,,,"FATAL","57P03","the database system is in recovery mode",,,,,,,0,,"postmaster.c",2967,
    2650 2016-06-17 17:48:14.409190 CST,"metro","zlib",p71841,th1945256720,"127.0.0.1","53776",2016-06-17 17:48:14 CST,0,con32,,seg0,,,,,"FATAL","57P03","the database system is in recovery mode",,,,,,,0,,"postmaster.c",2967,
    2651 2016-06-17 17:48:15.410467 CST,"metro","zlib",p71844,th1945256720,"127.0.0.1","53779",2016-06-17 17:48:15 CST,0,con33,,seg0,,,,,"FATAL","57P03","the database system is in recovery mode",,,,,,,0,,"postmaster.c",2967,
    2652 2016-06-17 17:49:16.206196 CST,"metro","zlib",p71851,th1945256720,"127.0.0.1","53789",2016-06-17 17:49:16 CST,0,con34,,seg0,,,,,"FATAL","57P03","the database system is in recovery mode",,,,,,,0,,"postmaster.c",2967,
    2653 2016-06-17 17:49:19.522503 CST,"metro","zlib",p71989,th1945256720,"127.0.0.1","53792",2016-06-17 17:49:19 CST,0,con36,,seg0,,,,,"FATAL","57P03","the database system is in recovery mode",,,,,,,0,,"postmaster.c",2967,
    2654 2016-06-17 17:50:17.040601 CST,"metro","zlib",p72672,th1945256720,"[local]",,2016-06-17 17:50:17 CST,0,,,seg-1,,,,,"FATAL","57P03","the database system is in recovery mode",,,,,,,0,,"postmaster.c",2967,
    2655 2016-06-17 17:52:21.139124 CST,,,p71396,th1945256720,,,,0,,,seg-1,,,,,"LOG","00000","could not signal bgwriter for checkpoint close all: No such process",,,,,,,0,,"bgwriter.c",563,
    2656 2016-06-17 17:56:36.321643 CST,,,p71396,th1945256720,,,,0,,,seg-1,,,,,"LOG","00000","could not signal bgwriter for checkpoint close all: No such process",,,,,,,0,,"bgwriter.c",563,
    2657 2016-06-17 18:01:36.603644 CST,,,p71396,th1945256720,,,,0,,,seg-1,,,,,"LOG","00000","could not signal bgwriter for checkpoint close all: No such process",,,,,,,0,,"bgwriter.c",563,
    2658 2016-06-17 18:06:36.885883 CST,,,p71396,th1945256720,,,,0,,,seg-1,,,,,"LOG","00000","could not signal bgwriter for checkpoint close all: No such process",,,,,,,0,,"bgwriter.c",563,
    2659 2016-06-17 20:08:05.661581 CST,,,p71396,th1945256720,,,,0,,,seg-1,,,,,"LOG","00000","could not signal bgwriter for checkpoint close all: No such process",,,,,,,0,,"bgwriter.c",563,
    2660 2016-06-17 21:08:13.048019 CST,,,p71396,th1945256720,,,,0,,,seg-1,,,,,"LOG","00000","could not signal bgwriter for checkpoint close all: No such process",,,,,,,0,,"bgwriter.c",563,
    2661 2016-06-17 23:09:01.558980 CST,,,p71396,th1945256720,,,,0,,,seg-1,,,,,"LOG","00000","could not signal bgwriter for checkpoint close all: No such process",,,,,,,0,,"bgwriter.c",563,

master log:

    276 2016-06-17 17:44:35.446153 CST,"metro","zlib",p70532,th1945256720,"[local]",,2016-06-17 17:43:40 CST,712,con18,cmd10,seg-1,,dx18,x712,sx1,"LOG","00000","statement: SELECT COUNT(t1.*) FROM test_zlib_hashjoin AS t1, test_zli    b_hashjoin AS t2 WHERE t1.i1=t2.i2;",,,,,,"SELECT COUNT(t1.*) FROM test_zlib_hashjoin AS t1, test_zlib_hashjoin AS t2 WHERE t1.i1=t2.i2;",0,,"postgres.c",1616,
    277 2016-06-17 17:44:35.525603 CST,"metro","zlib",p70532,th379887616,"[local]",,2016-06-17 17:43:40 CST,712,con18,cmd11,seg-1,,dx18,x712,sx1,"LOG","00000","Dispatcher encountered connection error on seg0 slice2 127.0.0.1:25432     pid=70533: server closed the connection unexpectedly
    278     This probably means the server terminated abnormally
    279     before or while processing the request.
    280 ",,,,,,,0,,,,
    281 2016-06-17 17:44:37.554142 CST,"metro","zlib",p70532,th1945256720,"[local]",,2016-06-17 17:43:40 CST,712,con18,cmd11,seg-1,,dx18,x712,sx1,"ERROR","XX000","fault triggered, fault name:'workfile_creation_failure' fault type:    'error' (faultinjector.c:675)  (seg0 slice2 127.0.0.1:25432 pid=70533)",,,,,,"SELECT COUNT(t1.*) FROM test_zlib_hashjoin AS t1, test_zlib_hashjoin AS t2 WHERE t1.i1=t2.i2;",0,,"cdbdisp.c",215,
    282 2016-06-17 17:44:37.559760 CST,,,p67213,th1945256720,,,,0,,,seg-1,,,,,"LOG","00000","3rd party error log:
    283  --
    284 Warning: /usr/bin/atos is moving and will be removed from a future OS X release.
    285 It is now available in the Xcode developer tools to be invoked via: `xcrun atos`
    286 To silence this warning, pass the '-d' command-line flag to this tool.
    287  --",,,,,,,,"SysLoggerMain","syslogger.c",618,
    288 2016-06-17 17:44:37.562870 CST,"metro","zlib",p70532,th1945256720,"[local]",,2016-06-17 17:43:40 CST,712,con18,cmd11,seg-1,,dx18,x712,sx1,"ERROR","XX000","could not temporarily connect to one or more segments (cdbgang.c:18    91)",,,,,,,0,,"cdbgang.c",1891,"Stack trace:
    289 1    0x10941ea0e postgres errstart + 0x5ee
    290 2    0x109422fa8 postgres elog_finish + 0x228
    291 3    0x10954c2ca postgres freeGangsForPortal + 0xaa
    292 4    0x1090248a4 postgres ReleaseGangs + 0x64
    293 5    0x108ffab38 postgres ExecutorEnd + 0x418
    294 6    0x108f70580 postgres PortalCleanupHelper + 0x60
    295 7    0x108f7042d postgres PortalCleanup + 0x10d
    296 8    0x10947498f postgres AtAbort_Portals + 0x8f
    297 9    0x108d7fc9e postgres AbortTransaction + 0x1be
    298 10   0x108d82307 postgres AbortCurrentTransaction + 0x87
    299 11   0x109287780 postgres PostgresMain + 0x960
    300 12   0x1091fc6f7 postgres BackendRun + 0x2f7
    301 13   0x1091fbae2 postgres BackendStartup + 0x192
    302 14   0x1091f6d04 postgres ServerLoop + 0x554
    303 15   0x1091f4e5f postgres PostmasterMain + 0x155f
    304 16   0x1090cb0e6 postgres main + 0x346
    305 17   0x7fff886fb5fd libdyld.dylib start + 0x1
    306 "
    307 2016-06-17 17:44:37.563190 CST,"metro","zlib",p70532,th1945256720,"[local]",,2016-06-17 17:43:40 CST,0,con22,,seg-1,,,,,"LOG","00000","The previous session was reset because its gang was disconnected (session id = 18). The     new session id = 22",,,,,,,0,,"cdbgang.c",2021

## one segment is in recovery mode

    ± |master ✗| → PGOPTIONS='-c gp_session_role=utility' psql -p 25432 postgres
    psql: FATAL:  the database system is in recovery mode

## ok, let us take a look at segment behavior

call stack in fault injector

    #0  FaultInjector_InjectFaultIfSet (identifier=WorkfileCreationFail, ddlStatement=DDLNotSpecified,
        databaseName=0x10fa320f5 "", tableName=0x10fa320f5 "") at faultinjector.c:672
    #1  0x000000010f8d9b74 in workfile_mgr_create_fileno (work_set=0x11c99cc98, file_no=1) at workfile_file.c:58
    #2  0x000000010f44e2e5 in ExecHashJoinSaveTuple (ps=0x7ffb508d7f28, tuple=0x7ffb51034fa8, hashvalue=586724666,
        hashtable=0x7ffb51033108, batchside=0x7ffb51046650, bfCxt=0x7ffb51041d78) at nodeHashjoin.c:1014
    #3  0x000000010f449d17 in ExecHashTableInsert (hashState=0x7ffb508d7f28, hashtable=0x7ffb51033108,
        slot=0x7ffb508d92a8, hashvalue=586724666) at nodeHash.c:991
    #4  0x000000010f449591 in MultiExecHash (node=0x7ffb508d7f28) at nodeHash.c:142
    #5  0x000000010f41d647 in MultiExecProcNode (node=0x7ffb508d7f28) at execProcnode.c:1262
    #6  0x000000010f44d60b in ExecHashJoin (node=0x7ffb508b8398) at nodeHashjoin.c:201
    #7  0x000000010f41cf50 in ExecProcNode (node=0x7ffb508b8398) at execProcnode.c:963
    #8  0x000000010f440773 in agg_retrieve_direct (aggstate=0x7ffb508b6fe0) at nodeAgg.c:1225
    #9  0x000000010f43ff99 in ExecAgg (node=0x7ffb508b6fe0) at nodeAgg.c:1102
    #10 0x000000010f41cf8f in ExecProcNode (node=0x7ffb508b6fe0) at execProcnode.c:975
    #11 0x000000010f46cbab in execMotionSender (node=0x7ffb508b6420) at nodeMotion.c:356
    #12 0x000000010f46bbee in ExecMotion (node=0x7ffb508b6420) at nodeMotion.c:323
    #13 0x000000010f41cff8 in ExecProcNode (node=0x7ffb508b6420) at execProcnode.c:995
    #14 0x000000010f40ecb3 in ExecutePlan (estate=0x7ffb508b2e60, planstate=0x7ffb508b6420, operation=CMD_SELECT,
        numberTuples=0, direction=ForwardScanDirection, dest=0x7ffb510096a0) at execMain.c:2809
    #15 0x000000010f40e89d in ExecutorRun (queryDesc=0x7ffb50825190, direction=ForwardScanDirection, count=0)

code where ERROR out:

       │659                     case FaultInjectorTypeError:                                                       │
       │660                             /*                                                                         │
       │661                              * If it's one time occurrence then disable the fault before it's          │
       │662                              * actually triggered because this fault errors out the transaction        │
       │663                              * and hence we wont get a chance to disable it or put it in completed     │
       │664                              * state.                                                                  │
       │665                              */                                                                        │
       │666                             if (entryLocal->occurrence != FILEREP_UNDEFINED)                           │
       │667                             {                                                                          │
       │668                                     entryLocal->faultInjectorState = FaultInjectorStateCompleted;      │
       │669                                     FaultInjector_UpdateHashEntry(entryLocal);                         │
       │670                             }                                                                          │
       │671                                                                                                        │
      >│672                             ereport(ERROR,                                                             │
       │673                                             (errmsg("fault triggered, fault name:'%s' fault type:'%s' "│
       │674                                                             FaultInjectorIdentifierEnumToString[entryLo│
       │675                                                             FaultInjectorTypeEnumToString[entryLocal->f│
       │676                             break;


ereport(ERROR)

    errstart: prepare error data in error stack:

        (gdb) p *edata
        $26 = {elevel = 20, output_to_server = 1 '\001', output_to_client = 1 '\001', show_funcname = 0 '\000',
          omit_location = 0 '\000', fatal_return = 0 '\000', send_alert = 0 '\000', hide_stmt = 0 '\000',
          filename = 0x10faf9340 "faultinjector.c", lineno = 675,
          funcname = 0x10faf93a8 "FaultInjector_InjectFaultIfSet", domain = 0x10faa5af6 "postgres-8.3",
          sqlerrcode = 2600, message = 0x0, detail = 0x0, detail_log = 0x0, hint = 0x0, context = 0x0, cursorpos = 0,
          internalpos = 0, internalquery = 0x0, saved_errno = 17, stacktracearray = {0x10f83350e <errstart+1518>,
            0x10f871025 <FaultInjector_InjectFaultIfSet+1717>, 0x10f8d9b74 <workfile_mgr_create_fileno+212>,
            0x10f44e2e5 <ExecHashJoinSaveTuple+197>, 0x10f449d17 <ExecHashTableInsert+855>,
            0x10f449591 <MultiExecHash+321>, 0x10f41d647 <MultiExecProcNode+871>, 0x10f44d60b <ExecHashJoin+651>,
            0x10f41cf50 <ExecProcNode+1328>, 0x10f440773 <agg_retrieve_direct+547>, 0x10f43ff99 <ExecAgg+729>,
            0x10f41cf8f <ExecProcNode+1391>, 0x10f46cbab <execMotionSender+331>, 0x10f46bbee <ExecMotion+462>,
            0x10f41cff8 <ExecProcNode+1496>, 0x10f40ecb3 <ExecutePlan+403>, 0x10f40e89d <ExecutorRun+1085>,
            0x10f6a6342 <PortalRunSelect+338>, 0x10f6a5e9a <PortalRun+778>, 0x10f69fb9e <exec_mpp_query+4590>,
            0x10f69d0ec <PostgresMain+5740>, 0x10f611357 <BackendRun+759>, 0x10f610742 <BackendStartup+402>,
            0x10f60b964 <ServerLoop+1364>, 0x10f609abf <PostmasterMain+5471>, 0x10f4dfd96 <main+838>, 0x7fff886fb5fd,
            0x0, 0x0, 0x0}, stacktracesize = 27, printstack = 0 '\000'}

... gpdb crash when continue ....


So break in AbortCurrentTransaction

    (gdb) b AbortCurrentTransaction
    Breakpoint 1 at 0x10e786ee4: file xact.c, line 4617.
    (gdb) c
    Continuing.

    Breakpoint 1, AbortCurrentTransaction () at xact.c:4617
    4617		TransactionState s = CurrentTransactionState;
    (gdb) where
    #0  AbortCurrentTransaction () at xact.c:4617
    #1  0x000000010ec8c3e0 in PostgresMain (argc=1, argv=0x7fbe3b002db8, dbname=0x7fbe3b002d20 "zlib",
        username=0x7fbe3b002ce0 "metro") at postgres.c:4743
    #2  0x000000010ec01357 in BackendRun (port=0x7fbe39c0d480) at postmaster.c:6716
    #3  0x000000010ec00742 in BackendStartup (port=0x7fbe39c0d480) at postmaster.c:6403
    #4  0x000000010ebfb964 in ServerLoop () at postmaster.c:2458
    #5  0x000000010ebf9abf in PostmasterMain (argc=15, argv=0x7fbe39c09290) at postmaster.c:1537
    #6  0x000000010eacfd96 in main (argc=15, argv=0x7fbe39c09290) at main.c:206
    (gdb) p MyProc->xid
    $1 = 724

So PostgresMain will catch exception and execute longjump code:

    if (sigsetjmp(local_sigjmp_buf, 1) != 0)
    {
        EmitErrorReport();

        /*
         * Make sure debug_query_string gets reset before we possibly clobber
         * the storage it points at.
         */
        debug_query_string = NULL;

        /* No active snapshot any more either */
        ActiveSnapshot = NULL;

        /*
         * Abort the current transaction in order to recover.
         */
        AbortCurrentTransaction();

        if (am_walsender)
            WalSndErrorCleanup();

        ...
    }

Watch MyProc->xid:

    (gdb) b AbortTransaction
    Breakpoint 1 at 0x105e6075b: file xact.c, line 3973.
    (gdb) c
    Continuing.

    Breakpoint 1, AbortTransaction () at xact.c:3973
    3973		MIRRORED_LOCK_DECLARE;
    (gdb) p MyProc->xid
    $1 = 732
    (gdb) p &MyProc->xid
    $2 = (TransactionId *) 0x111e7ee94
    (gdb) watch *(TransactionId *) 0x111e7ee94
    Hardware watchpoint 2: *(TransactionId *) 0x111e7ee94
    (gdb) c
    Continuing.
    Hardware watchpoint 2: *(TransactionId *) 0x111e7ee94

    Old value = 732
    New value = 0
    ProcArrayEndTransaction (proc=0x111e7ee68, latestXid=732, isCommit=0 '\000',
        needStateChangeFromDistributed=0x0, needNotifyCommittedDtxTransaction=0x0,
        localDistribXactRef=0x7fff59e45080) at procarray.c:346
    346				proc->lxid = InvalidLocalTransactionId;
    (gdb) where
    #0  ProcArrayEndTransaction (proc=0x111e7ee68, latestXid=732, isCommit=0 '\000',
        needStateChangeFromDistributed=0x0, needNotifyCommittedDtxTransaction=0x0,
        localDistribXactRef=0x7fff59e45080) at procarray.c:346
    #1  0x0000000105e60b16 in AbortTransaction () at xact.c:4118
    #2  0x0000000105e62f67 in AbortCurrentTransaction () at xact.c:4647
    #3  0x00000001063683e0 in PostgresMain (argc=1, argv=0x7ffde9040bb8, dbname=0x7ffde9040b20 "zlib",
        username=0x7ffde9040ae0 "metro") at postgres.c:4743
    #4  0x00000001062dd357 in BackendRun (port=0x7ffde8e00330) at postmaster.c:6716
    #5  0x00000001062dc742 in BackendStartup (port=0x7ffde8e00330) at postmaster.c:6403
    #6  0x00000001062d7964 in ServerLoop () at postmaster.c:2458
    #7  0x00000001062d5abf in PostmasterMain (argc=15, argv=0x7ffde8c09ec0) at postmaster.c:1537
    #8  0x00000001061abd96 in main (argc=15, argv=0x7ffde8c09ec0) at main.c:206


     68 2016-06-21 11:42:25.500364 CST,"metro","zlib",p60959,th1945256720,"127.0.0.1","59025",2016-06-21 11:36:06 CST,738,con6,cmd7,seg0,slice2,,x738,sx1,"FATAL","XX000","Unexpected internal error (procarray.c:284)","FailedAssertion(""!(((proc->xid) != ((TransactionId) 0)) || (((bool)(Mode == BootstrapProcessing)) && latestXid == ((TransactionId) 1)))"", File: ""procarray.c"", Line: 284)","Process 60959 will wait for gp_debug_linger=120 seconds bef    ore termination.
     69 Note that its locks and other resources will not be released until then.",,,,,0,,"procarray.c",284,"Stack trace:
     70 1    0x104ced50e postgres errstart + 0x5ee
     71 2    0x104ceba37 postgres ExceptionalCondition + 0x37
     72 3    0x104b2b576 postgres ProcArrayEndTransaction + 0xd6
     73 4    0x10464eb16 postgres AbortTransaction + 0x3d6
     74 5    0x104650f67 postgres AbortCurrentTransaction + 0x87
     75 6    0x104b563e0 postgres PostgresMain + 0x960
     76 7    0x104acb357 postgres BackendRun + 0x2f7
     77 8    0x104aca742 postgres BackendStartup + 0x192
     78 9    0x104ac5964 postgres ServerLoop + 0x554
     79 10   0x104ac3abf postgres PostmasterMain + 0x155f
     80 11   0x104999d96 postgres main + 0x346
     81 12   0x7fff886fb5fd libdyld.dylib start + 0x1


---

     (gdb) b AbortCurrentTransaction
     Breakpoint 1 at 0x1008b3ee4: file xact.c, line 4617.
     (gdb) c
     Continuing.

     Breakpoint 1, AbortCurrentTransaction () at xact.c:4617
     4617		TransactionState s = CurrentTransactionState;
     (gdb) b procarray.c:283
     Breakpoint 2 at 0x100d8e4f7: file procarray.c, line 283.
     (gdb) b procarray.c:284
     Breakpoint 3 at 0x100d8e588: file procarray.c, line 284.
     (gdb) p MyProc->xid
     $1 = 744
     (gdb) p &MyProc->xid
     $2 = (TransactionId *) 0x10c8cfe94
     (gdb) watch *(TransactionId *) 0x10c8cfe94
     Hardware watchpoint 4: *(TransactionId *) 0x10c8cfe94
     (gdb) c
     Continuing.

     Breakpoint 2, ProcArrayEndTransaction (proc=0x10c8cfe68, latestXid=744, isCommit=0 '\000',
         needStateChangeFromDistributed=0x0, needNotifyCommittedDtxTransaction=0x0,
         localDistribXactRef=0x7fff5f3f4080) at procarray.c:283
     283			Assert(TransactionIdIsValid(proc->xid) ||
     (gdb) p proc->xid
     $3 = 744
     (gdb) where
     #0  ProcArrayEndTransaction (proc=0x10c8cfe68, latestXid=744, isCommit=0 '\000',
         needStateChangeFromDistributed=0x0, needNotifyCommittedDtxTransaction=0x0,
         localDistribXactRef=0x7fff5f3f4080) at procarray.c:283
     #1  0x00000001008b1b16 in AbortTransaction () at xact.c:4118
     #2  0x00000001008b3f67 in AbortCurrentTransaction () at xact.c:4647
     #3  0x0000000100db93e0 in PostgresMain (argc=1, argv=0x7f8ac20187b8, dbname=0x7f8ac2018720 "zlib",
         username=0x7f8ac20186e0 "metro") at postgres.c:4743
     #4  0x0000000100d2e357 in BackendRun (port=0x7f8ac0602b80) at postmaster.c:6716
     #5  0x0000000100d2d742 in BackendStartup (port=0x7f8ac0602b80) at postmaster.c:6403
     #6  0x0000000100d28964 in ServerLoop () at postmaster.c:2458
     #7  0x0000000100d26abf in PostmasterMain (argc=15, argv=0x7f8ac0702560) at postmaster.c:1537
     #8  0x0000000100bfcd96 in main (argc=15, argv=0x7f8ac0702560) at main.c:206

---
     (gdb) p errordata
     $13 = {{
         elevel = 20,
         output_to_server = 1 '\001',
         output_to_client = 1 '\001',
         show_funcname = 0 '\000',
         omit_location = 0 '\000',
         fatal_return = 0 '\000',
         send_alert = 0 '\000',
         hide_stmt = 0 '\000',
         filename = 0x101216340 "faultinjector.c",
         lineno = 675,
         funcname = 0x1012163a8 "FaultInjector_InjectFaultIfSet",
         domain = 0x1011c2af6 "postgres-8.3",
         sqlerrcode = 2600,
         message = 0x7f8ac181e608 "fault triggered, fault name:'workfile_creation_failure' fault type:'error' (faultinjector.c:675)",
         detail = 0x0,
         detail_log = 0x0,
         hint = 0x0,
         context = 0x0,
         cursorpos = 0,
         internalpos = 0,
         internalquery = 0x0,
         saved_errno = 17,
         stacktracearray = {0x100f5050e <errstart+1518>, 0x100f8e025 <FaultInjector_InjectFaultIfSet+1717>,
           0x100ff6b74 <workfile_mgr_create_fileno+212>, 0x100b6b2e5 <ExecHashJoinSaveTuple+197>,
           0x100b66d17 <ExecHashTableInsert+855>, 0x100b66591 <MultiExecHash+321>,
           0x100b3a647 <MultiExecProcNode+871>, 0x100b6a60b <ExecHashJoin+651>, 0x100b39f50 <ExecProcNode+1328>,
           0x100b5d773 <agg_retrieve_direct+547>, 0x100b5cf99 <ExecAgg+729>, 0x100b39f8f <ExecProcNode+1391>,
           0x100b89bab <execMotionSender+331>, 0x100b88bee <ExecMotion+462>, 0x100b39ff8 <ExecProcNode+1496>,
           0x100b2bcb3 <ExecutePlan+403>, 0x100b2b89d <ExecutorRun+1085>, 0x100dc3342 <PortalRunSelect+338>,
           0x100dc2e9a <PortalRun+778>, 0x100dbcb9e <exec_mpp_query+4590>, 0x100dba0ec <PostgresMain+5740>,
           0x100d2e357 <BackendRun+759>, 0x100d2d742 <BackendStartup+402>, 0x100d28964 <ServerLoop+1364>,
           0x100d26abf <PostmasterMain+5471>, 0x100bfcd96 <main+838>, 0x7fff886fb5fd, 0x0, 0x0, 0x0},
         stacktracesize = 27,
         printstack = 0 '\000'
       }, {
         elevel = 20,
         output_to_server = 1 '\001',
         output_to_client = 1 '\001',
         show_funcname = 0 '\000',
         omit_location = 1 '\001',
         fatal_return = 0 '\000',
         send_alert = 0 '\000',
         hide_stmt = 0 '\000',
         filename = 0x1011e5668 "bfz.c",
         lineno = 442,
         funcname = 0x1011e56a7 "bfz_close",
         domain = 0x1011c2af6 "postgres-8.3",
         sqlerrcode = 786949,
         message = 0x7f8ac181e418 "could not close temporary file base/16384/pgsql_tmp/workfile_set_HashJoin_Slice2.R5K0XqA4t7/spillfile_f1: No such file or directory",
         detail = 0x0,
         detail_log = 0x0,
         hint = 0x0,
         context = 0x0,
         cursorpos = 0,
         internalpos = 0,
         internalquery = 0x0,
         saved_errno = 2,
         stacktracearray = {0x100f5050e <errstart+1518>, 0x100d866f9 <bfz_close+313>,
           0x100d867c2 <bfz_close_callback+34>, 0x1008b15b9 <CallXactCallbacksOnce+153>,
           0x1008b1b3e <AbortTransaction+1022>, 0x1008b3f67 <AbortCurrentTransaction+135>,
             0x100db93e0 <PostgresMain+2400>, 0x100d2e357 <BackendRun+759>, 0x100d2d742 <BackendStartup+402>,
             0x100d28964 <ServerLoop+1364>, 0x100d26abf <PostmasterMain+5471>, 0x100bfcd96 <main+838>,
             0x7fff886fb5fd, 0x0 <repeats 17 times>},
           stacktracesize = 13,
           printstack = 0 '\000'
         }