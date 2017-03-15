## Linux Scheduler
===================
* For o(1) scheduler, when does the preempt occur?
	* A running process on CPU can wake up another process, and it would mark itself as 'should-be-preempted' in its `thread_info` struct, next time when CPU returns from interrupt handling, it would check whether the running task is marked as to be preempted, if yes, it would trigger the scheduler code;
	* For SMP, tasks on other CPUs can mark the `thread_info` of another CPU;
* For o(1) scheduler, why it does not support interactive tasks well basically?
	* o(n) scheduler does well because it re-calculate the time slice of ALL tasks, including those on the wait queue, so the time slice of interactive tasks would increase;
	* o(1) scheduler re-calculate the time slice of task when the task uses up its time slice, so it does not consider the wait queue basically.
	* o(1) scheduler uses historical sleep time to try to pick out interactive tasks, and give it a chance to stay in the active array after time slice expiration.
* `thread_info` vs `task_struct`
	* Prior to the Linux 2.6 kernel, struct `task_struct` was present at the end of the kernel stack of each process. There was no `thread_info` struct concept. But in Linux 2.6 kernel, instead of `task_struct` being placed at the end of the kernel stack for the process, the `thread_info` struct is placed at the end. This `thread_info` struct contains a pointer to the `task_struct` structure.
	* the reason is: `task_struct` is huge. it's around 1.7KB on a 32 bit machine. on the other hand, you can easily see that `thread_info` is much slimmer. kernel stack is either 4 or 8KB, and either way a 1.7KB is pretty much, so storing a slimmer struct, that points to `task_struct`, immediately saves a lot of stack space and is a scalable solution.
* For realtime processes, o(1) scheduler, for normal processes, CFS is used after kernel 2.6.22
* CFS does not distinguish interactive task, but it works well, because it has no concept of time slice, when a task is in wait queue, its exec time is small, so its virtual time is small, so it would be in the left-down corner of the red-black tree