## Bootstap of PostgreSQL
* main of initdb.c would first create several directories, then call `bootstap_template1` to fill in the contents of the first database in base/1/ directory; `bootstap_template1` would call `PG_CMD_OPEN` to start a postgres process in bootstap mode by using `popen(/home/gpadmin/pgsrc/build/bin/postgres --boot -x1 -F)`(popen is the wrapper of `fork`, `pipe` and `exec`); then `bootstap_template1` would write the lines of postgres.bki to the postgres process through the pipe, and the stack of the postgres process is like:

```
#0  0x000000332ccc7330 in __read_nocancel () from /lib64/libc.so.6
#1  0x000000332cc6abf3 in _IO_file_xsgetn_internal () from /lib64/libc.so.6
#2  0x000000332cc60f22 in fread () from /lib64/libc.so.6
#3  0x00000000004c5907 in yy_get_next_buffer () at bootscanner.c:1353
#4  0x00000000004c5388 in boot_yylex () at bootscanner.c:1195
#5  0x00000000004c3610 in boot_yyparse () at y.tab.c:1449
#6  0x00000000004c7222 in BootstrapModeMain () at bootstrap.c:500
#7  0x00000000004c7045 in AuxiliaryProcessMain (argc=3, argv=0xb41ad8) at bootstrap.c:413
#8  0x00000000005b3ca3 in main (argc=4, argv=0xb41ad0) at main.c:180
```

* The bootstrap backend doesn't speak SQL, but instead expects commands in a special bootstrap language.
* after `bootstap_template1` in main, it would set up catalog tables like pg_authid, pg_dependent, pg_description, and build system views, schemas, etc, finally, there is a VACUUM for template1, after that, `make_template0` and `make_postgres` are called to copy from template1; note that, these two databases are created by `CREATE DATABASE` command, so their OIDs are volatile across major versions;