### fe-connect.c of libpq(create gang, dispatch code is fe-exec.c):
* If any error happens in PQconnectStartParams, including conninfo_array_pase(pass the connection info arrays), fillPGconn(move option values of option array into pg_conn) and connectDBStart(), status is set to CONNECTION_BAD;
* connectDBStart would build a addrinfo struct and call getaddrinfo, then it set the status to be CONNECTION_NEEDED, and call PQconnectPoll to do the real connect(in CONNECTION_NEEDED branch), if error happens in this procedure, CONNECTION_BAD is set;
* In PQconnectPoll's CONNECTION_NEEDED branch, the pipeline is socket/pg_set_noblock...(options setting up)/connect, then the status would be set CONNECTION_STARTED;
* connectDBComplete would block and complete a connection; this is implemented by an infinite loop of pqWaitTimed(wrapper of poll/select for socket IO) and PQconnectPoll, and the only exit status is PGRES_POLLING_OK;
* Roughly, there are 4 APIs to connect to a backend:
	* PQconnectdb and PQconnectdbParams are blocking;
	* PQconnectStart, PQconnectStartParams are nonblocking;
	* PQconenctdb uses PQconnectStart and connectDBComplete for implementation;
	* PQconnectdbParams uses PQconnectStartParams and connectDBComplete for implementation;
	* connectDBStart and PQconnectPoll would be used in PQconnectStartParams, and connectDBComplete would use PQconnectPoll and pqWaitTimed;
* status field of pg_conn indicates the health state of the connection, not OS level, GPDB level;

### asyncStatus of pg_conn
* PQisBusy would first consume the already received data and then check if the asyncStatus is PGASYNC_BUSY; PQgetResult will return immediately in all states except PGASYNC_BUSY, so there is a use pattern like:

	```
	if (PQisBusy(conn))
		return PGRES_POLLING_READING;
	res = PQgetResult(conn);
	```
* Normally, asyncStatus is set PGASYNC_BUSY once we kick off the query/plan over the connection, and set back to PGASYNC_IDLE in PQgetResult when no more result is available, means that the query execution has finished;