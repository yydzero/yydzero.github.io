---
layout: post
title: Live with multiple orca versions
date: 2017-11-06 10:00:00 +0800
comments: true
---

## Install different versions of ORCA into their own directory 

	cmake .. -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX=/usr/local/gporca-v2.46.4

## Set up CFLAGS etc for building GPDB:

ORCA_INSTALL_PATH=/usr/local/
use_orca ()
{
    local ver;
    ver="$1";
    function echo_and_run ()
    {
        echo "$@";
        "$@"
    };
    echo_and_run export CONF_INC="${ORCA_INSTALL_PATH}/$1/include";
    echo_and_run export CONF_LIB="${ORCA_INSTALL_PATH}/$1/lib";
    echo_and_run export CONF_RPATH="${ORCA_INSTALL_PATH}/$1/lib"
}

use_orca gporca-v2.46.4

## Configure GPDB:

CFLAGS="-O0" LDFLAGS="-rpath ${CONF_RPATH}" ./configure --with-python --with-perl --enable-orca --enable-debug --enable-cassert --prefix=$(pwd)/.build --with-includes=${CONF_INC} --with-libraries=${CONF_LIB}

Thanks Shreedhar for the tips
