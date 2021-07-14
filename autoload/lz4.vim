" Vim plugin for read/editing .lz4 compressed files.
" Author:   Yongwoon Cho
" HomePage: http://github.com/funcodeio/lz4.vim
" Version:  0.1
"
" This plugin is originated from autoload/gzip.vim.
" Since lz4's cmd line system is different from gzip, gzip#read and gzip#write
" cannot handle lz4 file. Thus, I modifiied autoload/gzip.vim for .lz4 file,
" and fixed some bugs.
"
" autoload/gzip.vim
"   Vim autoload file for editing compressed files.
"   Maintainer: Bram Moolenaar <Bram@vim.org>
"   Last Change: 2008 Jul 04
"

" Add `lz4c` in binary search list
" because the old version of lz4tools might not have 'lz4' binary.
let s:lz4_bin_list = [ "lz4", "lz4c" ]
let s:lz4_bin = s:lz4_bin_list[0]

fun s:filename_escape(name)
  if exists('*fnameescape')
    return fnameescape(a:name)
  endif
  return escape(a:name, " \t\n*?[{`$\\%#'\"|!<")
endfun

fun s:shell_escape(name)
  " shellescape() was added by patch 7.0.111
  if exists("*shellescape")
    return shellescape(a:name)
  endif
  return "'" . a:name . "'"
endfun

" Function to check that executing "cmd -V" works.
" The result is cached in s:have_"cmd" for speed.
fun s:lz4_exists()
  let l:cmd = "lz4"

  let l:e = 0
  if exists("s:have_" . l:cmd)
    exe "let l:e = s:have_" . l:cmd
  endif

  if l:e <= 0
    let l:bin = ""
    for l:bin in s:lz4_bin_list
      let l:e = executable(l:bin)
      if l:e < 0
        let r = system(l:bin . " -V")
        let l:e = (r !~ "not found" && r != "")
      endif

      if l:e > 0
        let s:lz4_bin = l:bin
        break
      endif
    endfor
    unlet l:bin

    exe "let s:have_" . l:cmd . "=" . l:e
  endif

  exe "return s:have_" . l:cmd
endfun

fun s:silent_exe(cmd)
  exe "silent " . a:cmd
endfun

" A function to add lockmarks if this command exists.
fun s:lockmarks_cmd(cmd)
  if exists(":lockmarks")
    return "lockmarks " . a:cmd
  endif
  return a:cmd
endfun

fun s:set_mark(mark_cmd, line_num)
  exe a:line_num
  exe "normal " . a:mark_cmd
endfun

" After reading compressed file: Uncompress text in buffer with "cmd"
fun lz4#read()
  " don't do anything if the cmd is not supported
  if !s:lz4_exists()
    return
  endif

  " make 'patchmode' empty, we don't want a copy of the written file
  let pm_save = &pm
  set pm=
  " remove 'a' and 'A' from 'cpo' to avoid the alternate file changes
  let cpo_save = &cpo
  set cpo-=a cpo-=A
  " set 'modifiable'
  let ma_save = &ma
  setlocal ma
  " Reset 'foldenable', otherwise line numbers get adjusted.
  if has("folding")
    let fen_save = &fen
    setlocal nofen
  endif

  " when filtering the whole buffer, it will become empty
  let empty = line("'[") == 1 && line("']") == line("$")
  let tmp = tempname()
  let tmp_with_ext = tmp . "." . expand("<afile>:e")
  let tmp_esc = s:filename_escape(tmp)
  let tmp_with_ext_esc = s:filename_escape(tmp_with_ext)
  let tmp_shell = s:shell_escape(tmp)
  let tmp_with_ext_shell = s:shell_escape(tmp_with_ext)

  " write the just read lines to a temp file '[,']w tmp.lz4
  call s:silent_exe("'[,']w " . tmp_with_ext_esc)

  " uncompress the temp file: call system("lz4c -df 'tmp.lz4' 'tmp'")
  let decompress_cmd = s:lz4_bin . " -df " . tmp_with_ext_shell . " " . tmp_shell
  call system(decompress_cmd)

  if !filereadable(tmp)
    " uncompress didn't work!  Keep the compressed file then.
    echoerr "Error: Could not read uncompressed file"
    let ok = 0
  else
    let ok = 1
    " delete the compressed lines; remember the line number
    let start_line = line("'[") - 1
    let delete_cmd = s:lockmarks_cmd("'[,']d _")
    exec delete_cmd

    " read in the uncompressed lines "'[-1r tmp"
    " Use ++edit if the buffer was empty, keep the 'ff' and 'fenc' options.
    if empty
      let read_cmd = s:lockmarks_cmd(start_line . "r ++edit" . tmp_esc)
    else
      let read_cmd = s:lockmarks_cmd(start_line . "r " . tmp_esc)
    endif
    call s:silent_exe(read_cmd)

    " if buffer became empty, delete trailing blank line
    if empty
      " Since delete operation changes '[ and '] mark, it is saved here.
      " And, it will be recovered after deleting the trailing line.
      " '[ and '] must be correct to continue autocommand after decompress.
      let start_save = line("'[")
      let end_save = line("']")
      call s:silent_exe(s:lockmarks_cmd("$delete _"))
      call s:set_mark("m[", start_save)
      call s:set_mark("m]", end_save)
      1
    endif
    " delete the temp file and the used buffers
    call delete(tmp)
    call delete(tmp_with_ext)
    silent! exe "bwipe " . tmp_esc
    silent! exe "bwipe " . tmp_with_ext_esc
  endif

  " Restore saved option values.
  let &pm = pm_save
  let &cpo = cpo_save
  let &l:ma = ma_save
  if has("folding")
    let &l:fen = fen_save
  endif

  " When uncompressed the whole buffer, do autocommands
  if ok && empty
    let fname = s:filename_escape(expand("<afile>:r"))
    if &verbose >= 8
      execute "doau BufReadPost " . fname
    else
      execute "silent! doau BufReadPost " . fname
    endif
  endif

  " nobin is set after completing autocommands
  setlocal nobin
endfun

" After compress written file.
fun lz4#write()
  " Before compressed, do autocommands
  let fname = s:filename_escape(expand("<afile>:r"))
  if &verbose >= 8
    execute "doau BufWritePost " . fname
  else
    execute "silent! doau BufWritePost " . fname
  endif

  " don't do anything if the cmd is not supported
  if !s:lz4_exists()
    return
  endif

  " Rename the file before compressing it.
  let write_file = resolve(expand("%"))
  let tmp_file = tempname()
  let write_file_shell = s:shell_escape(write_file)
  let tmp_file_shell = s:shell_escape(tmp_file)

  if rename(write_file, tmp_file) == 0
    call system(s:lz4_bin . " -zf " . tmp_file_shell . " " . write_file_shell)
    if !v:shell_error
      " Successfully compressed
      call delete(tmp_file_shell)
    else
      " An error occurred while compression. It will try to recover as possible.
      call rename(tmp_file, write_file)
      echoerr "The comperssion failed. You might lost the file. "
      echoerr "Please check whether your file is safe before you quit vim."
    endif
  endif
endfun

" TODO(Yongwoon): Implement append function
" TODO(Yongwoon): When reading, it should retrieve block size, HC, and all other
"                 infomation that can be used in compression. Currently,
"                 compression is done with default parameters which may be
"                 different from the original file.
" TODO(Yongwoon): Currently, writing abc.gz.lz4 does not work because gzip.vim
"                 tries to read expand("<afile>") which is abc.gz instead of
"                 expand("%") which is abc.gz.lz4. I cannot make abc.gz because
"                 it may overwrite the existing file. I need to find the way to
"                 resolve it without modifying gzip.vim.
" TODO(Yongwoon): Add unittests.
"                 - Test whether marks are preserved after read/write.
"                 - Test whether pm is preserved after read/write.
"                 - Test with weird file name to see escaping.
"                 - Test nested compressed files such as abc.gz.lz4.
"                 - Test depending on vim and lz4 version.
