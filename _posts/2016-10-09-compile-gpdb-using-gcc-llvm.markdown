---
layout: post
title:  "compile GPDB using llvm"
subtitle:  " 使用 llvm 编译 codegen, gcc 6 编译GPDB"
author: Pivotal Engineer
date:   2016-10-09 11:00 +0800
categories: gpdb llvm
published: false
---

# Instructions for building gcc-6.2.0 on CentOS6 (takes around 35 mins)
For example, start a docker container:
```
docker run --rm -it  pivotaldata/centos67-java7-gpdb-dev-image /bin/bash
```

Then, inside the docker, create a `build_gcc.bash` with following script, and run the script.
```
#! /bin/bash

GCC_VERSION="6.2.0"
WORKDIR="$HOME/src/"
INSTALLDIR="/opt"

# get the source code
mkdir -p $WORKDIR
cd $WORKDIR
wget https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.bz2
tar -xf gcc-${GCC_VERSION}.tar.bz2

# download the prerequisites
cd gcc-${GCC_VERSION}
./contrib/download_prerequisites

# create the build directory
cd ..
mkdir gcc-build
cd gcc-build

# build
../gcc-${GCC_VERSION}/configure                      \
    --prefix=${INSTALLDIR}                           \
    --enable-shared                                  \
    --enable-threads=posix                           \
    --enable-__cxa_atexit                            \
    --enable-clocale=gnu                             \
    --enable-languages=c,c++                         \
    --disable-multilib                               \
&& make \
&& make install

# Notes
#
#   --enable-shared --enable-threads=posix --enable-__cxa_atexit:
#       These parameters are required to build the C++ libraries to published standards.
#
#   --enable-clocale=gnu:
#       This parameter is a failsafe for incomplete locale data.
#
#   --disable-multilib:
#       This parameter ensures that files are created for the specific
#       architecture of your computer.
#        This will disable building 32-bit support on 64-bit systems where the
#        32 bit version of libc is not installed and you do not want to go
#        through the trouble of building it. Diagnosis: "Compiler build fails
#        with fatal error: gnu/stubs-32.h: No such file or directory"
#
#   --with-system-zlib:
#       Uses the system zlib instead of the bundled one. zlib is used for
#       compressing and uncompressing GCC's intermediate language in LTO (Link
#       Time Optimization) object files.
#
#   --enable-languages=all
#   --enable-languages=c,c++,fortran,go,objc,obj-c++:
#       This command identifies which languages to build. You may modify this
#       command to remove undesired language
```

After the script has finished successfully, GCC 6.2.0 binaries can be found at /opt/gcc-6.2.0.  Create a file to setup environment so as to use GCC 6.2.0.  E.g.

gcc_env.sh
```
export PATH=/opt/gcc-6.2.0/bin:$PATH
export LD_LIBRARY_PATH=/opt/gcc-6.2.0/lib64:$LD_LIBRARY_PATH
```

Verify it's correct version:
```
source gcc_env.sh
gcc --version
```

# Instructions for building LLVM and Clang 3.7.1. (takes around 30mins each on 6 core VM)
```
# Install the Python2.7, which is required by LLVM
yum install -y centos-release-SCL
yum install -y python27
source /opt/rh/python27/enable

# Ensure that GCC 6.2.0 is built the environment is setup.
source /opt/gcc_env.sh

# Download LLVM 3.7.1 from: http://llvm.org/releases/3.7.1/llvm-3.7.1.src.tar.xz.
# Extract the source under $HOME/src
mkdir -p $HOME/src
cd $HOME/src
wget http://llvm.org/releases/3.7.1/llvm-3.7.1.src.tar.xz
tar xf llvm-3.7.1.src.tar.xz


# LLVM needs cmake, if it's not already installed, install it using `yum install cmake`
# To build LLVM:
cd llvm-3.7.1.src
mkdir build
cd build
CC=$(which gcc) CXX=$(which g++) cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=/opt/llvm-3.7.1/ -DCMAKE_INSTALL_PREFIX=/opt/llvm-3.7.1/ -DLLVM_ENABLE_CRASH_OVERRIDES=off
make install -j8

# Clang requires cmake3
yum install cmake3

# Download Clang 3.7.1 from: http://llvm.org/releases/3.7.1/cfe-3.7.1.src.tar.xz
cd $HOME/src
wget http://llvm.org/releases/3.7.1/cfe-3.7.1.src.tar.xz
tar xf cfe-3.7.1.src.tar.xz
cd cfe-3.7.1.src
mkdir build
cd build
CC=$(which gcc) CXX=$(which g++) cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=/opt/llvm-3.7.1/ -DCMAKE_INSTALL_PREFIX=/opt/llvm-3.7.1/
make install -j8
```