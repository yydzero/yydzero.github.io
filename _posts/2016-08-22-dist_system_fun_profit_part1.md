* Computations primarily benefit from high-end hardware to the extent to which they can replace slow network accesses with internal memory accesses. The performance advantage of high-end hardware is limited in tasks that require large amounts of communication between nodes.
* **Scalability**:
	* with dataset constant, adding more nodes should make the system linearly faster;
	* growing the dataset should not increase latency if linearly add nodes;
* **Measure of scalability**:
	* performance
		* Short response time/low latency for a given piece of work
		* High throughput
	* availability
* A system that makes weaker guarantees has more freedom of action, and hence
potentially greater performance - but it is also potentially hard to reason
about. People are better at reasoning about systems that work like a single
system, rather than a collection of nodes.
* network partitions (e.g. total network failure between some nodes). A network partition occurs when the network fails while the nodes themselves remain operational. 
* **Two basic techniques that can be applied to a data set**. It can be split over multiple nodes (partitioning) to allow for more parallel processing. It can also be copied or cached on different nodes to reduce the distance between the client and the server and for greater fault tolerance (replication).
	* partition
		* Partitioning improves performance by limiting the amount of data to be examined and by locating related data in the same partition
		* Partitioning improves availability by allowing partitions to fail independently, increasing the number of nodes that need to fail before availability is sacrificed
	* replicate
		* Replication improves performance by making additional computing power and bandwidth applicable to a new copy of the data
		* Replication improves availability by creating additional copies of the data, increasing the number of nodes that need to fail before availability is sacrificed
* Replication is also the source of many problems
* **System model**: a set of assumptions about the environment and facilities on which a distributed system is implemented. Assumptions include:
	* what capabilities the nodes have and how they may fail
	* how communication links operate and how they may fail
	* properties of the overall system, such as assumptions about *time and order*
* The synchronous system model imposes many constraints on time and order. It
essentially assumes that the nodes have the same experience: that messages that
are sent are always received within a particular maximum transmission delay, and
that processes execute in lock-step. This is convenient, because it allows you
as the system designer to make assumptions about time and order, while the
asynchronous system model doesn't. It is easier to solve problems in the synchronous system model, because assumptions about *execution speeds*, *maximum message transmission delays* and *clock accuracy* all help in solving problems since you can make inferences based on those assumptions and rule out inconvenient failure scenarios by assuming they never occur.Of course, assuming the synchronous system model is not particularly realistic. Real-world networks are subject to failures and there are no hard bounds on message delay. Real world systems are at best partially synchronous: they may occasionally work correctly and provide some upper bounds, but there will be times where messages are delayed indefinitely and clocks are out of sync.
* Two impossibility results for consensus problem:
	* FLP
	* CAP
* My understanding of **CAP theorum**:
	* C: more than half of the nodes(replicas) have exactly same data state;
	* A: even if there is only one node left up, the system keeps providing service(maybe not consistent)
	* P: assuming there exists network partition

	* Proof of CAP:
		* if network partition happens(P satisfies):
			* if the main node now is in the minority partition, then a write to the main node cannot be spreaded to majority of the quorum, then we have to make a decision about whether we want to obey consistency or we refuse to provide service, that is to say, we have to choose between A and C;
			* if the main node now is in the majority partition, then a write to the main node could be spreaded to majority of the quorum, however, if all the nodes in the majority partition failes then, we have to make a decision about whether we want to follow the consistency priciple or we refuse to provide service, i.e, we have to choose either C or A; Paxos is an example of this kind of model(CP);
		* if there is no network partition(no P): a write to the main node can be spreaded to all nodes in the system, so C is guranteed, and we can provide service even if we have only one node remained; 2PC is an example of this kind of model(CA);


* example systems under CAP scheme:
	* CA (consistency + availability). Examples include full strict quorum protocols, such as two-phase commit.
	* CP (consistency + partition tolerance). Examples include majority quorum
protocols in which minority partitions are unavailable such as Paxos.
	* AP (availability + partition tolerance). Examples include protocols using
conflict resolution, such as Dynamo and Gossip.


