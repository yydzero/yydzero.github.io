## Postmaster Reset
* there are several critical functions in postmaster reset procedure:
	* do_reaper: workhorse for signal SIGCHLD, the handler of SIGCHLD is reaper, reaper would only set some flags and do_reaper handles the heavy-lifting; in PG, there is no do_reaper, reaper would do all things;
	* HandleChildCrash: once postmaster detects the exit of child processes, it would check the identity of the processes and their exit status, which is done in do_reaper, and if it believes the process exited is critical enough or the exit status is "bad", it would treat it as serious problem and call HandleChildCrash to notify almost all child processes to exit;
	* ServerLoop: main loop of postmaster; the loop is simple:
	
			|->	=> unblock signal
			|	=> select
			|	=> block signal
			|	=> check sigusr1
			^	=> do_reaper
			|	=> fork backend ---
			|____________________|
	* sigusr1_handler: handler of SIGUSR1 for postmaster, check the reasons and set corresponding flags;

* Master postmaster reset:
	* if a backend is killed by SIGKILL or SIGSEGV or reports PANIC, then postmaster would receive signal SIGCHLD, reaper would set flag to indicate some child processes die, so in the main loop, do_reaper would be called to check the exit status and do "reapering"(call waitpid indeed to avoid zombie processes); do_reaper would first check if the exited process is critical auxiliary processes, finally it would call CleanupBackend for normal backend, and find the abnormal exit status, so it would call HandleChildCrash to terminate all other processes, and mark the FatalError to be true; then in do_reaper, after reapering all processes, if it find FatalError true, it would call funtions to reset share memory and restart auxiliary processes, however, before that, it has to ensure all other(almost, syslogger is an exception) processes are completely terminated(reapered), otherwise, if some processes are detected terminated during StartupProcess or some important process which cannot be interrupted, then StartupProcess would be terminated and postmaster treats it as recovery failure.

* Segment postmaster reset:
	* the steps are similar to master, except:
		* after the termination of primary sender process, the mirror receiver process would notice the broken connection, and send a SIGUSR1 to mirror postmaster with reason "filerep status change";
		* before reset share memory and restart auxiliary processes, primary postmaster would start a filerep peer reset process to instruct the reset of mirror postmaster; filerep peer reset process would first connect to mirror postmaster, and mirror postmaster would fork a new backend, that new backend would send a SIGUSR1 to mirror postmaster with reason "postmaster reset required", then filerep peer reset process would check the reset status of mirror every 10ms by connecting to mirror, each time, a new backend would be forked(once pmState is changed to PM_BEGIN_END, those new backend would be dead_end backend);
		* mirror postmaster receives SIGUSR1 with reason "postmaster reset required", and then call HandleChildCrash in the main loop, so it would notify all child processes to exit; then it works like master;
		* previously, there is a bug: there are concurrent spawning of dead_end backend from filerep peer reset and exit of those backends, so it is possible mirror postmaster can never proceed reset because there are always exiting child processes; the fix for this bug is to change the pmState to PM_CHILD_STOP_WAIT_DEAD_END_CHILDREN after other important child processes have exited, so mirror postmaster would not accept new connections anymore;
		* after mirror postmaster finishes reset, filerep peer reset process can get the success status from mirror postmaster, and then filerep peer reset process would exit; primary postmaster detects the success exit status of filerep peer reset and resume its reset procedure;