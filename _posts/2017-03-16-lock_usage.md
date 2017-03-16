
* LockMethodData can be compared as electronic lock or traditional lock, it specifies:
	* the meaning of each lock mode, that is to say, which lock mode conflicts with other lock modes;
	* whether this kind of lock is transactional, that is to say, whether released at transaction end;
	* 3 important fields of this structure:
		* numLockModes
		* transactional
		* conflictTab: this is an array of bitmask, each bitmask records the
	conflicts of one lockmode with other lockmodes;

	* All LockMethodData instances are hard coded in lock.c, 3 in total, stored in const array `LockMethods`, and these 3 are almost the same, the only difference is that `USER_LOCKMETHOD` is not transactional;

* Table lock is used combined with underlying tuple visibility check -- visibility check implementation has several assumptions about table locks held.

* Quote from PG 8.3 documentation, `Explicit Locking` chapter:
> Remember that all of these lock modes are table-level locks, even if the name contains the word "row"; the names of the lock modes are historical. To some extent the names reflect the typical usage of each lock mode — but the semantics are all the same. **The only real difference between one lock mode and another is the set of lock modes with which each conflicts**. Two transactions cannot hold locks of conflicting modes on the same table at the same time. (However, a transaction never conflicts with itself. For example, it might acquire ACCESS EXCLUSIVE lock and later acquire ACCESS SHARE lock on the same table.) Notice in particular that some lock modes are **self-conflicting** (for example, an ACCESS EXCLUSIVE lock cannot be held by more than one transaction at a time) while others are not self-conflicting.

* For the 8 table lock modes, the comment specifies which mode to use pretty clear for each operation, except for these two: `ShareRowExclusiveLock` and `ExclusiveLock`. For 'ShareRowExclusiveLock', it is not used at all in source code, so ignore it. For `ExclusiveLock`, it is only acquired on certain system catalogs in some operations. Yeh, it is not clear, just remember it blocks `SELECT FOR UPDATE/SHARE` in table level.

* Once the locks are acquired, normally they are released at the end of transaction; But if a lock is acquired after establishing a savepoint, the lock is released immediately if the savepoint is rolled back to. The same applys for locks acquired within a PL/pgSQL exception block: an error escape from the block releases locks acquired within it.

* There seems no clear principle whether we should manually release the table locks inside the transaction by code, it may differ from case to case, so keep in mind the conflict tables and guard against those unsafe operations. (check out discussions in gpdb-dev mailing list: `Why locks are held until end of transaction`)

* For row level locks, specifically `SELECT FOR UPDATE/SHARE`, `xmax` and `t_infomask` fields of the tuple header are used to implement the locking semantic, because a transaction can take a lot of row locks before committing, which introduces the concern of regular lock table overflow. However, there do exist `LockTuple` function, comments of `heap_lock_tuple` explains:
> NOTES: because the shared-memory lock table is of finite size, but users
could reasonably want to lock large numbers of tuples, we do not rely on
the standard lock manager to store tuple-level locks over the long term.
Instead, **a tuple is marked as locked by setting the current transaction's
XID as its XMAX, and setting additional infomask bits to distinguish this
usage from the more normal case of having deleted the tuple**. When
multiple transactions concurrently share-lock a tuple, the first locker's
XID is replaced in XMAX with a **MultiXactId** representing the set of
XIDs currently holding share-locks.
>When it is necessary to wait for a tuple-level lock to be released, the
basic delay is provided by `XactLockTableWait` or `MultiXactIdWait` on the
contents of the tuple's XMAX.  However, **that mechanism will release all
waiters concurrently, so there would be a race condition as to which
waiter gets the tuple, potentially leading to indefinite starvation of
some waiters**.  The possibility of share-locking makes the problem much
worse --- a steady stream of share-lockers can easily block an exclusive
locker forever. **To provide more reliable semantics about who gets a
tuple-level lock first, we use the standard lock manager**.  The protocol
for waiting for a tuple-level lock is really like the following code. When there are multiple waiters, arbitration of who is to get the lock next is provided by LockTuple(). However, **at most one tuple-level lock will
be held or awaited per backend at any time, so we don't risk overflow
of the lock table**.  Note that incoming share-lockers are required to
do LockTuple as well, if there is any conflict, to ensure that they don't
starve out waiting exclusive-lockers.  However, if there is not any active
conflict for a tuple, we don't incur any extra overhead.

	```
	LockTuple()
	XactLockTableWait()
	mark tuple as locked by me
	UnlockTuple()
	```

* A running example of table lock combined with row lock for `SELECT FOR UPDATE`
	* operation sequence:
	
		```
		Tx1: Begin;
		Tx1: SELECT * FROM tbl FOR UPDATE; -- RowShareLock on tbl acquired
		Tx2: Begin;
		Tx2: DELETE FROM tbl; -- RowExclusiveLock can be acquired on table, since they does not conflict, but this DELETE statement would hang
		```
	* the logic behind the hang of the DELETE in Tx2 is:
		* DELETE would call `ExecutePlan` to scan the table, in `heap_getnext` -> `heapgetup_pagemode` -> `heapgetpage`, visibility would be checked for each tuple in the page by `HeapTupleSatisfiesMVCC`, it find that `(tuple->t_infomask & HEAP_IS_LOCKED)` is true, so believes the tuple is visible, and get back to `ExecDelete` -> `heap_delete` in `ExecutePlan`, `heap_delete` calls `HeapTupleSatisfiesUpdate` and find xmax is in progress, so returns `HeapTupleBeingUpdated`, so it would `LockTuple` first, and wait for the commit of xmax by `XactLockTableWait`