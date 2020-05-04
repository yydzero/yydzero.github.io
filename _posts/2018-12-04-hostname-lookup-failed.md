

## Error

	20181204:00:49:46:002361 gpinitsystem:e9708456f766:test-[FATAL]:-Hostname lookup for host e9708456f766 failed. Script Exiting!


    GP_HOSTNAME=`HOST_LOOKUP $GP_HOSTADDRESS`
	if [ x"$GP_HOSTNAME" = x"__lookup_of_hostname_failed__" ]; then
		ERROR_EXIT "[FATAL]:-Hostname lookup for host $GP_HOSTADDRESS failed." 2
	fi

	GPHOSTCACHELOOKUP=$WORKDIR/lib/gphostcachelookup.py

	HOST_LOOKUP() {
		res=`echo $1 | $GPHOSTCACHELOOKUP`
		err_index=`echo $res | awk '{print index($0,"__lookup_of_hostname_failed__")}'`
		if [ $err_index -ne 0 ]; then
			echo "__lookup_of_hostname_failed__"
		else
			echo $res
		fi
	}


	[test@e9708456f766 lib]$ echo 'abc' | python gphostcachelookup.py
	20181204:01:02:53:004406 gphostcachelookup.py:default-[WARNING]:-Failed to resolve hostname for abc
	__lookup_of_hostname_failed__



	GpInterfaceToHostNameCache class 负责把 interface 转换成 hostname 

	核心命令是：

	logger.debug("hostname lookup for %s" % interface)
	cmd=unix.Hostname('host lookup', ctxt=base.REMOTE, remoteHost=interface)


	class Hostname(Command):
    	def __init__(self, name, ctxt=LOCAL, remoteHost=None):
    	    self.remotehost = remoteHost
    	    Command.__init__(self, name, findCmdInPath('hostname'), ctxt, remoteHost)

    	def get_hostname(self):
    	    if not self.results:
    	        raise Exception, 'Command not yet executed'
    	    return self.results.stdout.strip()

	可见 hostname 是真正获得接口的命令，但是需要使用 ssh 的方式获取，因而
	如果 ssh 不能正常工作，这里的 Hostname class 也不能正常工作，但是
	错误报告非常的模糊，需要改进这里的错误报告。

	$ hostname
	yydzero.local
	$ echo yydzero.local | /Users/yydzero/work/build/master/bin/lib/gphostcachelookup.py
	yydzero.local

## Hostcache

	○ → cat ~/.gphostcache
	yydzero.local:yydzero.local
