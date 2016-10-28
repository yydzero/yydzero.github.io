## Compile gpdb4
* gcc must use gcc-4.4.2 and corresponding gcc_infrastructure, which contains the flex;
* must source gcc_env.sh before compiling;
* there must be at least a symbolic link for python package in the originally installed location of python(python may be moved to other places, while the original install location is recorded in python's makefile, and can be used by python libraries, such as sysconfig.get_config_var('LIBDIR')), which then can lead to link error;
* jdk-1.6 is required, not 1.7 or 1.8
* put the credentials of make sync_tools into the build command, because gphdfs need to download libraries from repo.pivotal.io