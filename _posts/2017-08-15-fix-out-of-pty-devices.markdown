---
layout: post
title: Fix "out of pty devices" in Guardian containers
date: 2017-08-15 16:00:00 +0800
comments: true
---

## Who are affected

Some certain Linux distros as Guardian containers, like SLES jobs on Concourse.

## How to reproduce

Create a SLES 11 SP4 Guardian container, then

    # useradd john
    # su - john
    $ python -c "import pty; pty.fork()"
    ...
    OSError: out of pty devices

## Why is this

> A pseudo TTY (or "PTY") is a pair of devices — a slave and a master — that provide a special sort of communication channel.

> Linux has a virtual filesystem called `devpts` that is normally mounted at `/dev/pts`. Whenever a new pseudo TTY is created, a device node for the slave is created in that virtual filesystem.

> "Unix98" Single Unix Specification (SUS) requires that the group ID of the slave device should not be that of the creating process, but rather some definite, though unspecified, value. The GNU C Library (glibc) takes responsibility for implementing this requirement; it quite reasonably chooses the ID of the group named "tty" (often 5) to fill this role. If the devpts filesystem is mounted with options gid=5,mode=620, this group ID and the required access mode will be used and glibc will be happy. If not, glibc will (if so configured) run a setuid helper found at /usr/libexec/pt\_chown. 

The problem is some Linux distros don't provide the setuid helper `pt_chown`, if `devpts` is not mounted with option `gid=5`, the device node could not be created with `tty` group.

## Fix and workaround

Guardian's default mount options are fixed now, workaround is adding normal users into `tty` group.

### ref:
1, [https://lwn.net/Articles/688809/](https://lwn.net/Articles/688809/)  
2, [https://en.wikipedia.org/wiki/Single\_UNIX\_Specification](https://en.wikipedia.org/wiki/Single_UNIX_Specification)  
3, [http://adam8157.info/blog/2017/08/fix-out-of-pty-devices/](http://adam8157.info/blog/2017/08/fix-out-of-pty-devices/)
