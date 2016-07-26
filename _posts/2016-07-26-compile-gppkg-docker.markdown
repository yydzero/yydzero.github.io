---
layout: post
title:  "Build postgis gppkg in GPDB43 docker"
subtitle:  "如何在docker中编译postgis的gppkg包"
author: 刘奎恩/Kuien
date:   2016-07-26 10:48 +0800
categories: docker 
published: true
---

### 0. quick fix commit is ready

Latest commit: https://github.com/greenplum-db/gpdb4/pull/49/commits/76d91d240b4f9647e32ee8030785befb9ab81697

    Quick fix to build on fresh pivotaldata/centos511-java7-gpdb-dev-image

    1. remove json related parts in configure to avoid version conflict
    2. remove *.la in lib geos to correct path error
    3. replace prefix in xml2-config to actual path


### 1. create a fresh docker from pivotaldata/centos511-java7-gpdb-dev-image

    sudo docker create -t --name gppkg pivotaldata/centos511-java7-gpdb-dev-image /bin/bash
    sudo docker start gppkg
    sudo docker exec -u gpadmin -it gppkg /bin/bash

Here, I config the docker with account 'gpadmin', create a directory '~/workspace' to keep the gpdb4, add 'gpadmin' into sudoers, upload ssh pubkey to github.

### 2. download source-code of gpdb4 from github

    git clone git@github.com:greenplum-db/gpdb4.git
    git submodule update --init --recursive gpAux/extensions/pgbouncer/source

### 3. download 3rd party libs from IVY

    source /opt/gcc_env.sh
    sudo chgrp -R gpadmin /opt && sudo chmod g+w -R /opt
    make sync_tools -C gpAux

### 4. switch to branch 'postgis_gppkg'

    git remote add kuien git@github.com:kuien/gpdb4.git
    git remote update kuien
    git checkout -b postgis_gppkg -t kuien/postgis_gppkg
    
### 5. compile gpdb4 and gppkg

    make GPHOME=`pwd` BLD_TARGETS="gppkg" dist -j40

I met two trivial issues about dependent tools, solved as following:

    ln -s /opt/releng/tools/third-party/ext/2.2/rhel5_x86_64/python-2.6.2 /opt/python-2.6.2
    cp /opt/releng/apache-ant/lib/ivy-2.2.0.jar ~/.ant/lib/ivy.jar #network is soooo slow to download the official version for comparison.

You can also build it in:

		cd ~/workspace/gpdb4/gpAux/extensions/postgis-2.0.3/package
		make INSTLOC=$GPHOME

### 6. Check the results

    ls -lh /home/gpadmin/workspace/gpdb4/gpAux/extensions/postgis-2.0.3/package/*.gppkg
    -rw-rw-r-- 1 gpadmin gpadmin 9.2M Jul 25 07:04 /home/gpadmin/workspace/gpdb4/gpAux/extensions/postgis-2.0.3/package/postgis-ossv2.0.3_pv2.0.1_gpdb4.3orca-rhel5-x86_64.gppkg

### 7. Run regression of posts after installation

    gppkg -i postgis-ossv2.0.3_pv2.0.1_gpdb4.3orca-rhel5-x86_64.gppkg
    cd postgis-test/   # a tiny package I pick from postgis source.
    make prepare postgis
