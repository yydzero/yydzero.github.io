linux overcommit_memory
=======================
* This file contains the kernel virtual memory accounting mode. Values are:
	* 0: heuristic overcommit (this is the default)
	* 1: always overcommit, never check
	* 2: always check, never overcommit

In mode 0, calls of mmap(2) with MAP_NORESERVE are not checked, and the default check is very weak, leading to the risk of get-ting a process "OOM-killed". Under Linux 2.4 any non-zero value implies mode 1. In mode 2 (available since Linux 2.6), the total virtual address space on the system is limited to (SS + RAM*(r/100)), where SS is the size of the swap space, and RAM is the size of the physical memory, and r is the contents of the file /proc/sys/vm/overcommit_ratio.

* The simple answer is that setting overcommit to 1, will make it when a program calls something like  malloc() to allocate a chunk of memory (man 3 malloc), it always succeeds regardless if the system knows it will have all the memory asked for. The underlying concept to understand is the idea of virtual memory. Programs see a virtual address space that may, or may not, be mapped to actual physical memory. By disabling overcommit checking, you tell the OS to just assume that there is always enough physical memory to back up the virtual space.