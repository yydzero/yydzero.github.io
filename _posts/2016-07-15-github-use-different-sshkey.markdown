---
layout: post
title:  "Use different ssh key for different user or gitrepo"
author: 姚延栋
date:   2016-07-15 09:49
categories: github ssh
published: true
---

有时候希望一个用户使用不同的 ssh key 访问不同的 github repo，或者不同的用户使用自己的key访问相同的repo：


首先生成ssh key，设置自己的key名字， 为了安全起见，设置密码。

    $ ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
    Generating public/private rsa key pair.
    Enter a file in which to save the key (/Users/you/.ssh/id_rsa): [Press enter] /Users/you/.ssh/id_rsa_yydzero
    Enter passphrase (empty for no passphrase): [Type a passphrase]
    Enter same passphrase again: [Type passphrase again]

使用 ssh-agent 和 ssh-add

    # start the ssh-agent in the background
    eval "$(ssh-agent -s)"
    Agent pid 59566

    $ ssh-add ~/.ssh/id_rsa_yydzero

    $ git clone <repo>