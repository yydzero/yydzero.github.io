==> ResLockPortal would return true if the portal takes the lock, false if
	skipped the lock, the result is stored in portal->releaseResLock, in the
	cleanup, this field is used to indicate whether lock release needed;

==> There is one and only one LOCK for a resource queue;

==> As the resource lock is taken after parse/analyze most regular locks have
	been already acquired before the resource lock is (tuple level locks are the
	exceptions).

==> Deadlocks between regular and resource locks are possible, and are handled
	by the deadlock detector. We pass the lock mode as ExclusiveLock - which
	results in overly agressive detection and rollback of deadocks. However, safety
	is the *initial* goal!

==> ResLockPortal does the following things:
	--> decide whether to take resource locks based on sourceTag
	--> build the ResPortalIncrement
	--> ResLockAcquire; note that, the tag is the queue id, and the lock method
		is RESOURCE_LOCKMETHOD; actually, it is exactly same as default lock
		method, but the name is different;

		--> guarantee there is an entry in LOCALLOCK for the resource lock; the
			values do not matter actualy;
			XXX do we really need LOCALLOCK for resource lock, since we must
			access share memory for resource lock;
		--> since no LOCALLOCK guard, so a process/transaction may increase the
			LOCK fields more than once;
			XXX is this necessary? do other places handle this properly? e.g,
			deadlock detector and pg_locks?
		--> find the corresponding ResQueue
			XXX when exception occurs here(cannot find ResQueue in ResQueueHash),
			LWLockReleaseAll is called, so partition LWLock would be released also,
			if other processes modify the LOCK fields concurrently, is there any risk?
			XXX should reduce the LOCK before release all lwlocks in CATCH?
		--> check the ignorecostlimit
			--> ResCleanUpLock(no waking up needed)



==> 3 structures of resource management, all in share memory:
	--> ResSchedulerData, just contains a field indicating the number of current
		resource queues, there is a global variable ResScheduler pointing to it;
	--> ResQueueData: the metadata and *status* of the resource queue; all the
		ResQueueDatas are organized into a hash table, and referenced by a
		global variable ResQueueHash; these two structures are initialized in
		InitResScheduler; this is protected by ResQueueLock LWLock;
	--> ResPortalIncrement: the increment of a specific portal, they are
		organized as a double linked list(SHM_QUEUE) put in the portalLinks
		field of PROCLOCK; this is protected by partition LWLock;

==> ResProcLockRemoveSelfAndWakeup would traverse the wait list of a lock, and
	then get the waiting portal(since only one portal in a process can be
	waiting, so it is OK here), and its ResPortalIncrement, then compare with
	the available quota(ResLockCheckLimit); this function is the counterpart of
	ProcLockWakeup;

	Note that, the process itself can also be on the wait list, when the
	deadlock is triggered by itself; when it is the case, simply remove itself from
	the wait list and examine the next one;

	The wakeup algorithm here is a simple FIFO; these functions are normally
	called together:
	--> ResLockCheckLimit
		Does not check the STATUS_ERROR return value here in
		ResProcLockRemoveSelfAndWakeup, because a STATUS_ERROR PGPROC cannot be
		inserted into the waiting list, which is controlled in ResLockAcquire;
	--> ResGrantLock
	--> ResLockUpdateLimit
	--> ResProcWakeup(same as ProcWakeup, remove itself from lock's wait list)

	XXX ResPortalIncrement is not removed from portalLinks of PROCLOCK, what is
	this used for?

==> The overcommit of ResQueueData is for cost only, which means that you can
	exceed the cost limit if there is no other quota enquiry.(ResLockCheckLimit)

==> Why we need LOCK and PROCLOCK in resource management, seems only the
	ResQueueHash is enough?

	Answer: LOCK and PROCLOCK is used for the wake up mechanism, and the
	deadlock detection mechanism;

==> UnGrantLock would check the conflicts of ungranted lock mode with the
	waitMask, to see whether wake up of the waiting list is needed; while for
	ResUnGrantLock, wake up is alwayls needed;

==> The queueId and portalId in PGPROC is firstly set properly during process
	initialization, regardless of the role is super user or not; then after
	returning from ResLockAcquire, if result is LOCKACQUIRE_NOT_AVAIL, then we
	should reset these two fields to zero, to indicate that this query is not
	managed by resource queue;(resqueue.c:319)

==> ResIncrementAdd builds the ResPortalIncrement in share memory;

==> Before going to sleep in ResLockAcquire, there is a guc to control whether
	we would destroy all idle reader gangs;

==> TODO: ResWaitOnLock's sleeping part is different from WaitOnLock, is it correct? no
	--> should use a PG_TRY/PG_CATCH to keep pgstat and display valid;
	--> should set awaitedLock to NULL if deadlock detected? XXX to be further confirmed

==> XXX raised exceptions in ResLockAcquire

==> The rough procedure of deadlock detection is: sig\_alarm is triggered, and
	function CheckDeadLock is called, then if deadlock detected,
	RemoveFromWaitQueue is called, then PGSemaphoreUnlock is called, then return
	from handler of sig_alarm, then PGSemaphoreLock can exit and the
	PGPROC.waitStatus has already been set STATUS_ERROR in RemoveFromWaitQueue;

==> lockAwaited is set and reset in ProcSleep/LockWaitCancel, actually quite same as
	awaitedLock, which is set and reset in WaitOnLock;
	XXX can we merge them into a single one?

==> LockWaitCancel is to handle the cases when PGSemaphoreLock is interrupted by
	SIGINT/SIGTERM, either on sem_wait or just exited from sem_wait; it is
	called in StatementCancelHandler/die, or in ProcReleaseLocks at main
	transaction commit or abort, or in AbortTransaction and AbortSubTransaction;

	ResLockWaitCancel is called in ResLockPortal when exceptions are caught in ResLockAcquire,
	and in ResourceOwnerReleaseAllInternal;

	XXX
	--> can we merge LockWaitCancel and ResLockWaitCancel into a single one?
	--> ResLockWaitCancel has some suspicious spots:
		--> does not disable_sig_alarm
		--> assert that we cannot be granted the lock
		--> PGSemaphoreReset which is not necessary

==> It is manually verified when waiting for the resource lock, it is able to be
	canceled; why? since StatementCancelHandler does not call ResLockWaitCancel.

	Answer: the code path here is different when waiting for regular lock and
	resource lock;
	
	--> for regular lock:
		--> if SIGINT comes when hanging on semop, then LockWaitCancel in
		StatementCancelHandler would RemoveFromWaitQueue and return true, then
		ProcessInterrupts would be called and longjump to other places, so would
		not get back to semop again;
		--> if SIGINT comes just after exiting semop, LockWaitCancel in
		StatementCancelHandler would GrantLocalLock and return true, then
		ProcessInterrupts would be called and longjump to other places, so would
		not get back to semop again also;

		So, the regular lock is guaranteed to not get back to semop, so is
		viable;

		Not necessary to call PGSemaphoreReset, since it is only needed in one
		race condition: during entering StatementCancelhandler and
		RemoveFromWaitQueue(or LWLockAcquire), another process granted us the
		lock(called PGSemaphoreUnlock), and now we have removed ourself from the
		waitProc, so there is a remaining semaphore; even in this mere race
		condition, the left over semaphore is not harmful, because ProcSleep
		would double check the waitStatus after exiting PGSemaphoreLock, so it
		is not necessary to reset the semaphore here;
	--> for resource lock:
		whenever SIGINT comes in PGSemaphoreLock, the StatementCancelHandler
		would do nothing except for setting the QueryCancelPending flag; it is
		canceled when loop back to CHECK_FOR_INTERRUPTS, so it is based on the
		assumption that semop is *interruptible*;

		TODO: we should change the behavior here to make it viable to be
		interrupted;


==> RemoveFromWaitQueue would first remove itself from the LOCK's waitProc, so
	there is no ProcLockRemoveSelfAndWakeup, just ProcLockWakeup;

==> ResProcSleep does not need to find a proper position in the waitProc list to
	insert as ProcSleep, it can just append itself to the end of the queue,
	since all the mode of the resource lock is exclusive, there is no check
	between lock modes dependency; difference here is, after inserting itself to
	waitProc list, it would call a ResCheckSelfDeadlock, which is not in
	ProcSleep; the reason is that, regular deadlock detector does not consider
	self deadlock at all, because one regular lock can be acquired only once in
	share memory, and there is a basic assumption that there is no conflicts
	between regular locks for a single process/transaction, so self deadlock is
	a special case need to be handled for resource lock;

==> TODO: change some of the ResQueueLock to LW\_SHARE, for example,
	ResCheckSelfDeadLock

	ResQueueLock not only protects ResQueueHash, but also protects
	ResPortalIncrementHash;

==> XXX what happens if we set role to another one in a transaction which has
	declared cursors? how about the ResPortalIncrement?
	then how about we set role in a function?

==> XXX why TotalResPortalIncrements does not use portalLinks of PROCLOCK for
	the calculation, instead of using PortalHashTable and ResPortalIncrementHash;

	TotalResPortalIncrements does count itself, because ResIncrementAdd is
	called in ResLockAcquire to insert itself into ResPortalIncrementHash even
	before ResLockCheckLimit;
