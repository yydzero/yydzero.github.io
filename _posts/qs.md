* first loop, process sigusr1 only, send sigquit to backend and mirror process;
* second loop, do_reaper, reaper mirror process and backend; why for FileRepPID,
	the exit status is not 0??
* Is reset peer process loop and connect to mirror postmaster for sending 
	sigusr1?

* Verify the hypothesis above.
* figure out the pm state machine and why BeginResetOfPostmasterAfterChildrenAreShutDown
	is not called

* special PIDs such as FileRepPID is set to 0 in two cases:
	* HandleChildCrash if the crashed process is the special process;
	* do_reaper when reaper the special processes;

	so once these PIDs are set zero, they are definitely gone;


Checkout why reset peer process is keeping connecting, backtrace is like:

#0  0x00007f5b49a41923 in __select_nocancel () from /lib64/libc.so.6
#1  0x00000000011851d6 in pg_usleep (microsec=10000) at pgsleep.c:43
#2  0x000000000101c0e7 in FileRepResetPeer_Main () at
cdbfilerepresetpeerprocess.c:316
#3  0x00000000006a1a82 in AuxiliaryProcessMain (argc=2, argv=0x7ffed75ff8e0) at
bootstrap.c:505
#4  0x0000000000bb1ebe in StartChildProcess (type=FilerepResetPeerProcess) at
postmaster.c:7773
#5  0x0000000000ba081a in BeginResetOfPostmasterAfterChildrenAreShutDown () at
postmaster.c:2224
#6  0x0000000000bab7c7 in do_reaper () at postmaster.c:5105
#7  0x0000000000ba12ee in ServerLoop () at postmaster.c:2432
#8  0x0000000000b9dfc0 in PostmasterMain (argc=15, argv=0x3d01430) at
postmaster.c:1537
#9  0x0000000000a0f304 in main (argc=15, argv=0x3d01430) at main.c:206


Once I gdb attach to the reset peer process, the mirror process is started up;
