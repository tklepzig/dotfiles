if has('nvim')
  finish
endif

call plug#begin('~/.vim/vim-plug')
"pluginfile
source $HOME/.dotfiles-local/plugins.vim
call plug#end()
