==> One tricky thing here in resqueue.c:1338 is:
	over commit is for the per process perspective, if this process has only one
	portal running, and the cost exceeds the limit, then it is OK to over
	commit; these is no considering for other processes, since PortalHashTable
	is process native;

==> XXX ResLockUpdateLimit has an unused parameter inError;

==> In ResLockPortal's catch code path for ResLockAcquire, it would call
	ResLockWaitCancel and ResLockRelease; different from LockWaitCancel,
	ResLockWaitCancel does not call GrantAwaitedLock to update the locallock if
	we have been granted the lock and then was interrupted; XXX then how does we
	handle this case?

==> ResCheckSelfDeadLock is very tricky, when it detects that it is going to
	cause a self deadlock, it calls ResGrantLock and ResLockUpdateLimit, and
	then ereport ERROR, to jump to ResLockPortal's catch code for cleanup.
	Several questions:
	--> XXX ResLockUpdateLimit would enforce the current value to be 0.0 if
	negative, then in ResLockRelease later, it is supposed to add back the
	current value, then it is wrong state now;
	--> XXX after ResLockUpdateLimit, if another session wants to acquire the
	resource lock(cost based), and it is supposed to be able to get it if the
	deadlock one is not granted, so it would be inserted into the waitProc list
	now, though ResLockRelease would wake up one process, it is a delay here;

==> ResLockAcquire does not update LOCALLOCK at all after acquiring the lock;
	should we remove LOCALLOCK for resource lock? not necessary, some routines
	use the LOCALLOCK, such as ResLockWaitCancel;

==> XXX ResLockAcquire's error cleanup is messy, verify whether it is solid. What
	does ResLockRelease do in catch block? several resources needed to be
	cleaned up:
	--> LWLock
	--> LOCK/PROCLOCK
	--> ResPortalIncrement

==> TODO: Change PGSemaphoreLock in ResProcSleep to be consistent with ProcSleep, and
	ResLockWaitCancel PGSemaphoreReset correspondingly;
