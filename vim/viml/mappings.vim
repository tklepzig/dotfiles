let mapleader = "\<space>"

nnoremap <silent> <leader>dr :%SourceSelection<cr>
vnoremap <silent> <leader>dr :SourceSelection<cr>

nnoremap <silent> <leader>dh :source $VIMRUNTIME/syntax/hitest.vim

augroup vimspec
    autocmd!
    autocmd FileType vimspec nnoremap <buffer> <nowait> <leader>t :Themis<cr>
augroup END
