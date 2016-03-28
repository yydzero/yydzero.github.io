==> Linux has a memory killer mechanism, to kill processes when OOM happens,
	based on a score system, which can be seen in /proc/pid/oom_score; with
	higher score, the process has higher priority to be killed(oom_adj can
	be set to proper value to let processes immune from the killer); kernel
	adds SIGKILL or SIGTERM(for processes that have hardware accesses) to the
	to do list of the process;
