---
layout: post
title: Have Vim Automatically Add Clojure Namespace
tags: clojure vim
category: posts
---

# Only so Much Time in the Day

Given that we all have a limited number of hours in a day to be productive,
automating repetitive tasks is the name of the game. After I had done it more
than a few times in a day it occurred to me that there was no reason to
manually type out the namespace declaration in new Clojure files. So, I wrote
the following function to do it for me:

``` vim
function! InsertNamespace()
  let s:dir_regex        = 'test\/\|src\/'
  let s:first_line_empty = getbufline('%', 1, 1) == ['']
  let s:file_path        = expand('%')
  if match(s:file_path, s:dir_regex) > -1 && s:first_line_empty
      let s:relevant_path   = substitute(s:file_path, s:dir_regex, '', '')
      let s:dasherized_path = substitute(s:relevant_path, '_', '-', 'g')
      let s:dotted_path     = substitute(s:dasherized_path, '\/', '\.', 'g')
      let s:namespace       = substitute(s:dotted_path, '\.clj[s]*$', '', '')
      call setline(1, '(ns ' . s:namespace . ')')
  endif
endfunction

augroup filetype_clojure
    autocmd!
    autocmd FileType clojure call InsertNamespace()
augroup END
```
Now anytime I open an empty file in either a `src` or `test` directory I
automatically have the appropriate namespace declaration inserted. It may not
change your life, but little automations eventually add up into real-time
savings.
