---
layout: post
title:  "Debug Makefile"
subtitle:  " 调试 Makefile"
author: Pivotal Engineer
date:   2016-10-10 11:00 +0800
categories: makefile
published: true
---


# Debug Makefile

## dry run

    $ make -n <target>

## print variable used by Makefile

Add following rule to your Makefile

    print-%  : ; @echo $* = $($*)

Then, if you want to find out the value of a makefile variable such as BLD_TOP, just:

    $ make print-BLD_TOP

## Display messages

    $(info this is a message I want to show)

or @echo if in target actions:

    test:
        @echo "this is a message I want to show"