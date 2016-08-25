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
* For synchronous system, **failure detection** is easy, since there is a upper bound for the message delay; For asynchronous system, it is hard to tell whether the no-response is caused by network partition or node failure; Ideally, we'd prefer the failure detector to be able to adjust to changing network conditions and to avoid hardcoding timeout values into it. For example, Cassandra uses an accrual failure detector, which is a failure detector that outputs a suspicion level (a value between 0 and 1) rather than a binary "up" or "down" judgment. This allows the application using the failure detector to make its own decisions about the tradeoff between accurate detection and early detection.

