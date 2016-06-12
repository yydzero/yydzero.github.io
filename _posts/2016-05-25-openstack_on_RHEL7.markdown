---
layout: post
title:  "Install Openstack on RHEL7"
author: 姚延栋
date:   2016-06-03 11:49
categories: openstack RHEL7
published: true
---

## Install Openstack on RHEL7


### setup RHEL repos, prepare prerequisites

    $ unset HISTFILE
    $ sudo subscription-manager register --username <username> --password <password>
    $ sudo subscription-manager attach --auto
    $ sudo subscription-manager repos --enable rhel-7-server-optional-rpms --enable rhel-7-server-extras-rpms

    $ sudo yum [re]install -y https://www.rdoproject.org/repos/rdo-release.rpm
    $ sudo yum update -y
    $ sudo yum [re]install -y openstack-packstack

    If report any error about cpio for urllib3 or python-requests:

    $ sudo pip uninstall requests

### Issues

cheetah could not find:

    python-cheetah.x86_64 : Template engine and code generator
    Repo        : @epel

    Need to change following yum repo as enabled.

    [epel]
    name=Extra Packages for Enterprise Linux 7 - $basearch
    #baseurl=http://download.fedoraproject.org/pub/epel/7/$basearch
    mirrorlist=https://mirrors.fedoraproject.org/metalink?repo=epel-7&arch=$basearch
    failovermethod=priority
    enabled=0
    gpgcheck=1
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

    // then
    $ sudo yum install -y python-cheetah

    Looks like packstack will disable above repo automatically :(  Take a look at following setting:

    # Specify 'y' to enable the EPEL repository (Extra Packages for
    # Enterprise Linux). ['y', 'n']
    CONFIG_USE_EPEL=n

chardet

    ImportError: No module named chardet'.

    ->

    sudo pip uninstall requests
    sudo pip install requests

indexbytes:

    from OpenSSL import crypto
    ImportError: cannot import name indexbytes

    ->
    sudo pip uninstall six
    sudo pip install six

Error: Execution of '/usr/bin/yum -d 0 -e 0 -y install openstack-dashboard' returned 1: Error unpacking rpm package python-XStatic-Font-Awesome-4.3.0.0-1.el7.noarch

    $ sudo rm -rf /usr/lib/python2.7/site-packages/xstatic/pkg/font_awesome/
    $ sudo yum install -y python-XStatic-Font-Awesome-4.3.0.0-1.el7.noarch


### packstack

    $ packstack --answer-file packstack-answers-20160608-120416.txt  -d

