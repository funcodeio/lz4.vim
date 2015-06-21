# lz4.vim
A vim plugin for reading and writing [lz4] frame files.
[lz4]: https://github.com/Cyan4973/lz4

This plugin enables you to see the original content of lz4-compressed file, and to modify it. When you read a lz4-compressed file, the plugin decompresses it internally and paste the result into the window. And, when you write a file whose extension is lz4, the plugin writes compressed string to the file.

It is a variant of [gzip.vim] plugin included in vim74.
[gzip.vim]: http://sourceforge.net/p/vim/code/HEAD/tree/vim7/runtime/autoload/gzip.vim

## Installation 
If you don't have any preferred installation method, one option is using Vundle.

1. [Install Vundle] into `~/.vim/bundle/`.
[Install Vundle]: https://github.com/gmarik/vundle

2. Add this line to your `.vimrc`.

  ```Plugin 'funcodeio/lz4.vim'```

3. Open vim and run `:PluginInstall`.

  To update, open vim and run `:PluginUpdate`

## Requirement 

lz4c binary is required.

If you use Ubuntu, you can find it in `liblz4-tool` package.

  ```sudo apt-get install liblz4-tool```
