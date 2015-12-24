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
	the available quota(ResLockCheckLimit);

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
