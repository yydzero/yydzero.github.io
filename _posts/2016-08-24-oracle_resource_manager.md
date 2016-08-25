# Oracle Resource Manager
## General introductions
* With resource manager, you can:
	* distribute CPU time
	* create an active **session** pool
	* manage runaway sessions
	* prevent the execution of operations that the optimizer estimates will run for a longer time than a specified limit.
	* Limit the amount of time that a session can be idle. This can be further defined to mean only sessions that are blocking other sessions.
	
* As a database administrator (DBA), you can manually switch a session to a different consumer group. Similarly, an application can run a PL/SQL package procedure that switches its session to a particular consumer group.
* By default, each session in a consumer group shares the resources allocated to that group with other sessions in the group in a round robin fashion.
* The Resource Manager allocates resources to consumer groups according to the set of resource plan directives (directives) that belong to the currently active resource plan. There is a parent-child relationship between a resource plan and its resource plan directives. Each directive references one consumer group, and no two directives for the currently active plan can reference the same consumer group.
* only one resource plan is active at a time. When a resource plan is active, each of its child resource plan directives controls resource allocation for a different consumer group. Each plan must include a directive that allocates resources to the consumer group named OTHER_GROUPS. OTHER_GROUPS applies to all sessions that belong to a consumer group that is not part of the currently active plan.
* The currently active resource plan does not enforce allocation limits until CPU usage is at 100%. If the CPU usage is below 100%, the database is not CPU-bound and hence there is no need to enforce limits to ensure that all sessions get their designated resource allocation. In addition, when limits are enforced, unused allocation by any consumer group can be used by other consumer groups. In the previous example, if the OLTP group does not use all of its allocation, the Resource Manager permits the REPORTS group or OTHER_GROUPS group to use the unused allocation.

## Resource Plan Directives
* Each directive can specify a number of different methods for allocating resources to its consumer group or subplan
* You can control the maximum number of concurrently active sessions allowed within a consumer group. This maximum defines the active session pool. An active session is a session that is in a call. It is considered active even if it is blocked, for example waiting for an I/O request to complete. When the active session pool is full, a session that is trying to process a call is placed into a queue. When an active session completes, the first session in the queue can then be removed from the queue and scheduled for execution. You can also specify a period after which a session in the execution queue times out, causing the call to terminate with an error.
* Automatic Consumer Group Switching. This method enables you to control resource allocation by specifying criteria that, if met, causes the automatic switching of a session to a specified consumer group. Typically, this method is used to switch a session from a high-priority consumer group—one that receives a high proportion of system resources—to a lower priority consumer group because that session exceeded the expected resource consumption for a typical session in the group.
* You can also specify directives to cancel long-running SQL queries or to terminate long-running sessions based on the amount of system resources consumed.(Runaway detection)
* Execution Time Limit. You can specify a maximum execution time allowed for an operation. If the database estimates that an operation will run longer than the specified maximum execution time, the operation is terminated with an error.
* You can specify an amount of time that a session can be idle, after which it is terminated. You can also specify a more stringent idle time limit that applies to sessions that are idle and blocking other sessions.

## Notes
* How to understand high throughput, low latency, high concurrency and scalability?
	* Ideally, a system should have high throughput, low latency and high concurrency, and should perform better or at least not worth with the increasing scale;
	* Realistically, users do not care about concurrency that much, they care about how much time the system would take to finish a specific number of jobs(this is my understanding for low latency, latency is the total time taken for specific jobs); when system offers same latency, then users care about high throughput(inverse of average response time, the order of execution can effect the throughput even if latency does not change, for example, short query bias can increase throughput); these two can be catagorised as performance, and concurrency is an input variable which effects performance; it can have good effects or bad effects, which depends on whether it is perfectly linear concurrency or worse than linear or better than linear;
	* reasons accounting for worse than linear concurrency include:
		* context switch
		* lock conflicts on shared resources
	* reasons accounting for better than linear concurrency include:
		* cooperative caching
		* full utilization of spare resources(RAM, or CPUs on SMP machine, etc) of sequential tasks
	* scalability means that performance should not be worse when scaling up;