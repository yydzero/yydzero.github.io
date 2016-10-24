---
layout: post
title:  "Use an Encrypted USB Drive for your SSH Keys"
subtitle:  "使用U盘保存SSH秘钥"
author: 刘奎恩/Kuien
date:   2016-10-24 12:58 +0800
categories: tools
published: true
---

__Background__

A potential challenge of pair programming is that: pair stations are almost transparent to surroundings, their login account/password are sharing as public, so the SSH keys (for github and other services) may be disclosed permanently. With individual USBs, each time we load a key, we can specify its lifetime of validity, e.g., /Volumes/keys/load 2 (hours). By default, lifetime is set to 3600 seconds (1 hour). 


__What to do__

Blog: [Build a USB SSH key](http://tammersaleh.com/posts/building-an-encrypted-usb-drive-for-your-ssh-keys-in-os-x/)

1. format your USB key using OS X's built-in encrypted filesystem
2. generate (or copy original) SSH keys by `ssh-keygen`
3. prepare SSH key loading script with command `ssh-add -t TIME $USB/id_ras`
4. copy SSH key and script onto you encrypted USB key
5. copy SSH key to github.com (and retire existing ones)


__Can it be used on remote server__

Yes, use ssh agent: `ssh -A REMOTE_SERVER`


__Can it be used in docker__

Yes, but not easy. We may find some tips on [websites](http://stackoverflow.com/questions/32897709/ssh-agent-forwarding-inside-docker-compose-container), such as:

```sh
docker run --volume $SSH_AUTH_SOCK:/ssh-agent --env SSH_AUTH_SOCK=/ssh-agent ubuntu ssh-add -l
```

But I have not tested it yet. My 2 cents:

```
1. create docker container while mounting gpdb_src on host into docker;
2. always test bin in docker but push/pull src in host (with `git duet`)
```

I strongly suggest everyone use `git duet` for paring, and `construct` (or `sprout`) for env setup.
