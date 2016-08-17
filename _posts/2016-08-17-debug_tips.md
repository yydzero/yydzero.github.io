## Debug Tips
* If a python process is hanging, we can use GDB to attach to this process and `bt`, then if python debug-info is installed, we can see we are stuck at which line of which python file; the variable is f;
* Remember to check the child process of the python process, it is common a python process is hanging waiting for the exit of its child process;