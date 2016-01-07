==> TODO: should we remove gp\_is\_callback?
==> lockHolderProcPtr is set when trying to acquire a lock, can it guarantee
	the correctness? when it is called, does the PGPROC all ready? when
	getSharedComboCidEntry <-- GetRealCmin <-- HeapTupleHeaderGetCmin ---
																		|
						   <-- GetRealCmax <-- HeapTupleHeaderGetCmax -----> in tqual.c, should
						   have called LockAcquire at least once
	loadSharedComboCommandId <-- getSharedComboCidEntry
	sharedLocalSnapshot_filename <-- dumpSharedLocalSnapshot_forCursor(safe,on QD and writer)
								 <-- readSharedLocalSnapshot_forCursor
								 	 <-- GetSnapshotData(cursor case, so LockAcquire should have been 
														 called)
	is called, is lockHolderProcPtr already set?

	when is the PGPROC put into procArray? is LockAcquire in reader called before putting
	the PGPROC of writer in?

	PGPROC is added into procArray and become visible to other processes in
	InitProcess->InitProcessPhase2->ProcArrayAdd; in QD, dispatcher would first
	create writer gang on segments, that is to say, before creating the readers,
	the writers have been created and initialized, thus before trying to create
	QE, the PGPROC of writer is already in procArray; so when reader tries to
	find lockHolderProcPtr, it should definitely find it in normal situations;
	the *synchronization* is done by QD in a serialisable style;

	for entry_db_reader? when calling function FincProcByGpSessionId, it would
	return the corresponding QD, since QD.mpp_is_writer is true, so there is no
	problem at all;

	TODO: modify the log message to indicate the possiblity of QD as the writer in
	LockAcquire; add comments there to raise the issue whether we should move
	the code episode of set lockHolderProcPtr to initialization phase;
