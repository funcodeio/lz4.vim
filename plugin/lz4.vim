
autocmd BufReadPre,FileReadPre      *.lz4 setlocal bin
autocmd BufReadPost,FileReadPost    *.lz4 call lz4#read()
autocmd BufWritePost,FileWritePost  *.lz4 call lz4#write()
