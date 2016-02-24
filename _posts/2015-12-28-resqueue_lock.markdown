==> One tricky thing here in resqueue.c:1338 is:
	over commit is for the per process perspective, if this process has only one
	portal running, and the cost exceeds the limit, then it is OK to over
	commit; these is no considering for other processes, since PortalHashTable
	is process native;

==> In ResLockPortal's catch code path for ResLockAcquire, it would call
	ResLockWaitCancel and ResLockRelease; different from LockWaitCancel,
	ResLockWaitCancel does not call GrantAwaitedLock to update the locallock if
	we have been granted the lock and then was interrupted; then how does we
	handle this case?
	Answer: we do not care locallock in resource lock, even in ResLockAcquire,
	we do not update locallock after granted the lock successfully;

==> ResCheckSelfDeadLock is very tricky, when it detects that it is going to
	cause a self deadlock, it calls ResGrantLock and ResLockUpdateLimit, and
	then ereport ERROR, to jump to ResLockPortal's catch code for cleanup.
	Several questions:
	--> ResLockUpdateLimit would enforce the current value to be 0.0 if
	negative, then in ResLockRelease later, it is supposed to add back the
	current value, then it is wrong state now;
	--> after ResLockUpdateLimit, if another session wants to acquire the
	resource lock(cost based), and it is supposed to be able to get it if the
	deadlock one is not granted, so it would be inserted into the waitProc list
	now, though ResLockRelease would wake up one process, it is a delay here;

	Answer: fixed now;

==> ResLockAcquire does not update LOCALLOCK at all after acquiring the lock;
	should we remove LOCALLOCK for resource lock? not necessary, some routines
	use the LOCALLOCK, such as ResLockWaitCancel;

==> TODO(done): Change PGSemaphoreLock in ResProcSleep to be consistent with ProcSleep, and
	ResLockWaitCancel PGSemaphoreReset correspondingly;

==> ResRemoveFromWaitQueue's difference from RemoveFromWaitQueue is: additional
	cleanup for ResPortalIncrement by calling ResIncrementRemove;
