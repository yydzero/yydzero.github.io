---
layout: post
title:  "How to extend VMware disk size"
subtitle:  "如何扩展VMware虚拟机的磁盘空间"
author: 刘奎恩 王淏舟
date:   2016-03-06 14:07:24
categories: tools vmware disk resize
published: true
---

When we run _make installcheck-good_, the test *uao_compaction/index2* may
consume lots of disk space. Here we record the operation log we used to resize
the vmware disk space.

1. adjust \*.vmdk 's size through vmware menu, for example, 20G -> 30G.

2. create primary disk partition using 'sudo fdisk /dev/sda', enter:
	* 'n': new partition
	* 'p': primary partition
	* '3': partition number, /dev/sda3
	* 'w': save and exit

3. config this partition using 'sudo fdisk /dev/sda', enter:
	* 't': change partition
	* '3': partition number
	* '8e': for LVM
	* 'w': save and exit

4. run 'partprobe' to make this partition detectable.

5. format this partition using 'mkfs.xfs /dev/sda3' before mount

6. extend it to root fs
	* wipe it using 'sudo pvcreate /dev/sda3'
	* extend using 'sudo vgextend rhel /dev/sda3'
		. using 'df -lh' to find the lvm group name, for mine, it is
		```
		Filesystem             Size  Used Avail Use% Mounted on
		/dev/mapper/rhel-root   18G   17G  612M  97% /
		devtmpfs               1.9G     0  1.9G   0% /dev
		```
	* display it using 'sudo vgdisplay' to confirm the free space
	* expend LVM space: 'sudo lvextend -L +10G /dev/rhel/root /dev/sda3'
	* expend it onto fs: 'sudo xfs_growfs /dev/rhel/root'

7. run 'fdisk -l' and 'df -lh' to see what happens, good luck!
