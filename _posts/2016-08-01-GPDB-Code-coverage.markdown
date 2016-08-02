---
layout: post
title:  "How to generate code coverage for GPDB"
subtitle: "怎么生成GPDB的代码覆盖率"
author: Pengzhou Tang
date:   2016-08-01 13:10:43
---

## 1. Install lcov by using yum 

## 2. Compile GPDB with gcov enabled

```
./configure xxxxxxxxx --enable-coverage
make
make install
```

In this step, you may need to modify following two files to let make pass

```
diff --git a/src/bin/gpfdist/Makefile b/src/bin/gpfdist/Makefile
index 858b8b7..eb8c470 100644
--- a/src/bin/gpfdist/Makefile
+++ b/src/bin/gpfdist/Makefile
@@ -40,7 +40,7 @@ gfile.c: $(top_builddir)/src/backend/utils/misc/fstream/gfile.c

 gpfdist$(EXE_EXT): $(OBJS)
-       $(CC) $(LDFLAGS) $(OBJS) $(LDLIBS) -o $@
+       $(CC) $(LDFLAGS) $(CLAGS) $(OBJS) $(LDLIBS) -o $@

 install: all

diff --git a/src/bin/pg_basebackup/Makefile b/src/bin/pg_basebackup/Makefile
index 2150988..0c8e514 100644
--- a/src/bin/pg_basebackup/Makefile
+++ b/src/bin/pg_basebackup/Makefile
@@ -17,7 +17,7 @@ top_builddir = ../../..
 include $(top_builddir)/src/Makefile.global

 ifneq ($(PORTNAME), win32)
-override CFLAGS := -I$(libpq_srcdir) $(CPPFLAGS) $(PTHREAD_CFLAGS) -pthread
+override CFLAGS := -I$(libpq_srcdir) $(CPPFLAGS) $(PTHREAD_CFLAGS) $(CFLAGS) -pthread
 endif
```

## 3. Run test suite like installcheck-good

## 4. Generate code coverage
take dispatcher for example.

```
$ cd src/backend/cdb/dispatcher/
$ lcov --capture --directory . --output-file gpdb-dispatcher-test.info --test-name gpdb-dispatcher
$ genhtml gpdb-dispatcher-test.info --output-directory /tmp/dispatcher-coverage --title "gpdb dispatcher coverage test" --show-details --legend
```

## 5. Open html on browser
