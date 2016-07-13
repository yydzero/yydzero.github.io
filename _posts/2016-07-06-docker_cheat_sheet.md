### Tips for using docker:
* First, start the VM to host docker daemon or docker engine, use

```
# if no VM created before
docker-machine create -d virtualbox --virtualbox-cpu-count 4 --virtualbox-disk-size 50000 --virtualbox-memory 8192 gpdb

# if there are existing VMs
docker-machine start gpdb

# stop a VM
docker-machine stop
```

* after starting the VM, let shell know the existence of the VM by exporting the environment variables of the VM:

```
eval $(docker-machine env gpdb)
```

* then, we should have an image to run container

```
# if no exiting image, build one or pull one from docker hub

# build one from Dockerfile
cd <path_to_gpdb>
docker build . # the Dockerfile in that dir would pull a base image first and then apply some commands

# pull one
docker pull <image_name>
```

* if we have not run container before on this image:

```
docker run -it <image_name> # start a new container on the specified image, -it means interactive and using terminal
```

* if there are existing containers on the image:

```
docker ps -a # list all containers on all images

# if the container has exited, start it first
docker start <container_id>

# if the container has been running, we can use one of the following two methods to login to the container
docker attach <container_id> # this would attach to the original tty of the container, the tty is unique
docker exec -it c<container_id> bash # recommended, this start a bash process in a new tty
```

* how to detach from a container?

```
# if we are using attach method
^p ^q # this would leave the the container and the container would be still running
exit # this would leave the container and the container would be stopped

# if we are using exec method
exit # recommended, this would leave the container and the container would still be running, and the new tty, the bash process would exit
^p ^q # this would leave the container and the container would still be running, and the bash process would still be running in the container, which is not good
```

* remove an existing container

```
docker rm <container_id>
docker rmi <image_id> # remove image; once we updated src code, we would build a new image, so it is a good habit to remove old unused images
```

* how to attach to a process using gdb?
	* the container must be run with option --privileged
	* --privileged option must be supplied when docker exec