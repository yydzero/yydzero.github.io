## PG SpinLock and LWLock
==========================
### 8.3
-------
* In LWLockAcquire

	```
	453         for (;;)
	454         {
	455             /* "false" means cannot accept cancel/die interrupt here. */
	456             PGSemaphoreLock(&proc->sem, false);
	457             if (!proc->lwWaiting)
	458                 break;
	459             extraWaits++;
	460         }
	```
	`extraWaits` is to not assume the sem is 0 when entering for loop. Same applies to `lwWaiting`.
* In LWLockRelease

	```
	603     if (head != NULL)
	604     {
	605         if (lock->exclusive == 0 && lock->shared == 0 && lock->releaseOK)
	606         {
	607             /*
	608              * Remove the to-be-awakened PGPROCs from the queue.  If the front
	609              * waiter wants exclusive lock, awaken him only. Otherwise awaken
	610              * as many waiters as want shared access.
	611              */
	612             proc = head;
	613             if (!proc->lwExclusive)
	614             {
	615                 while (proc->lwWaitLink != NULL &&
	616                        !proc->lwWaitLink->lwExclusive)
	617                     proc = proc->lwWaitLink;
	618             }
	619             /* proc is now the last PGPROC to be released */
	620             lock->head = proc->lwWaitLink;
	621             proc->lwWaitLink = NULL;
	622             /* prevent additional wakeups until retryer gets to run */
	623             lock->releaseOK = false;
	624         }
	```
	why introducing `releaseOK`? to avoid starvation. Each time someone releases a LWLock, it may wake up some backends, and these backends would go into the retry loop to acquire the spin lock. These waked up backends would contend with the new coming backends for the spin lock, if one new coming backend gets the spin lock, which is not retrying, so it would not set `releaseOK` of lock back to true, so when this backend releases the lock, it cannot wake up any backends, otherwise, the previously waked up backends would be starved and may never get a chance to get the spin lock.
* Should we remove the `lock->exclusive == 0` check in line 605? because it is always true.
* Why lock manager chooses to make releaser directly grants the lock to a waiter, but LWLock chooses the wake up and retry mechinism? The assumption is that LWLock is held for a short time, and the frequency of LWLockAcquire and LWLockRelease is high, so there are situations where a process call lock->unlock several times in a 'cpu time slice', so if we grant the lock, then we are likely to be scheduled out for the next lock acquire, which is not effecient. The assumption of lock manager is the lock would be held for a long time.

### 9.6
-------
* Q: why reset `LW_FLAG_RELEASE_OK` just after one backend is waked up? this seems cannot avoid starvation, e.g, if the new comming backends get the lock and then release another batch of backends(from head or tail?), those will contend with the previously waked backends.
* Q: Can a backend holds a LWLock and then acquire it again? the LWLockAcquire seems no check for this case, so if the backend has held an exclusive lock, then it would hang if it tries to get a share lock again, this is a deadlock situation.
