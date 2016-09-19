---
layout: post
title:  "test CONSTRUCT in docker"
subtitle:  "在docker中试用CONSTRUCT"
author: 刘奎恩/Kuien, Peifeng Qiu
date:   2016-09-19 17:23 +0800
categories: tools
published: true
---

We are trying to use CONSTRUCT to uniform dev env, to test in clean OS, we need mount it to docker.

__What is construct?__

>construct is inspired by systems like [boxen], [sprout-wrap], [sprout], [chef], [babushka] and [puppet].
>
>construct is not better, just simpler. construct has no external dependencies. construct has no server. There are no conferences about construct. There are no consultancies that offer construct services. construct is designed to be simple enough to setup workstations and jumpboxes. It is not the right tool for many, many other use cases.
>
>construct is okay with units that require manual operator intervention as construct is as much about documentation as it is about automation. In fact, if construct was a person it would suggest you first write your units as the kind that instruct the operator _before_ you investigate how to make them automated and non-interactive.


__HOST__

```
git clone git@github.com:pivotal-cloudops/construct.git ~/workspace/
docker create -v ~/workspace/construct:/root/construct -it --name construct docker.io/kuien/centos511-java7-gpdb-dev-image /bin/bash
docker start construct
docker exec -it construct /bin/bash
```

The ~/workspace/construct folder is then shared with docker, mounted at /root/workspace

__Docker__

```
cd /root/construct
git log
```


__tips__

> **Mount a host directory as a data volume**
> In addition to creating a volume using the -v flag you can also mount a directory from your Docker engine’s host into a container.
>
> ```$ docker run -d -P --name web -v /src/webapp:/opt/webapp training/webapp python app.py```
>
>This command mounts the host directory, /src/webapp, into the container at /opt/webapp. If the path /opt/webapp already exists inside the container’s image, the /src/webapp mount overlays but does not remove the pre-existing content. Once the mount is removed, the content is accessible again. This >
>is consistent with the expected behavior of the mount command.
>
>The container-dir must always be an absolute path such as /src/docs. The host-dir can either be an absolute path or a name value. If you supply an absolute path for the host-dir, Docker bind-mounts to the path you specify. If you supply a name, Docker creates a named volume by that name.
>
>A name value must start with an alphanumeric character, followed by a-z0-9, _ (underscore), . (period) or - (hyphen). An absolute path starts with a / (forward slash).
>
>For example, you can specify either /foo or foo for a host-dir value. If you supply the /foo value, the Docker Engine creates a bind-mount. If you supply the foo specification, the Docker Engine creates a named volume.


[boxen]: http://boxen.github.com
[sprout-wrap]: https://github.com/pivotal-sprout/sprout-wrap
[sprout]: https://github.com/pivotal-sprout/sprout
[babushka]: http://babushka.me
[chef]: http://www.opscode.com/chef
[puppet]: http://puppetlabs.com
