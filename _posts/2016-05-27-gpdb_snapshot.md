### GPDB's GetSnapshotData:
* PostgreSQL's GetSnapshotData would return xmin, xmax and xip, while GPDB's GetSnapshotData would do more things, including:
  * allocate space for distribSnapshotWithLocalMapping in SnapShot struct, QD, writer QE and reader QE would all do this;
  * for reader QE, set the dtx portion of SnapShot using the DTXInfo dispatched from QD(optimization, by function FillInDistributedSnapshot), and wait and copy local portion of SnapShot from sharedLocalSnapshot;
  * for writer QE and QD, do the regular work of PostgreSQL's GetSnapshotData, i.e, get local portion of SnapShot;
  * QD and writer QE would both call FillInDistributedSnapshot, in this funciton, QD(DTX_CONTEXT_QD_DISTRIBUTED_CAPABLE) would call createDtxSnapshot to set the DTX portion of SnapShot, while writer QE and reader QE would copy from the DTX portion of the dispatched snapshot;
  * for writer QE, the final additional step is updateSharedLocalSnapshot;
  