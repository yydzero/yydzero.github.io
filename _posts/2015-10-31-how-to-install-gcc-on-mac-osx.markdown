---
layout: post
title:  "How to install GCC onto OSX 10.9"
subtitle:  "在OSX 10.9上安装gcc"
date:   2015-10-29 14:20:43
categories: osx gcc
---

### 1. Install GCC 4.9
     $ brew tap homebrew/versions

     $ brew install gcc49   // will install gcc 4.9
     $ brew install gcc     // Will install gcc 5.x

### 2. Export env variables

     export CC=gcc-4.9
     export CXX=g++-4.9
     export CPP=cpp-4.9
     export LD=gcc-4.9

     
