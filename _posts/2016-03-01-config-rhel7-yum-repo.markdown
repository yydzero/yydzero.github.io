---
layout: post
title:  "如何配置RHEL7上的yum repo"
author: 刘奎恩 王淏舟
date:   2016-03-01 18:01:24
categories: rhel yum repo
published: true
---

To install dependent 3rd-party libraries, we use YUM to install them. But the default
repo of yum on RHEL 7 is really slow, I suggest you use below yum repo from USTC or
163:

* [USTC mirror](https://lug.ustc.edu.cn/wiki/mirrors/help/centos)

* [163 mirror](http://mirrors.163.com/.help/centos.html)

For example, for 163, you can:
1. download the repo file from: http://mirrors.163.com/.help/CentOS7-Base-163.repo

2. modify the file using
   ```
   sudo sed -i 's/\$releasever/7/g' CentOS7-Base-163.rep
   ```

3. copy it to /etc/yum.repo.d/

4. run 'yum makecache' to verify it

5. enjoy

Besides, sometime you may meet a problem that 'redhat.repo' is always re-created
and invoked by yum, it's boring and slow. You can try following way to disable
it (maybe not the best way):
	```
	vim /etc/yum.config and set 'plugins=0'
	```


For example, PostGIS requires at least these 3rd party libraries: json-c, geos, proj4, gdal and expat. The libaraies json-c and expat can be download from [base source][1], the other three
libraies need to be download from [epel source][2].


[1]: {{ site.url }}/download/epel.repo
[2]: {{ site.url }}/download/CentOS-Base.repo
