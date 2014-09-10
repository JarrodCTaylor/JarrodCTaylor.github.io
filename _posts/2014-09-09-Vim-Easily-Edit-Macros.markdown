---
layout: post
title: Vim Easily Edit Macros
tags: vim
category: posts
---

# The Problem

You are performing a repetitive editing task and see a great opportunity to
record a vim macro that will magically perform the remainder of this boring
task and solidify your rightful place as a true Vim master. You expertly execute
a lengthy macro to solve all your woes, hit stop and immediately realize that you didn't
drop down to the next line. Therefore preventing you from repeatedly running this
excellent macro as you intended.

# The Next Problem

Great, now we have an almost perfect macro and no interest in rerecording it.
However, all hope is not lost, after all, this is Vim, there has to be a way to
edit an existing macro. Of course there is. Assuming that we recorded our macro
to the `a` register then the [Vim wiki](http://vim.wikia.com/wiki/Macros) gives
us five easy steps to edit our macro's contents and add our trailing `j`.


- `:let @a='` open the `a` register
- `<Cntl-r><Cntl-r>a` paste the contents of the a register into the buffer
- `j` add the missing motion to drop to the next line
- `'` add a closing quote
- <Enter> finish editing the macro

Wow! I don't know about you but, I am not going to remember that when I need
it.  In fact, I often find myself just giving up and rerecording the macro, not
to mention conceding my position as a Vim master.

# There Has To Be A Better Way

Not being content with rerecording or looking up / remembering the incantation
to edit my macros I have written a function that you can add to your `.vimrc`
to do all the hard work for you.

``` vim
function! EditMacro()
  call inputsave()
  let g:regToEdit = input('Register to edit: ')
  call inputrestore()
  execute "nnoremap <Plug>em :let @" . eval("g:regToEdit") . "='<C-R><C-R>" . eval("g:regToEdit")
endfunction
```

You can now add a mapping of your choice to execute this new function and the
`<Plug>` that it creates. For example, I am using `<Leader>em` in my
configuration like so.

``` vim
nmap <Leader>em :call EditMacro()<CR> <Plug>em
```

Now when you use your key mapping you will be asked for the register to edit.
Then, the contents will be displayed for you. All you will need to do it make
your modifications, press enter and get back to actually doing real work.
