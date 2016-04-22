---
layout: post
title:  "Attribut a single commit to multiple developers"
author: 刘奎恩
date:   2016-04-21 9:47:12
categories: tools git
published: true
---

To attribut a single commit to multiple developers for pair-programmed
source-code, several possible solutions you may choose:

One solution would be to set a name for the pair:
```
git config user.name "Kuien Liu and Yandong Yao"
```

Or, add a note at the end of the commit message saying
```
Co-authored-by: Kuien Liu <kliu@pivotal.io>
Commit by Kuien Liu and Yandong Yao.
```

Also it is suggested to give more information in commit message:
```
	Notes (Issue #223)
		Kuien Liu <kliu@pivotal.io>

	Notes (code):
		Kuien Liu <kliu@pivotal.io>
		Haozhou Wawng<hawang@pivotal.io>

	Notes (documentation):
		Haozhou Wawng<hawang@pivotal.io>

	Notes (review):
		Yandong Yao <pivotal.io>
```
It is good but a bit little verbose :)

--
No thanks, I'm Fuge(福哥) !.
