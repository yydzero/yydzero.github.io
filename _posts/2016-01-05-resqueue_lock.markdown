==> After applying the fix, when self-deadlock detected, ResLockRelease would be
	called, and then it was found that ResPortalIncrement cannot be found, then
	just release the lwlocks and do nothing; so it is OK;

	TODO: one optimization can be done here is to add a new LOCK_ACQUIRE_RESULT,
	and check the self-deadlock, then throw error in ResLockPortal, to avoid the
	cost of LWLock acquiring in ResLockRelease in catch block; since
	self-deadlock is not that common, so this has low priority;

==> When hanging waiting for the resource lock, if a SIGTERM comes, then
	ProcessInterrupts would call proc_exit, then ResourceOwnerRelease would call
	ResLockWaitCancel, which would ResRemoveFromWaitQueue, which would cleanup
	the LOCK->nRequested, and ResPortalIncrement; no ResLockRelease is called in
	this path;

	SIGINT is also OK, ResLockWaitCancel would be called in the catch block in
	ResLockPortal, then the PROCLOCK holdMask would be cleaned, then
	ResLockRelease would do nothing;

==> Steps to reproduce phantom resource lock holder bug:
	--> set breakpoint at PGSemaphoreLock, just after semop and before reset
	ImmediateInterruptOk, then send a SIGTERM to the process, just after the
	process got the semaphore, in this path, no ResLockRelease is called;
	then we can see, there is no session at all, while GPDB believes someone is
	holding a resource lock;

	RC here is: Portal->releaseResLock is false;

==> After applying the fix, SIGINT/SIGTERM's cleanup is viable now; both
	ResLockWaitCancel and ResLockRelease would be called, in any possible code path;

==> Deadlock's cleanup is handled properly by ResRemoveFromWaitQueue, since the
	lock cannot have been granted yet, so no ResLockRelease is needed;

==> ResLockRelease's cleanup may have problem, when the ResQueue is not found or
	ResPortalIncrement is not found, either for the released portal or the
	portals to be waken up; these two cases are too weird, so I do not cleanup
	this cases;

==> Fatal problem of resource queue: concurrent Alter Resource Queue when query
	in queue; previously, GPDB would not allow ALTER RESOURCE QUEUE to succeed
	when then new limit value is less than the current value; then this check
	was removed by MPP-4340, this could lead to weird status of resource queue
	when the current value is larger than the limit, and no one is waiting;

	The behavior now is:
	--> when reducing limit when some portals are waiting: all current running
	portals continue, when they complete and release the resource lock, the new
	limit would take effect;
	--> when increasing limit when some portals are waiting: all current running
	portals convinue, when one completes and releases the resource lock, the new
	limit would take effect and more portals would be wakenup, in function
	ResProcLockWakeUp

	This may result in the temporary inconsistent state of resource queue, but
	in the long term, it would get back to the normal state; deadlock is not
	problem here, to some extent, you can treat the counter of resource queue
	and the lock of resource queue to be separate, as long as ResProcLockWakeup
	is implemented properly;

	AlterQueue would first modify the pg_resqueue table, then call ResAlterQueue
	to modify the ResQueueHash in share memory;

==> When is ResQueueHash loaded?
	Answer: in function InitResQueues(in PostgresMain), using caql to query the
	pg_resqueue, then call function ResCreateQueue, which would call ResQueueHashNew
	to allocate an entry in share memory and use the values from pg_resqueue to
	fill into the entry;
