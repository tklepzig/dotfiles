#!/usr/bin/env zsh

rm -f $HOME/.dotfiles/colours.vim
while read -r line
do
  [[ -z $line ]] && continue
  [[ $line =~ ^#.* ]] && continue
  echo "let $line" >> $HOME/.dotfiles/colours.vim
done <$HOME/.dotfiles/colours.zsh
