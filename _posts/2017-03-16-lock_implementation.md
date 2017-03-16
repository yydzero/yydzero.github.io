* LOCKTAG uniquely identifies a resource to be locked;

* LOCK structure descripts the live locking situation of a target resource,
	that is to say, which processes acquired the lock on this target resource,
	and which processes are waiting for the lock on this target resource;
	* LOCKTAG tag
	* LOCKMASK grantMask: all the lock modes that have been granted on this target resource;
	* LOCKMASK waitMask: all the lock modes wait to be granted on this target resource;
	* `SHM_QUEUE` procLocks: all the procs that have been granted the lock on the target resource, not in PGPROC list form, but in LOCKPROC list form, here SHM_QUEUE is the **head** of the list;
		* `SHM_QUEUE` is a structure widely used for share memory code, it is a part of the share memory double linked list implementation; each element in the linked list is a `SHM_QUEUE` structure, there is no data field in `SHM_QUEUE`, the pointer of the data can be get by using the offset and the pointer of the SHM_QUEUE element, so by this way, the linked list functionality is abstracted out; Another thing is: when SHM_QUEUE is a field of a structure, when perform insert/delete of list, only the SHM_QUEUE would be adjusted; when perform next/prev of list, the offset of SHM_QUEUE in the structure is considered, so the returned pointer is for the structure instead of the SHM_QUEUE; so better to put the SHM_QUEUE as the last field of the structure to make use of this implementation, but you can put it as the first field also, that is easier; Note that, SHM_QUEUE can only be used as a field of a structure, which is to be allocated from share memory;
	* PROC_QUEUE waitProcs: all the procs waiting to be granted lock on target resource, in PGPROC list form, here PROC_QUEUE is the **head** of the list;
		* PROC_QUEUE is a wrapper for SHM_QUEUE with an additional field to record the size of the list;
	* int requested[MAX_LOCKMODES]: record numbers of locks requested for each lock mode, including the granted locks;
	* int nRequested: total number together;
	* int granted[MAX_LOCKMODES]: record numbers of locks waiting for each lock mode;
	* int nGranted: total number together;
	* each process/transaction would be counted only once for multiple grabs
		on a particular lock(LOCALLOCK works here);

* **Actually, there is no need for PROCLOCK structure if no deadlock detection**, simply use PROC_QUEUE for PGPROC is OK; Each PROCLOCK is a map of a PGPROC and a LOCK, where PGPROC can be process granted the lock or the process waiting for the lock; PROCLOCKTAG is combination of PROC and LOCK;
	* PROCLOCKTAG tag
	* LOCKMASK holdMask: lock modes granted of the specific lock in tag for this process;
	* LOCKMASK releaseMask: temp workspace for LockReleaseAll();
	* SHM_QUEUE lockLink and SHM_QUEUE procLink: add this structure into linked lists; that is to say, **for each** PGPROC, there would be a linked list of PROCLOCK recording the lock **granted or waiting for**, i.e, myProcLocks field in PGPROC; and for each LOCK, there would be a linked list of PROCLOCK recording the processes which **has acquired** the lock, i.e, procLocks field in LOCK structure; these two SHM_QUEUE is just an **element** in a list, not a head;
	* GP-specific fields for resource queue
		* int nLocks: total number of times this lock is acquired by this process. Should be moved to LOCALLOCK? provide that share memory lock only counts once for each process/transaction. Answer: no, LOCALLOCK of resource lock is almost not used, and nLocks should be in share memory as it may be referenced by other backends;
		* SHM_QUEUE portalLinks: **head**, since a process would acquire a single resource queue lock several times, each time with a ResPortalIncrement structure, we link these increments into a list, and the head is put here; Whether nLocks equals to the length of this list? Answer: these two has no relationship at all! nLocks means the number of portals which have acquired the resource lock, while the length of the portalLinks means the number of portals waiting to get the resource lock;
			* TODO: Should restrict these two fields to specific resource queue lock to reduce share memory usage? Answer: not that urgent to do this currently; Should be moved to LOCALLOCK also? Answer: cannot be moved into LOCALLOCK, because this information should be exposed to other processes, so must reside in share memory, though it violates the design of PROCLOCK a little bit;
		* All ResPortalIncrements are in share memory as a hash table, with
			global variable ResPortalIncrementHash points to it; the unique
			identifier for a ResPortalIncrement is pid and portal id, that is to
			say, for each process, there would be a list of ResPortalIncrements,
			with head in PROCLOCK, and each element is for a portal, ordinarily,
			there would be only one element for a process, if there are extended
			queries, then more than one elements would be in the list;

* LOCALLOCK is mainly for recording the number of times the lock has been acquired, since a process/transaction would be counted only once in share memory lock; the numbers are tracked per ResourceOwner;
	* LOCALLOCKTAG tag: combination of LOCKTAG and lockmode;
	* LOCK \*lock: corresponding lock in share memory; LOCALLOCK in process private, so we can use pointer directly;
	* PROCLOCK \*proclock: corresponding proclock in share memory;
	* int64 nLocks; number of times acquired;

* LOCK, PROCLOCK, and LOCALLOCK are organized into hash table LockMethodLockHash, LockMethodProcLockHash and LockMethodLocalHash in share memory;

* Function InitLocks is called in postmaster startup, it creates those 3 hash tables; there is an assumption of average 2 holders per lock(estimated number of PROCLOCK);

* A question of LockAcquire is: the order of insert/modify LOCALLOCK/PROCLOCK and LOCK; should them be atomic?
	* Answer: yes, they are atomic, protected by LWLockAcquire(partitionLockId); First, allocate entry in LOCALLOCK, LOCK and PROCLOCK, not modify the entry, then after check conflicts, call GrantLock to modify LOCK and PROCLOCK, and GrantLocalLock to modify LOCALLOCK;
	* the concurrency is protected by LWLockAcquire(partionLockId);
	* there is no ereport in GrantLock and GrantLocalLock, so cannot longjump
		to escape the atomic protection;
	* there is no CHECK_FOR_INTERRUPTS in function LockAcquire, so no
		interrupts;

* LockMethodLockHash is logically divided into several partitions using hash, so when reading/writing a LOCK entry, use corresponding partition's LWLockId for concurrency protection;

* global variable lockHolderProcPtr is a pointer to a PGPROC which is responsible for snapshot stuff, i.e, for utility mode and QD, it's itself, for QE on segments, it's the writer's PGPROC; However, reader can indeed acquire locks; Question: if reader gang acquired locks, is there any risk we do not release them? Answer: no risk, the locks can be released in ResourceOwnerRelease, which would be called in CommitTransaction or AbortTransaction, it is not writer specific;

* `hash_search` would first calculate the hash value of the key, hash_search_with_hash_value would directly use the hash_value param and then check the match of the key; LOCALLOCK->hashcode is the hash value of the LOCKTAG in LOCALLOCKTAG, not LOCALLOCKTAG itself; There is a function pointer in struct HTAB, which specifies the memory allocator to be used in hash table, when action is HASH_ENTER_NULL, the pointer cannot be palloc related function;

* GrantLock is to modify the LOCK and PROCLOCK structures' fields(number and lockmask) to reflect that the lock has been granted to the process;

* LockCheckConflicts would count the lock modes already held by this process, and the processes has same mppSessionId, so it's OK for reader QE to acquire locks;

* why in ProcSleep we should check LockCheckConflicts again? the partitionLockId is always held by us(proc.c:974). Answer: in LockAcquire, we can get STATUS_FOUND when finding the target mode, e.g, mode x, is in waitMask, then dive into ProcSleep without really checking LockCheckConflicts, however, if another process is waiting for the lock for mode x, and we are inserted before it in wait list, then we cannot say we are really blocked by the lock without calling LockCheckConflicts;
	
* Acquisition of either a spinlock or a lightweight lock would let cancel and die interrupts to be held off until all such locks are released by HOLD_INTERRUPTS/RESURE_INTERRUPTS. No such restriction exists for regular locks; We can accept cancel and die interrupts while waiting for a regular lock(verified manually); it is implemented in function PGSemaphoreLock(true), for LWLock and spinlock, the param is false; see the comments in posix_sema.c:246, very helpful

* The partition's LWLock is considered to protect all the LOCK objects of that partition as well as **their subsidiary PROCLOCKs**; The other lock related fields of a PGPROC are only interesting when the PGPROC is waiting for a lock, so we consider that they are protected by the partition LWLock of the awaited lock;

* Deadlock of regular lock can be caused by:
	* between different modes of a single lock; this is detected when trying to insert the PGPROC into the wait list of the lock by function ProcSleep(); deadlock check can handle this case as well, but direct adjustment in ProcSleep is cheaper without incurring a deadlock timeout;
	* between different locks: this kind of deadlock checking would LWLock all the partitions in partition-number order(to avoid LWLock deadlock); see README

		> The deadlock checking is triggered by timer DeadLockTimeout, ususally
		one second, the deadlock is resolved usually be aborting the detecting
		process' transaction, or re-arrange the wait list of a lock if possible;
		Deadlock detection is an independent component, and is elaborated quite
		clear in README.

*  ProcLockWakeup is called when a lock is released by UnGrantLock or **a prior waiter is aborted**; Must call ProcLockWakeup after releasing a lock or re-arrange the wait list of a lock, to guarantee no missing wakable process;

	> "When a lock is released, the lock release routine (ProcLockWakeup) scans
	the lock object's wait queue.  Each waiter is awoken if (a) its request
	does not conflict with already-granted locks, and (b) its request does
	not conflict with the requests of prior un-wakable waiters.  Rule (b)
	ensures that conflicting requests are granted in order of arrival. There
	are cases where a later waiter must be allowed to go in front of
	conflicting earlier waiters to avoid deadlock, but it is not
	ProcLockWakeup's responsibility to recognize these cases; instead, the
	deadlock detection code will re-order the wait queue when necessary." --README

	* When waking up a process, first update the share memory state before going to call the PGSemaphoreUnlock, to gurantee the lock grant is recorded in case the waked process is interrupted just after the wakeup; see posix_sema.c:272

* Only LockAcquire would call WaitOnLock, only WaitOnLock would call ProcSleep;

* In ProcSleep, if we find a deadlock when trying to insert the PGPROC into the wait list, i.e, when early_deadlock is true, we do not have to call ProcLockWakeup in RemoveFromWaitQueue->CleanUplock, because the begin state is exactly same as the end state per the wait list, and the temporary different state cannot be seen by anyone since the partition lwlock is held by us all the time;

* In the case when lock is not available, partition LWLock is released only when we have finished inserting the PGPROC into the wait list in ProcSleep; 

* LockWaitCancel would be called in cancel/die handler;
	* Question: there is a comment in LockWaitCancel, saying "Don't try to cancel resource locks"; Answer: resource lock is specially handled by ResLockWaitCancel, it uses a different code path with regular locks, it is OK here;

	* Question: is there problems resource lock uses same awaitedLock as regurlar locks? Answer: no, there is no possibility that a process is waiting for a resource lock and a regular lock at the same time;

	* LockWaitCancel is responsible for keep LOCALLOCK valid in race condition when we are granted the lock and not able to record it in LOCALLOCK because of cancel/die interrupts; see proc.c:1069 and posix_sema.c:272

* Both ProcSleep and ProcWaitForSignal(signal means "clue" here) are implemented using PGSemaphore, but a process cannot call this two function at the same time, so it's OK; the only thing concerns is a special case when a process first call ProcWaitForSignal, then was aborted, and then another process calls ProcSendSignal, then the first process call ProcSleep, there would be a leftover "signal" there, so we should use:
	
	```
	do
	{
		PGSemaphoreLock();
	} while(MyProc->waitStatus == STATUS_WAITING)
	```
to check we indeedly get the lock; After exiting the do while loop, the MyProc->waitStatus can be STATUS_OK or STATUS_ERROR when deadlock detected and RemoveFromWaitQueue called in	handle_sig_alarm->CheckDeadLock

* Auxiliary processes are not expected to acquire regular locks, but they would do for LWLock, thus PGPROC is necessary;

* awaitedLock is used for keep LOCALLOCK valid in error cases, it is first set in the begining of WaitOnLock, and set back in the end of WaitOnLock; it is used by WaitLockCancel to GrantLocalLock if found share lock granted, and process itself is not able to GrantLocalLock before interruption; It is possible that LOCALLOCK entry exists for a lock and lockmode, while the lock and proclock field is null, that is caused by "out of share memory" when allocating lock and proclock, and thus ERROR would go into LockWaitCancel, it would not call RemoveLocalLock, let alone the awaitedLock is not set yet; LockWaitCancel is called when transaction is committed or aborted, or in die/StatementCancelHandler, or in ResourceOwnerReleaseInternal;

* LockReleaseAll would first modify LOCALLOCK entries, then modify LOCK and PROCLOCK partition by partition, this can reduce the LWLockAcquire cost;

* `AtPrepare_Locks` would traverse the LOCALLOCK, and record the locks held into a XLogRecData list which resides in memory context; this function is called in PrepareTransaction; After successful PREPARE, the ownerships of current held locks would be transferred to a dummy PGPROC, which is associated with the prepared transaction; hence all the corresponding entries in LOCALLOCK would be removed; this is done by function PostPrepare_Locks, which is called in function PrepareTransaction; Note that, for a dummy PGPROC of a prepared transaction, there is no LOCALLOCK, it is in another form as TwoPhaseLockRecord; PostPrepare_Locks is quite similar as LockReleaseAll: first go through LOCALLOCK and mark releaseMask of proclock, then clean up LOCK and PROCLOCK;

* All the temporary objects are put under a temp namespace;

* `hash_seq_search` a HTAB(dynahash.c) can handle the case when HTAB is inserted during the traversal, however, whether the newly appended entries would be traversed or not should be double checked;

* GetLockStatusData is used by user level function such as `pg_locks`, one thing is that we should grab all the partition lock first before we copy any data, this is to guarantee we have a self-consistent view of the state;

* `lock_twophase_recover` is registered as a callback, which would be called in RecoverPreparedTransactions; it is quite similar as LockAcquire, except that it does not check the conflicts, and grant the lock any how;
	* Differences:
		* locallock does not included in this function;
		* the proc in PROCLOCK is the dummy proc for prepared transaction;
		* no conflicts check; XXX any problems? in what situation this function is called?
* Similarly, `lock_twophase_postcommit` would be called in FinishPreparedTransaction; it is quite like LockRelease, differences:
	* no locallock involved;
	* dummy proc in PROCLOCK;

* lock_twophase_postabort is just exactly same as lock_twophase_postcommit, so if a COMMIT PREPARE fails, then the locks of the dummy PGPROC would be released, so lock_twophase_recover should re-acquire them later;