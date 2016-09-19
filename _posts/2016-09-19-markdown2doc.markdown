---
layout: post
title:  "generate DOC from MARKDOWN file"
subtitle:  "将markdown转换为doc文件"
author: 刘奎恩/Kuien, Peifeng Qiu
date:   2016-09-19 17:33 +0800
categories: tools
published: true
---

__Command__

```
brew install pandoc
pandoc -o gpdb.docx -f markdown -t docx gpdb.md
```


__What's Pandoc?__

>Pandoc  is  a  Haskell library for converting from one markup format to another, and a command-line tool that uses this library.  It can read Markdown, CommonMark, PHP Markdown Extra, GitHub-Flavored Markdown, and (subsets
>of) Textile, reStructuredText, HTML, LaTeX, MediaWiki markup, TWiki markup, Haddock markup, OPML, Emacs Org mode, DocBook, txt2tags, EPUB, ODT and Word docx; and it can write plain text, Markdown, CommonMark, PHP  Markdown
>Extra,  GitHub-Flavored  Markdown,  reStructuredText,  XHTML,  HTML5, LaTeX (including beamer slide shows), ConTeXt, RTF, OPML, DocBook, OpenDocument, ODT, Word docx, GNU Texinfo, MediaWiki markup, DokuWiki markup, Haddock
>markup, EPUB (v2 or v3), FictionBook2, Textile, groff man pages, Emacs Org mode, AsciiDoc, InDesign ICML, TEI Simple, and Slidy, Slideous, DZSlides, reveal.js or S5 HTML slide shows.  It can also produce PDF output on sys-
>tems where LaTeX, ConTeXt, or wkhtmltopdf is installed.
>
