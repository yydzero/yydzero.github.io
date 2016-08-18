---
layout: post
title:  "Integrate VIM with CLangFormat"
subtitle:  "Vim中集成CLangFormat"
author: 刘奎恩/Kuien
date:   2016-08-18 12:58 +0800
categories: vim 
published: true
---

### install clangformat

__on Mac OS X__:

```sh
brew install clang-format
```

### configure clangformat

```sh
clang-format -style=google -dump-config > .clang-format
```

`.clang-format` is YAML format configure file for CLangFormat

An example of a configuration file for multiple languages:

```yml
	---
	# We'll use defaults from the LLVM style, but with 4 columns indentation.
	BasedOnStyle: LLVM
	IndentWidth: 4
	---
	Language: Cpp
	# Force pointers to the type for C++.
	DerivePointerAlignment: false
	PointerAlignment: Left
	---
	Language: JavaScript
	# Use 100 columns for JS.
	ColumnLimit: 100
	---
	Language: Proto
	# Don't format .proto files.
	DisableFormat: true
	...
```

See [ClangFormatStyleOptions.html](http://clang.llvm.org/docs/ClangFormatStyleOptions.html) for more detailed info.


### integrate Vim with clangformat

This can be integrated by adding the following to your .vimrc:

	map <C-K> :pyf <path-to-this-file>/clang-format.py<cr>
	imap <C-K> <c-o>:pyf <path-to-this-file>/clang-format.py<cr>

On my Macbook, the path is: `/usr/local/Cellar/clang-format/2016-03-29/share/clang/clang-format.py`
