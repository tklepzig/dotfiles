#!/usr/bin/env zsh

if [ -z $1 ]
then
  cd $HOME/.dotfiles
  git checkout .
else
  cat $HOME/.dotfiles/themes/colours.$1.zsh > $HOME/.dotfiles/colours.zsh
fi

source $HOME/.dotfiles/generateVimColours.zsh 
tmux source-file $HOME/.tmux.conf
