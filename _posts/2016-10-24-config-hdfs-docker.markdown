---
layout: post
title:  "setup hdfs in docker"
subtitle:  "在docker中搭建hdfs环境"
author: Peifeng Qiu, Haozhou Wang
date:   2016-10-24 15:23 +0800
categories: tools
published: true
---

## Setup hadoop environment

### Pull latest ubuntu image and start container.

```sh
docker pull ubuntu
docker run -it --name hdfs ubuntu /bin/bash
```

### Modify ubuntu software sources (optional)
We will use software sources from mainland china.

```sh
sed -i -e "s/archive.ubuntu.com/cn.archive.ubuntu.com/g" /etc/apt/sources.list
```

### Update software source and install dependent packages

```sh
apt-get update
apt-get install default-jre ssh rsync vim
```

### Download and extract hadoop 2.7.3 package 
Find the fastest mirror [here](http://www.apache.org/dyn/closer.cgi/hadoop/common/hadoop-2.7.3/hadoop-2.7.3.tar.gz).

We will extract the package at /usr/local/hdfs

```sh
mkdir /usr/local/hdfs
cd /usr/local/hdfs
tar -xzf /hadoop-2.7.3.tar.gz

cd /usr/local/hdfs/hadoop-2.7.3
```

### Setup JAVA path for hadoop env
Edit /usr/local/hdfs/hadoop-2.7.3/etc/hadoop/hadoop-env.sh,
Replace

```
export JAVA_HOME=${JAVA_HOME}
```

with absolute path

```
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/
```


### Now we can run a mapreduce example

```sh
mkdir input
cp etc/hadoop/*.xml input
bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.3.jar grep input output 'dfs[a-z.]+'
cat output/*
```

## Setup pseudo distributed cluster (single node cluster)

### setup ssh to enable ssh localhost

```sh
/etc/init.d/ssh start
ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys
ssh-keyscan -H localhost > ~/.ssh/known_hosts
```

### setup the configure file
etc/hadoop/core-site.xml

```
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://0.0.0.0:8020</value>
    </property>
</configuration>
```

etc/hadoop/hdfs-site.xml

```
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
</configuration>
```

### format the cluster

```sh
bin/hdfs namenode -format
```

### start the cluster

```sh
sbin/start-dfs.sh
```

### test the new cluster

```sh
bin/hdfs dfs -put etc/hadoop /input
bin/hdfs dfs -ls /input
```

### run a test using /input, store result in /output

```sh
bin/hadoop jar share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.3.jar grep /input /output 'dfs[a-z.]+'
```

### list output

```sh
bin/hdfs dfs -ls /output
```

### copy output to local

```sh
bin/hdfs dfs -get /output output
```

### cat the file content

```sh
bin/hdfs dfs -cat /output/*
```

### stop cluster

```sh
sbin/stop-dfs.sh
```

## Expose hdfs port of the docker

We will have to rereate another container and specify the port options.
Exit and stop the docker container first.

Commit the image

```sh
docker commit hdfs hdfs
```

Create another container

```sh
docker run -it --name hdfs1 -p 0.0.0.0:8020:8020 hdfs /bin/bash
```
