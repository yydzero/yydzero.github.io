---
layout: post
title:  "Import well prepared GPDB43 docker"
subtitle:  "如何导入做好的GPDB43 docker"
author: 刘奎恩/Kuien, Adam Lee
date:   2016-07-13 14:08
categories: coding
published: true
---

## prepare the docker images and containers (on my host)

    docker save -o centos511-java7-gpdb-dev-image.tar pivotal/centos511-java7-gpdb-dev-image
    docker ps -a  # find out the container id you wanna export
    docker export 15d7534d2c68 > gpdb43-centos511-docker.tar

## import gpdb43 standard docker (on your host)

a. start your docker container engine

    yum install docker docker-registry docker-engine
    service start docker

b. import gpdb43 standard docker image

    scp gpadmin@10.153.101.111:~/centos511-java7-gpdb-dev-image.tar ./
    docker load --input centos511-java7-gpdb-dev-image.tar

c. import gpdb43 docker container

    scp gpadmin@10.153.101.111:~/gpdb43-centos511-docker.tar ./
    docker import gpdb43-centos511-docker.tar test/gpdb4
    docker create -it --name gpdb4-test --user gpadmin test/gpdb4 /bin/bash

d. start the docker

    docker start gpdb4-test
    docker exec -it gpdb4-test /bin/bash

e. find src and bin of gpdb4

	ls /usr/local/greenplum-db-devl
	ls /root/workspace/gpdb4

## compile gpdb43 in docker (on your host)
	
	click [compile gpdb43 in docker](http://gpdb.rocks/coding/2016/07/06/gpdb43-docker.html)
