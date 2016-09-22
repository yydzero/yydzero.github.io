## Debug Tips
* If a python process is hanging, we can use GDB to attach to this process and `bt`, then if python debug-info is installed, we can see we are stuck at which line of which python file; the variable is f;
* Remember to check the child process of the python process, it is common a python process is hanging waiting for the exit of its child process;
* if `ssh sdw1 "command_to_be_executed"` fails, while `ssh sdw1; command_to_be_executed` succeeds, the root cause may be python cannot import paramiko module, we should check whether the module is successfully installed, or the $PYTHONPATH can find that module; paramiko module is used by python for ssh related work;
* gpstart -v and ssh -vvv are very useful tips for debugging;