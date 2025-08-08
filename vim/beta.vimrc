" Manually add the default user directory to the runtime path
set runtimepath^=$HOME/.vim

" Manually enable features that -u disables
filetype plugin indent on
syntax on

call plug#begin('~/.vim/vim-plug')
" add plugins
call plug#end()
