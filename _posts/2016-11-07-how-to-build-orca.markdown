---
layout: post
title:  "How to build ORCA"
author: Pivotal Engineer
date:   2016-11-07 09:00 +0800
categories: orca build
published: true
---

# How to build ORCA

## gpos

    mkdir build
    cd build
    cmake -D CMAKE_BUILD_TYPE=DEBUG ../
    make
    sudo make install

## gp-xerces

    mkdir build
    cd build
    env CFLAGS="-g" CXXFLAGS="-g" ../configure --prefix=/usr/local
    make
    sudo make install

## gp-orca

    mkdir build
    cd build
    cmake -D CMAKE_BUILD_TYPE=DEBUG ../
    make
    sudo make install

## Rebuild ORCA

    rm -rf /usr/local/include/gp*
    rm -rf /usr/local/include/naucrates
    rm -rf /usr/local/lib/libgp*

    cd build
    ninja clean
    ninja install


