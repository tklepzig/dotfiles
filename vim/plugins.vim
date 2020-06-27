call plug#begin('~/.vim/vim-plug')
"pluginfile
if !empty(globpath("$HOME", "/.plugins.vim"))
  source $HOME/.plugins.vim
endif
call plug#end()
