let mapleader = "\<space>"

augroup ruby
    autocmd!
    autocmd FileType ruby nnoremap <buffer> <leader>2 :AlternateSafe<cr>
augroup END
