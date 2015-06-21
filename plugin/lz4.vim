" Vim plugin for read/editing .lz4 compressed files.
" Author:   Yongwoon Cho
" HomePage: http://github.com/funcodeio/lz4.vim
" Version:  0.1
"
" This plugin is originated from plugin/gzip.vim.
"
" plugin/gzip.vim
"   Vim plugin for editing compressed files.
"   Maintainer: Bram Moolenaar <Bram@vim.org>
"   Last Change: 2010 Mar 10


" Exit quickly when:
" - this plugin was already loaded
" - when 'compatible' is set
" - some autocommands are already taking care of compressed files
if exists("g:loaded_lz4") || &cp || exists("#BufReadPre#*.lz4")
  finish
endif
let g:loaded_lz4 = 1

augroup lz4
  " This prevents having the autocmd defined twice.
  au!

  autocmd BufReadPre,FileReadPre      *.lz4 setlocal bin
  autocmd BufReadPost,FileReadPost    *.lz4 call lz4#read()
  autocmd BufWritePost,FileWritePost  *.lz4 call lz4#write()
augroup END
