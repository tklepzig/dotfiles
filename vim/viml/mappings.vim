let mapleader = "\<space>"

nnoremap <silent> <leader>dr :%SourceSelection<cr>
vnoremap <silent> <leader>dr :SourceSelection<cr>
vnoremap <silent> <leader>dh :let &statusline = ' %{synIDattr(synID(line("."),col("."),1),"name")} - %{synIDattr(synIDtrans(synID(line("."),col("."),1)),"name")} '<cr>

augroup vimspec
    autocmd!
    autocmd FileType vimspec nnoremap <buffer> <nowait> <leader>t :Themis<cr>
augroup END
