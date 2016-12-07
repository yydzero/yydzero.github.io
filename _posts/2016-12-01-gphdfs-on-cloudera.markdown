---
layout: post
title:  "setup gpdb with gphdfs and kerberos in Cloudera VM"
subtitle:  "在Cloudera中搭建带gphdfs和kerberos的GPDB"
author: Kuien Liu, Yuan Zhao, Haozhou Wang
date:   2016-12-01 12:53 +0800
categories: tools
published: true
---

## Setup gphdfs environment

* If you need a stand alone hdfs distribution, find the fastest mirror [here](http://www.apache.org/dyn/closer.cgi/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz).
* If you need a running hdfs service. Please refer to (hdfs)[../1.html]
* If you need to setup gphdfs with stand alone hdfs service, please refer to (Peifeng and Haozhou's blog)[http://gpdb.rocks/tools/2016/10/24/gphdfs-format.html]

In following section we record tips on how to setup gphdfs on Cloudera VM.

```sh
echo "export JAVA_HOME=/usr/java/jdk1.7.0.xxx" >> ~/.bashrc
echo "export HADOOP_HOME=/usr/lib/hadoop/client" >> ~/.bashrc

source ~/.bashrc
gpstop -arf
psql postgres
```

in gpdb

```sql
set gp_hadoop_home '/usr/lib/hadoop/client';
set gp_hadoop_target_version 'gphd-2.0';

create external table r (src text)
    location ('gphdfs://quickstart.cloudera:8082/gpdb/')
	format 'text';

select * from r;
```

## Setup kerberos for PSQL 

Add /lib64 into the LD_LIBRARY_PATH
```
export LD_LIBRARY_PATH=/lib64:$LD_LIBRARY_PATH
```
switch to the admin user, then run the command line
```
kadmin.local
```
In greenplum database, principal is greenplum database role using kerberos authentication, so we need to add a principal for a specific user:
```
addprinc test/kerberos-gpdb@CLOUDERA
addprinc postgres/master.test.com@CLOUDERA
```
The first addprinc creates a greenplum database user as a principal,test/kerberos-gpdb.
The second addprinc creates the postgres process on the greenplum database master host as a principal in the kerberos KDC.
The principal is required when using kerberos authentication with greenplum database. 
get the principal
```
getprinc test@CLOUDERA

```
generate the content of keytab file, the following example creates a keytab file gpdb-kerberos.keytab in the current directory with authentication infomation for the principal.
```
xst -k gpdb.keytab test/kerberos-gpdb@CLOUDERA postgres/quickstart.cloudera@CLOUDERA 
```

```
kinit -kt ~/gpdb.keytab postgres/quickstart.cloudera@CLOUDERA kinit -kt ~/gpdb.keytab postgres/quickstart.cloudera@CLOUDERA
```

You may verify it with following commands

```
klist
kdestory
```
## Setup kerberos for hadoop 



After the kerberos configured completed, user need to connect to the database with a full command like this:
```
sudo kadmin.local

kadmin.local:  addprinc -randkey hdfs/gpadmin@CLOUDERA 
kadmin.local:  addprinc -randkey mapred/gpadmin@CLOUDERA 
kadmin.local:  addprinc -randkey yarn/gpadmin@CLOUDERA
kadmin.local:  addprinc -randkey HTTP/gpadmin@CLOUDERA
kadmin.local:  xst -norandkey -k hdfs.keytab hdfs/gpadmin@CLOUDERA HTTP/gpadmin@CLOUDERA 
kadmin.local:  xst -norandkey -k mapred.keytab mapred/gpadmin@CLOUDERA HTTP/gpadmin@CLOUDERA 
kadmin.local:  xst -norandkey -k yarn.keytab yarn/gpadmin@CLOUDERA HTTP/gpadmin@CLOUDERA 

```

Change owner and group information:
```
sudo chown hdfs:hadoop /etc/hadoop/conf/hdfs.keytab
sudo chown mapred:hadoop /etc/hadoop/conf/mapred.keytab
sudo chown yarn:hadoop /etc/hadoop/conf/yarn.keytab
sudo chmod 400 /etc/hadoop/conf/*.keytab

```
###shutdown the cluster with the command:
```
for x in `cd /etc/init.d ; ls hadoop-*` ; do sudo service $x stop ; done

```

####Enable hadoop security
To enable hadoop security, add following properties to core-site.xml file on every machine in the cluster:
```
<property>
  <name>hadoop.security.authentication</name>
  <value>kerberos</value> <!-- A value of "simple" would disable security. -->
</property>

<property>
  <name>hadoop.security.authorization</name>
  <value>true</value>
</property>

```
#### Enable service-level authentication for hadoop service
The hadoop-policy.xml file maintains access control list(ACL) for hadoop service. Each ACL consists of comma-seperated list of users and groups seperated by space.
If you only want to specify a set of users, add a comma-seperated list of users followed by a blank space.Similarly, to specify only authorized groups, use a blank space at the beginning. A * can be used to give access to all users.
For example, to give users, ann,bob and groups, group_a, group_b access to hadoop's dataNodeProtocol service,modify the security.datanode.protocol.acl property in hadoop-policy.xml. Similarly, to give all users access to the interTrackerProtocol service, modify security.inter.tracker.protocol.acl as following:
```
<property>
    <name>security.datanode.protocol.acl</name>
    <value>ann,bob group_a,group_b</value>
    <description>ACL for DatanodeProtocol, which is used by datanodes to 
    communicate with the namenode.</description>
</property>

<property>
    <name>security.inter.tracker.protocol.acl</name>
    <value>*</value>
    <description>ACL for InterTrackerProtocol, which is used by tasktrackers to 
    communicate with the jobtracker.</description>
</property>

```
####configured secure hdfs
When following the instructions in this section to config the properties in the hdfs-site.xml file, keep the following important guidlines in mind:
* The properties for each deamon(NameNode, Secondary Namenode and Datanode) must specify both the HDFS and HTTP principals, as well as the path to HDFS keytab file.
* The kerberos principal for the Namenode, Secondary Namenode and Datanode are configured in the hdfs-site.xml file. The same HDFS-site.xml file with all three principals must in installed on every host machinein the cluster. That is, it is not suffivient to have the NameNode princitals configured on the Namenode host machine only. This is because, for example, the datanode must know the principal name of the namenode in order to send heartbeat to it. kerberos authentication is bi-directional. 
* The special string _HOST in the properties is replaced at run-time by the fully qualified domain name if the host machine where the deamon process is running. This requires that the reserce DNS is properly working on all the hosts configured this way. You may use _HOST only as the entireof the second component of a principal name. For example, hdfs/_HOST@YOUR-REALM.COM is valid, but hdfs._HOST@YOUR-REALM.COM and hdfs/_HOST.example.com@YOUR-REALM.COM are not.
* When performing the _HOST substitution for the Kerberos principal names, the NameNode determines its own hostname based on the configured value of fs.default.name, whereas the DataNodes determine their hostnames based on the result of reverse DNS resolution on the DataNode hosts. Likewise, the JobTracker uses the configured value of mapred.job.tracker to determine its hostname whereas the TaskTrackers, like the DataNodes, use reverse DNS.
* The dfs.datanode.address and dfs.datanode.http.address port numbers for the DataNode must be below 1024, because this provides part of the security mechanism to make it impossible for a user to run a map task which impersonates a DataNode. The port numbers for the NameNode and Secondary NameNode can be anything you want, but the default port numbers are good ones to use.


Continue reading:
* To configure [secure HDFS](https://www.cloudera.com/documentation/enterprise/5-8-x/topics/cdh_sg_secure_hdfs_config.html#concept_nsy_21z_xn)
* To enable [TLS/SSL for HDFS](https://www.cloudera.com/documentation/enterprise/5-8-x/topics/cdh_sg_secure_hdfs_config.html#concept_kk4_41z_xn)

###Set Variables for Secure DataNodes

In order to allow DataNodes to start on a secure Hadoop cluster, you must set the following variables on all DataNodes in /etc/default/hadoop-hdfs-datanode.
```
export HADOOP_SECURE_DN_USER=hdfs
export HADOOP_SECURE_DN_PID_DIR=/var/lib/hadoop-hdfs
export HADOOP_SECURE_DN_LOG_DIR=/var/log/hadoop-hdfs
export JSVC_HOME=/usr/lib/bigtop-utils/

```
Note:
Depending on the version of Linux you are using, you may not have the /usr/lib/bigtop-utils directory on your system. If that is the case, set the JSVC_HOME variable to the /usr/libexec/bigtop-utils directory by using this command:
```export JSVC_HOME=/usr/libexec/bigtop-utils```

###Start up the NameNode

You are now ready to start the NameNode. Use the service command to run the /etc/init.d script.
```$ sudo service hadoop-hdfs-namenode start```
You can verify that the NameNode is working properly by opening a web browser to http://machine:50070/ where machine is the name of the machine where the NameNode is running.

Cloudera also recommends testing that the NameNode is working properly by performing a metadata-only HDFS operation, which will now require correct Kerberos credentials. For example:
```hadoop fs -ls```
Information about the kinit Command
* Important:
Running the hadoop fs -ls command will fail if you do not have a valid Kerberos ticket in your credentials cache. You can examine the Kerberos tickets currently in your credentials cache by running the klist command. You can obtain a ticket by running the kinit command and either specifying a keytab file containing credentials, or entering the password for your principal. If you do not have a valid ticket, you will receive an error such as:
```
11/01/04 12:08:12 WARN ipc.Client: Exception encountered while connecting to the server : javax.security.sasl.SaslException:
 GSS initiate failed [Caused by GSSException: No valid credentials provided (Mechanism level: Failed to find any Kerberos tgt)] 
Bad connection to FS. command aborted. exception: Call to nn-host/10.0.0.2:8020 failed on local exception: java.io.IOException: 
javax.security.sasl.SaslException: GSS initiate failed [Caused by GSSException: No valid credentials provided (Mechanism level: Failed to find any Kerberos tgt)]

```

* Note:
The kinit command must either be on the path for user accounts running the Hadoop client, or else the hadoop.kerberos.kinit.command parameter in core-site.xml must be manually configured to the absolute path to the kinit command.

* Note:
If you are running MIT Kerberos 1.8.1 or higher, a bug in versions of the Oracle JDK 6 Update 26 and higher causes Java to be unable to read the Kerberos credentials cache even after you have successfully obtained a Kerberos ticket using kinit. To workaround this bug, run kinit -R after running kinit initially to obtain credentials. Doing so will cause the ticket to be renewed, and the credentials cache rewritten in a format which Java can read. For more information about this problem, see Troubleshooting.

###Start up a DataNode
Begin by starting one DataNode only to make sure it can properly connect to the NameNode. Use the service command to run the /etc/init.d script.
```
sudo service hadoop-hdfs-datanode start

```

###Configure YARN Security

####Configure Secure YARN

Before you start:

* The Kerberos principals for the ResourceManager and NodeManager are configured in the yarn-site.xml file. The same yarn-site.xml file must be installed on every host machine in the cluster.
* Make sure that each user who runs YARN jobs exists on all cluster nodes (that is, on every node that hosts any YARN daemon).
To configure secure YARN:

1. Add the following properties to the yarn-site.xml file on every machine in the cluster:
```
<!-- ResourceManager security configs -->
<property>
  <name>yarn.resourcemanager.keytab</name>
  <value>/etc/hadoop/conf/yarn.keytab</value>
<!-- path to the YARN keytab -->
</property>
<property>
  <name>yarn.resourcemanager.principal</name>

  <value>yarn/_HOST@YOUR-REALM.COM</value>
</property>

<!-- NodeManager security configs -->
<property>
  <name>yarn.nodemanager.keytab</name>
  <value>/etc/hadoop/conf/yarn.keytab</value>
<!-- path to the YARN keytab -->
</property>
<property>
  <name>yarn.nodemanager.principal</name>

  <value>yarn/_HOST@YOUR-REALM.COM</value>
</property>

<property>
  <name>yarn.nodemanager.container-executor.class</name>

  <value>org.apache.hadoop.yarn.server.nodemanager.LinuxContainerExecutor</value>
</property>

<property>
  <name>yarn.nodemanager.linux-container-executor.group</name>
  <value>yarn</value>
</property>

<!-- To enable TLS/SSL -->
<property>
  <name>yarn.http.policy</name>
  <value>HTTPS_ONLY</value>
</property>

```
2. Add the following properties to the mapred-site.xml file on every machine in the cluster:

```
<!-- MapReduce JobHistory Server security configs -->
<property>
  <name>mapreduce.jobhistory.address</name>
  <value>host:port</value> <!-- Host and port of the MapReduce JobHistory Server; default port is 10020  -->
</property>
<property>
  <name>mapreduce.jobhistory.keytab</name>
  <value>/etc/hadoop/conf/mapred.keytab</value>
<!-- path to the MAPRED keytab for the JobHistory Server -->
</property>

<property>
  <name>mapreduce.jobhistory.principal</name>

  <value>mapred/_HOST@YOUR-REALM.COM</value>
</property>

<!-- To enable TLS/SSL -->

<property>
  <name>mapreduce.jobhistory.http.policy</name>
  <value>HTTPS_ONLY</value>
</property>

```
3. Create a file called container-executor.cfg for the Linux Container Executor program that contains the following information
```
yarn.nodemanager.local-dirs=<comma-separated list of paths to local NodeManager directories. Should be same values specified in yarn-site.xml. Required to validate paths passed to container-executor in order.>
yarn.nodemanager.linux-container-executor.group=yarn
yarn.nodemanager.log-dirs=<comma-separated list of paths to local NodeManager log directories. Should be same values specified in yarn-site.xml. Required to set proper permissions on the log files so that they can be written to by the user's containers and read by the NodeManager for log aggregation.
banned.users=hdfs,yarn,mapred,bin

min.user.id=1000

```
* Note:
In the container-executor.cfg file, the default setting for the banned.users property is hdfs, yarn, mapred, and bin to prevent jobs from being submitted using those user accounts. The default setting for the min.user.id property is 1000 to prevent jobs from being submitted with a user ID less than 1000, which are conventionally Unix super users. Some operating systems such as CentOS 5 use a default value of 500 and above for user IDs, not 1000. If this is the case on your system, change the default setting for the min.user.id property to 500. If there are user accounts on your cluster that have a user ID less than the value specified for the min.user.id property, the NodeManager returns an error code of 255.

4. The path to the ``container-executor.cfg`` file is determined relative to the location of the container-executor binary. Specifically, the path is ``<dirname of container-executor binary>/../etc/hadoop/container-executor.cfg`` If you installed the CDH 5 package, this path will always correspond to ``/etc/hadoop/conf/container-executor.cfg``.

* Note
The container-executor program requires that the paths including and leading up to the directories specified in yarn.nodemanager.local-dirs and yarn.nodemanager.log-dirs to be set to 755 permissions as shown in this table on permissions on directories.

5. Verify that the ownership and permissions of the container-executor program corresponds to:
```---Sr-s--- 1 root yarn 36264 May 20 15:30 container-executor```

* Notes:
1. The keytab file need to be created by kadmin.local
2. The Kerberos username and keytab file path need to set in hdfs-site.xml
```
  <property>
      <name>com.emc.greenplum.gpdb.hdfsconnector.security.user.keytab.file</name>
      <value>/home/gpadmin/gpdb.keytab</value>
  </property>

  <property>
      <name>com.emc.greenplum.gpdb.hdfsconnector.security.user.name</name>
      <value>test/quickstart.cloudera@CLOUDERA</value>
  </property>

```
3 . The location of hdfs-site.xml need to put the hadoop default conf path, then gphdfs could load it.

The reference webpage can be found
1. [Cloudera Hadoop Security](https://www.cloudera.com/documentation/enterprise/5-8-x/topics/cdh_sg_cdh5_hadoop_security.html)
2. [GPDB Admin guide on Kerberos] (http://gpdb.docs.pivotal.io/43100/admin_guide/kerberos.html)
3. [legacy confluence](https://github.com/Pivotal-DataFabric/confluence-mirror/blob/605906eb430f0df4b4634e00b2a469355124b0af/PPD/Configuring%2BKerberos%2BAuthentication.md)
4. [Pivotal Knowlegde base](https://discuss.pivotal.io/hc/en-us/categories/200072608-Pivotal-Greenplum-DB-Knowledge-Base)
