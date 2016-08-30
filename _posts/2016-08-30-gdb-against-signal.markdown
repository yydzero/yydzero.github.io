---
layout: post
title:  "GDB against signal"
subtitle:  "GDB中处理signal"
author: 刘奎恩/Kuien, Haozhou Wang
date:   2016-08-30 17:58 +0800
categories: gdb
published: true
---

When we want to debug signal within GDB, but the signal will be handle by GDB itself, that is, signals will not be passed to program.

**Solution/Example**

__in bash__:

	gdb --args gpcheckcloud -u /tmp/data "s3://s3-us-west-2.amazonaws.com/s3write.pivotal.io/s3write/gpcheckcloud/ config=/home/gpadmin/s3.conf"


__in GDB__:

	handle SIGINT nostop pass
		the signal will be passed to program 
	run
		run the program to be debugged
	^C (CTRL-C)
		interrupt the running program
	handle SIGINT stop nopass
		return signal process right to GDB, otherwise it is lost control

**Print signal name in C/C++**

Following is an example to print signal name friendly within C/C++

```c
	// More friendly than strsignal (string.h) and sys_signame (signal.h)
	const char *signame[] = {"INVALID", "SIGHUP",  "SIGINT",    "SIGQUIT", "SIGILL",    "SIGTRAP",
	                         "SIGABRT", "SIGBUS",  "SIGFPE",    "SIGKILL", "SIGUSR1",   "SIGSEGV",
	                         "SIGUSR2", "SIGPIPE", "SIGALRM",   "SIGTERM", "SIGSTKFLT", "SIGCHLD",
	                         "SIGCONT", "SIGSTOP", "SIGTSTP",   "SIGTTIN", "SIGTTOU",   "SIGURG",
	                         "SIGXCPU", "SIGXFSZ", "SIGVTALRM", "SIGPROF", "SIGWINCH",  "SIGPOLL",
	                         "SIGPWR",  "SIGSYS",  NULL};
	
	static void handleAbortSignal(int signum) {
	    //  Defensive code
	    int validSigNum = signum >= sizeof(signame) / sizeof(char *) ? 0 : signum;
	
	    fprintf(stderr, "\n");
	    fprintf(stderr, "Interrupted by user with %s, exiting...\n\n", signame[validSigNum]);
	    QueryCancelPending = true;
	}
	
	void registerSignalHandler() {
	    signal(SIGABRT, handleAbortSignal);
	    signal(SIGTERM, handleAbortSignal);
	    signal(SIGINT, handleAbortSignal);
	    signal(SIGTSTP, handleAbortSignal);
	}
```
