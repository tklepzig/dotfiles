#!/usr/bin/env zsh

theme=$1
if [ -z $theme ]
then
  theme="${DOTFILES_THEME:-lcars}"
fi

cat $HOME/.dotfiles/themes/colours.$theme.zsh > $HOME/.dotfiles/colours.zsh
cat $HOME/.dotfiles/themes/kitty.$theme.conf > $HOME/.dotfiles/kitty/kitty.theme.conf

rm -f $HOME/.dotfiles/colours.vim
while read -r line
do
  [[ -z $line ]] && continue
  [[ $line =~ ^#.* ]] && continue
  echo "let $line" >> $HOME/.dotfiles/colours.vim
done <$HOME/.dotfiles/colours.zsh

if [ -n "$TMUX" ] && [ -f $HOME/.tmux.conf ]
then
  tmux source-file $HOME/.tmux.conf
fi
