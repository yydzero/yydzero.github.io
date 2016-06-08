---
layout: post
title:  "Pair with tool: git-duet"
subtitle: 怎么用git-duet辅助Pair-programming
author: 刘奎恩/Kuien
date:   2016-06-07 12:49
categories: tools git pair 
published: true
---

__Under Mac__:

## install

    brew tap git-duet/tap
    brew install git-duet

## config

```
    ○ → cat ~/.git-authors
    authors:
       kl: Kuien Liu; kliu
       hz: Haozhou Wang; hawang
       yy: Yandong Yao; yyao
    email:
       domain: pivotal.io
 ```
   
## usage

almost the same with origin GIT, with a few diffs if you want to remain the pairing info.

### a. before typing

```
	$ git solo kl
	GIT_AUTHOR_NAME='Kuien Liu'
	GIT_AUTHOR_EMAIL='kliu@pivotal.io'
```

OR

```
	$ git duet hz kl
	GIT_AUTHOR_NAME='Haozhou Wang'
	GIT_AUTHOR_EMAIL='hawang@pivotal.io'
	GIT_COMMITTER_NAME='Kuien Liu'
	GIT_COMMITTER_EMAIL='kliu@pivotal.io'
```

  Here, the first guy is Driver, while the second is Navigator.

###  b. commit

```
	$ git duet-commit
	$ git log
	commit bededfd55eb3349bb79f7a585d81008a22005653
	Author: Kuien Liu <kliu@pivotal.io>
	Date:   Wed Jun 8 12:28:15 2016 +0800
	
	    Test git-duet
	
	    Signed-off-by: Haozhou Wang <hawang@pivotal.io>
```

### c. others

almost the same with origin GIT, with a few diffs for **git-revert** and **git-merge** if you want to remain the pairing info.

```   
   git duet-revert
   git duet-merge
```
