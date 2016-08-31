## Run TINC tests
* Clone the tinc repo: git clone git@github.com:greenplum-db/tinc.git
* Setup environment:
	* source $GPHOME/greenplum_path.sh
	* export $PGPORT= port
	* export $PGDATABASE=postgres
	* cd tinc
	* source tinc_env.sh
* Run the TINC test:
	* cd tincrepo/mpp/gpdb/tests/storage/transaction_management/crashrecovery 	* tinc.py discover .
		* This runs the test CrashRecovery_2PC.test_master_panic_after_phase1 defined in test_crashrecovery.py. It takes about 2 mins to run on my laptop. You may tail the test log from crashrecovery/log/tinctest*.log