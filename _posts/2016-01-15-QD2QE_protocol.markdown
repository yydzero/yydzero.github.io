==> From psql to QD, the libpq protocol for the client is located under
	src/interfaces/libpq/, the protocol for the server side is under
	src/backend/libpq/; while from QD to QE, QD would act as a client, but it
	does not use the src/interfaces/libpq protocol directly, but use a modified
	counterpart which is under src/backend/gp_libpq_fe/;

==> Dispatch thread mostly follows the third protocol mentioned above, i.e,
	src/backend/gp_libpq_fe/ part, however, for NOTICE and WARNING raised from
	QE, dispatch thread uses the second protocol to send it back to psql
	directly, and that is why we need a pthread mutex to protect the sending;

	The stacktrace of the NOTICE raising mechanism is like:
	#0  pq_putmessage (msgtype=78 'N', s=0xfa64170 "SNOTICE", len=89) at
		pqcomm.c:1444
	#1  0x0000000000a9d817 in MPPnoticeReceiver (arg=0xfa547c8, res=0xfa64060) at
		cdbconn.c:216
	#2  0x0000000000784830 in pqGetErrorNotice3 (conn=0xfb03f00, isError=0 '\000')
		at fe-protocol3.c:1143
	#3  0x0000000000782c0e in pqParseInput3 (conn=0xfb03f00) at fe-protocol3.c:165
	#4  0x0000000000777106 in parseInput (conn=0xfb03f00) at fe-exec.c:1987
	#5  0x000000000077712e in PQisBusy (conn=0xfb03f00) at fe-exec.c:2002
	#6  0x0000000000aa8486 in processResults (dispatchResult=0x2af73c011bb0) at
		cdbdisp.c:2855
	#7  0x0000000000aa70a8 in thread_DispatchWait (pParms=0xfba5ee8) at
		cdbdisp.c:2108
	#8  0x0000000000aa7626 in thread_DispatchCommand (arg=0xfba5ee8) at
		cdbdisp.c:2346
	#9  0x000000332dc0683d in start_thread () from /lib64/libpthread.so.0
	#10 0x000000332ccd514d in clone () from /lib64/libc.so.6
