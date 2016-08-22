Computations primarily benefit from high-end hardware to the extent to which they can replace slow network accesses with internal memory accesses. The performance advantage of high-end hardware is limited in tasks that require large amounts of communication between nodes.

Scalability:
* adding more nodes should make the system linearly faster;
* growing the dataset should not increase latency
* it should be possible to use multiple data centers to reduce the time it takes to respond to user queries, while dealing with cross-data center latency in some sensible manner.
* adding more nodes should not increase the administrative costs of the system (e.g. the administrators-to-machines ratio).

Measure of scalability:
* performance
	* Short response time/low latency for a given piece of work
	* High throughput
	* Low utilization of computing resource(s)

* availability

A system that makes weaker guarantees has more freedom of action, and hence
potentially greater performance - but it is also potentially hard to reason
about. People are better at reasoning about systems that work like a single
system, rather than a collection of nodes.

network partitions (e.g. total network failure between some nodes)
A network partition occurs when the network fails while the nodes themselves
remain operational. 

There are two basic techniques that can be applied to a data set. It can be
split over multiple nodes (partitioning) to allow for more parallel processing.
It can also be copied or cached on different nodes to reduce the distance
between the client and the server and for greater fault tolerance (replication).
* partition
	* Partitioning improves performance by limiting the amount of data to be
	examined and by locating related data in the same partition
	* Partitioning improves availability by allowing partitions to fail
	independently, increasing the number of nodes that need to fail before
	availability is sacrificed
* replicate
	* Replication improves performance by making additional computing power and
	bandwidth applicable to a new copy of the data
	* Replication improves availability by creating additional copies of the data,
	increasing the number of nodes that need to fail before availability is
	sacrificed

Replication is also the source of many of the problems

Only one consistency model for replication - strong consistency - allows you to
program as-if the underlying data was not replicated. Other consistency models
expose some internals of the replication to the programmer. However, weaker
consistency models can provide lower latency and higher availability - and are
not necessarily harder to understand, just different.

System model: a set of assumptions about the environment and facilities on which a distributed
system is implemented. Assumptions include:
* what capabilities the nodes have and how they may fail
* how communication links operate and how they may fail and
* properties of the overall system, such as assumptions about time and order

The synchronous system model imposes many constraints on time and order. It
essentially assumes that the nodes have the same experience: that messages that
are sent are always received within a particular maximum transmission delay, and
that processes execute in lock-step. This is convenient, because it allows you
as the system designer to make assumptions about time and order, while the
asynchronous system model doesn't.

It is easier to solve problems in the synchronous system model, because
assumptions about execution speeds, maximum message transmission delays and
clock accuracy all help in solving problems since you can make inferences based
on those assumptions and rule out inconvenient failure scenarios by assuming
they never occur.

Of course, assuming the synchronous system model is not particularly realistic.
Real-world networks are subject to failures and there are no hard bounds on
message delay. Real world systems are at best partially synchronous: they may
occasionally work correctly and provide some upper bounds, but there will be
times where messages are delayed indefinitely and clocks are out of sync.

Two impossibility results:
* FLP
* CAP

FLP result states that "there does not exist a (deterministic) algorithm for the
consensus problem in an asynchronous system subject to failures, even if
messages can never be lost, at most one process may fail, and it can only fail
by crashing (stopping executing)".

This impossibility result is important because it highlights that assuming the
asynchronous system model leads to a tradeoff: algorithms that solve the
consensus problem must either give up safety or liveness when the guarantees
regarding bounds on message delivery do not hold.

CAP:
* Consistency: all nodes see the same data at the same time.
* Availability: node failures do not prevent survivors from continuing to operate.
* Partition tolerance: the system continues to operate despite message loss due to
network and/or node failure

examples:(QQ)
* CA (consistency + availability). Examples include full strict quorum protocols,
such as two-phase commit.
* CP (consistency + partition tolerance). Examples include majority quorum
protocols in which minority partitions are unavailable such as Paxos.
* AP (availability + partition tolerance). Examples include protocols using
conflict resolution, such as Dynamo.

Consistency model:
a contract between programmer and system, wherein the system guarantees that if
the programmer follows some specific rules, the results of operations on the
data store will be predictable

Strong consistency models (capable of maintaining a single copy)
* Linearizable consistency
* Sequential consistency
Weak consistency models (not strong)
* Client-centric consistency models
* Causal consistency: strongest model available
* Eventual consistency models

My understanding of CAP:
C: more than half of the nodes(replicas) have exactly same data state;
A: even if there is only one node left up, the system keeps providing
service(maybe not consistent)
P: assuming there exists network partition

Proof of CAP:
* if network partition happens(P satisfies):
	* if the main node now is in the minority partition, then a write to the
	  main node cannot be spreaded to majority of the quorum, then we have to
	  make a decision about whether we want to obey consistency or we refuse to
	  provide service, that is to say, we have to choose between A and C;
	* if the main node now is in the majority partition, then a write to the
	main node could be spreaded to majority of the quorum, however, if all the
	nodes in the majority partition failes then, we have to make a decision
	about whether we want to follow the consistency priciple or we refuse to
	provide service, i.e, we have to choose either C or A; Paxos is an example
	of this kind of model(CP);
* if there is no network partition(no P):
	a write to the main node can be spreaded to all nodes in the system, so C is
	guranteed, and we can provide service even if we have only one node
	remained; 2PC is an example of this kind of model(CA);
