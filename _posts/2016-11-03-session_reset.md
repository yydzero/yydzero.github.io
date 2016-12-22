## session reset in dispatcher
* resetSessionForPrimaryGangLoss: set NeedResetSession flag and set myTempNameSpaceOid to 0, is only called in disconnectAndDestroyAllGangs

* CheckForResetSession: bump gp\_session\_id, if we are not idle, return; if we are idle, start xact to remove temp tables; generally, call this function after calling disconnectAndDestroyAllGangs

* why reset session in this async style? for performance, only when we are really idle, we do the heavy work of deleting temp table

* why we need session reset?  diconnectAndDestroyGang is an async procedure, if we do not bump gp\_session\_id, we may have shared snapshot collision if the previous QE is not exited completely and we are starting new QE; session reset has a side effect -- removing temp tables

* criteria for session reset?(when shall we pass true to disconnectAndDestroyAllGangs) theoretically, all disconnectAndDestroyAllGangs(writer gang destroy) should reset session; in current code, one exception is when idle client time out is triggered, since we are idle, we do not want to bump the gp_session_id, otherwise, users would feel strange, and we should not delete temp tables in this case either; but this implementation is at the risk of writer gang collision stated above, since the session is idle, the probability of timeout trigger and then an immediate gang creation is very low, so …

* BUG: CheckForResetSession reset the NeedResetSession if we are not idle, then when do we remove the temp table?

