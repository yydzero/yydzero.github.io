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
	the available quota;

	Note that, the process itself can also be on the wait list, when the
	deadlock is triggered by itself; when it is the case, simply remove itself from
	the wait list and examine the next one;

	The wakeup algorithm here is a simple FIFO; XXX for a non-statement count
	resource queue(i.e, cost based), there may be quota left while the tail
	enquiry is blocked and less than the quota, if no re-ordering is
	implemented.
