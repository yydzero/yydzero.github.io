---
layout: post
title:  "How to remove empty lines at file tail using SED?"
subtitle: 怎么用e删掉文件尾部的空行？
author: 刘奎恩/Kuien
date:   2016-04-25 16:49
categories: tools makefile
published: true
---

1. remove all the empty lines:

sed '/^$/d' filename

2. remove the empty lines at file tail:

sed '${/^$/d}' filename

If we wanna achieve this in a Makefile:

sed '$${/^$$/d}' filename

3. replace all '\n' with ',': 

sed ':LLL;N;s/\n/,/g;t LLL' aaa

---
No thanks, I'm Fuge(福哥) !.
