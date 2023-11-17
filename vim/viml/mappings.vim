let mapleader = "\<space>"


nnoremap <silent> <leader>dr :%SourceSelection<cr>
vnoremap <silent> <leader>dr :SourceSelection<cr>
nnoremap <silent> <leader>ds :call ToggleStatusline()<cr>

augroup vimspec
    autocmd!
    autocmd FileType vimspec nnoremap <buffer> <nowait> <leader>t :Themis<cr>
augroup END
