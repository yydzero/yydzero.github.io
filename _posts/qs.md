* first loop, process sigusr1 only, send sigquit to backend and mirror process;
* second loop, do_reaper, reaper mirror process and backend; why for FileRepPID,
	the exit status is not 0??

* special PIDs such as FileRepPID is set to 0 in two cases:
	* HandleChildCrash if the crashed process is the special process;
	* do_reaper when reaper the special processes;

	so once these PIDs are set zero, they are definitely gone;

* why WalSender special?
* BACKEND_TYPE_AUTOVAC and AutoVacPID?
* WalWriterPID in PostmasterStateMachine
