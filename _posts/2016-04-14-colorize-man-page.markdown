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
man() {
        env GROFF_NO_SGR=1 \
        LESS_TERMCAP_mb=$'\E[05;34m' \
        LESS_TERMCAP_md=$'\E[01;34m' \
        LESS_TERMCAP_me=$'\E[0m'     \
        LESS_TERMCAP_se=$'\E[0m'     \
        LESS_TERMCAP_so=$'\E[44;33m' \
        LESS_TERMCAP_ue=$'\E[0m'     \
        LESS_TERMCAP_us=$'\E[04;33m' \
        man "$@"
}
```

No thanks, I'm LeiFeng !.
