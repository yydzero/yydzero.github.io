cd gpAux & make sync_tools
cd .. & git submodule --init --recursive ...pgbouncer
cd gpAux & make BLD_ARCH='rhel5_x86_64' HOME=`pwd` devel
