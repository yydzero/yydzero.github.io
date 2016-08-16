---
layout: post
title:  "relocate docker to another disk"
subtitle:  "将Docker移动到其他磁盘"
author: 刘奎恩/Kuien, Peifeng Qiu
date:   2016-08-16 14:48 +0800
categories: docker 
published: true
---

### why we need to move docker to another disk?

in the beginning, we setup a docker env for testing, and we find it is easy to deploy multiple rhel5 and rhel6 for developing and concurse pipeline, so we do this without  hesitation.

So on, /root is used out quickly, while /data1 and /data2 remain 12TB free space with nothing. I know we should mount ~ on to those disk in the beginning, but currently, let us move docker to those disks.

### solution

__in host__:

```sh
service docker stop
cp -R /var/lib/docker /data1/
vi /etc/sysconfig/docker
	edit the option with '-g /PATH'
service docker start
```

after you confirm your docker on new location work well, remove old images and containers. DO NOT remove the whole /var/lib/docker directory before you make sure those certs are useless forever.

### useful tips

__in host__:

If you want to use gdb in Docker, you may run into a "ptrace: Operation not permitted" error. We found a workaround, which is to re-run the container with new flags:

```sh
docker run -t -v <absolute path to gpdb4 directory>:/home/gpadmin/gpdb4 --privileged --security-opt seccomp:unconfined -i pivotaldata/centos511-java7-gpdb-dev-image bash
```
> See [this post](https://forums.docker.com/t/boot2docker-mac-os-x-1-10-failing-ptrace-gdb/6005). I have also updated the mounted docker guide. The simplest way to resolve is to destroy your gpdb4 container/image and redo the guide from the start, although you could commit your gpdb4 container to an image and use docker run on that...
>   -- from Amil Khanzada <akhanzada@pivotal.io>

We perform following commands to verify it:

```sh
docker commit -m "gppkg" gppkg gppkg-img
docker create -it --privileged --security-opt seccomp:unconfined --name gpdb4-dev gppkg-img /bin/bash
docker start gpdb4-dev
docker exec -u gpadmin -it gpdb4-dev /bin/bash
```

Now we can `gdb` in new container gpdb4-dev.
