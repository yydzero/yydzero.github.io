---
layout: post
title:   Dockers of gpdb/ldap/kerberos
 cluster
author: Violet Cheng
date:   2017-01-20
categories: GPDB
---


(https://github.com/yydzero/dockerfiles)

This project is under kerberos-dockers folder of the repo. It has 4 dockerfiles and one bash script to start them and create a cluster with kerberos server/ldap server/gpdb server/client containers.

# How To Use

This dockers create a kdc server, a ldap server, a gpdb server that enabled kerberos/ldap login, and a client with psql and kerberos/ldap clients installed.

Notice:

* The script will using local machine's 5432 port, if local machine's 5432 port is occupied, it will fail to start the gpdb container.
* The script will test gpdb container using psql, so please make sure you have psql installed in your local machine.


To start with cached docker images

    $ ./run.sh

To re-build all the docker images

	$ ./run.sh -r
	
To shut down and rm all startup containers created by this script
	
	$ ./run.sh -s

## Change pre-defined variables
run.sh has several predifined variables. They are mainly for kerberos setting and gpdb user create. You can change them to what you like.

* REALM_NAME 

	kerberos realm name
	
* DOMAIN_NAME
	
	kerberos domain name

* USER_NAME
	
	The gpdb user used to login through kerberos
	
* USER_PASSWORD

	The password for all kerberos/ldap users.

* LDAP_USER_NAME
	
	The gpdb user used to login through ldap non-ssl/tls
	
	For tls/ssl ldap login, a "\_tls" and "\_s" suffix will be append to LDAP\_USER\_NAME. For example, if LDAP\_USER\_NAME is "Patrick", then you can use "Patrick\_tls" and "Patrick\_s" to login through tls/ssl.
	
## Using client container to run psql

After run.sh finished, three containers will be up, kdc/gpdb/client. Client container will test kerberos login and execute '\l' command through psql.

You can attach to client and play it by yourself.

	$ docker attach client



## Using the kerberos server and set your local machine

During the run.sh running, it will print out "temp dir" path. It located at ~/tmp/.

You can find our krb5.conf and the keytab file in the path. If you have kerberos workstation installed in your machine, you can copy ther krb5.conf into /etc/ and start to use kdc container as kerberos service server.

To install kerberos workstation in centos:

	$ sudo yum install krb5-workstation krb5-libs
