## LD_PRELOAD
* LD_PRELOAD only works when starting the process; if a process has already been running, LD_PRELOAD cannot override the functions in shared library, you can only use tools like dtrace;