* A **total order** is a binary relation that defines an order for every element in some set.
* Two distinct elements are comparable when one of them is greater than the other. In a **partially ordered** set, some pairs of elements are not comparable and hence a partial order doesn't specify the exact order of every item.
* Both total order and partial order are transitive and antisymmetric.
* Facebook's Canssandra and Google's spanner uses global clock;
* Substitution of clock to indicate order: **Lamport clock and Vector clock**
	* A Lamport clock is simple. Each process maintains a counter using the following rules:
		* Whenever a process does work, increment the counter
		* Whenever a process sends a message, include the counter
		* When a message is received, set the counter to max(local_counter, received_counter) + 1
	* A vector clock is an extension of Lamport clock, which maintains an array [ t1, t2, ... ] of N logical clocks - one per each node. Rather than incrementing a common counter, each node increments its own logical clock in the vector by one on each internal event. Hence the update rules are:
		* Whenever a process does work, increment the logical clock value of the node in the vector
		* Whenever a process sends a message, include the full vector of logical clocks
		* When a message is received:
			* update each element in the vector to be max(local, received)
			* increment the logical clock value representing the current node in the vector
		* **Use cases of Vector Clock**:
			* Git branch merge: key point is that vector merge is completely independent of value merge, you can define any rule regarding value merge; there exists timestamp conflict, you have to define the behavior of value merge when conflict happens;
			* Dynamo of Amazon: write is fast, you only need to write to one node, to guarantee weak consistency, read has to read all nodes, and merge the value by timestamp of vector clock;
* For synchronous system, **failure detection** is easy, since there is a upper bound for the message delay; For asynchronous system, it is hard to tell whether the no-response is caused by network partition or node failure; Ideally, we'd prefer the failure detector to be able to adjust to changing network conditions and to avoid hardcoding timeout values into it. For example, Cassandra uses an accrual failure detector, which is a failure detector that outputs a suspicion level (a value between 0 and 1) rather than a binary "up" or "down" judgment. This allows the application using the failure detector to make its own decisions about the tradeoff between accurate detection and early detection.
* **Consensus problem**: Several processes (or computers) achieve consensus if they all agree on some value. Replicated systems that maintain single copy consistency need to solve the consensus problem in some way.
* The **replication algorithms** that maintain single-copy consistency include:
	* 1n messages (asynchronous primary/backup)
	* 2n messages (synchronous primary/backup)
	* 4n messages (2-phase commit, Multi-Paxos)
	* 6n messages (3-phase commit, Paxos with repeated leader election)
* Primary/backup replication:
	* There are two variants:
		* asynchronous primary/backup replication: WAL replication of PostgreSQL
		* synchronous primary/backup replication: Filerep of GPDB
	* it is worth noting that even synchronous P/B can only offer weak guarantees. Consider the following simple failure scenario:
		* the primary receives a write and sends it to the backup the backup persists and ACKs the write and then primary fails before sending ACK to the client The client now assumes that the commit failed, but the backup committed it; if the backup is promoted to primary, it will be incorrect.
	* Furthermore, P/B schemes are susceptible to split-brain, where the failover to a backup kicks in due to a temporary network issue and causes both the primary and backup to be active at the same time.
* **Leader election**
	* All nodes start as followers; one node is elected to be a leader at the start. During normal operation, the leader maintains a heartbeat which allows the followers to detect if the leader fails or becomes partitioned. When a node detects that a leader has become non-responsive (or, in the initial case, that no leader exists), it switches to an intermediate state (called "candidate" in Raft) where it increments the term/epoch value by one, initiates a leader election and competes to become the new leader. In order to be elected a leader, a node must receive a majority of the votes. One way to assign votes is to simply assign them on a first-come-first-served basis; this way, a leader will eventually be elected. Adding a random amount of waiting time between attempts at getting elected will reduce the number of nodes that are simultaneously attempting to get elected.
