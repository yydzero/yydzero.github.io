---
layout: post
title:  "如何使man帮助带上彩色"
author: 刘奎恩
date:   2016-04-13 11:07:24
categories: tools man terminal colorful
published: true
---

add below lines into ~/.bashrc and re-source it

```sh
# colorize man pages
export PAGER="`which less` -s"
export BROWSER="$PAGER"
export LESS_TERMCAP_mb=$'\E[01;36m'
export LESS_TERMCAP_md=$'\E[01;36m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[01;44;33m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;33m'
```

No thanks, I'm LeiFeng !.
