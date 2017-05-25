Navcoin Full Node for Docker
============================

Navcoind + Wallet + WebUI docker image, thats run the Navcoin Full Node to earn Proof of Stake rewards.

Requirements
------------

* Any phisical or virtual machine that support docker.
* 2GB to store the blockchain files (warning, the chain is always growing)
* And 1 GB of RAM.

Quick start
-----------

1. First you need to create a named volume `navcoin-data` to persist the blockchain and wallet files:
```
     docker volume create --name=navcoin-data
```
Or directly you can use a specific directory from the host, i prefer named volumes.  
For know the difference, read this: [Manage data in containers](https://docs.docker.com/engine/tutorials/dockervolumes/).

So if you want to reboot, upgrade or destroy the container, that files will be safe.


2. Create the container:
```
     docker run -v navcoin-data:/navcoin --name=navcoin-full-node -d \
                -p 44440:44440 \
                -p 127.0.0.1:44444:44444 \
                -p 8080:80 \
                sebaponti/docker-navcoind
```
3. Check if the container its susefuly created, and its running:
```
     docker ps
```
4. You can then access the daemon's output thanks to the [docker logs command](https://docs.docker.com/reference/commandline/cli/#logs).
```
     docker logs -f navcoin-full-node
```
Custom Building (optional)
--------------------------

You can build the image with custom parameters like id's of your unprivileged user,  
clone the repository and build the image with this args:
```
     docker build --build-arg USER_ID=$( id -u ) --build-arg GROUP_ID=$( id -g ) .
```
By default the image is building with the user and group id = 1000.


Update
------

To get the latest version of this image run:
```
     docker pull sebaponti/docker-navcoind
```
Contributing to this project
----------------------------

Anyone and everyone is welcome to contribute.

---

And that's all folks, happy Stakeing!.
