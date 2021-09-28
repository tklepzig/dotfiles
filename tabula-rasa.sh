#!/bin/bash

read -p "Please confirm (Type 'yes') " confirm
if [ "$confirm" != "yes" ]
then
  exit 1 
fi

set -e
dotfilesDir=$HOME/.dotfiles

source <(curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/logger.sh)

removePatternFromFile() {
  target=$1
  pattern=$2
  if [ -f $HOME/$target ]
  then
    info "Remove link from $target with pattern $pattern..."
    sed /$pattern/d $HOME/$target > $HOME/$target.tmp && mv $HOME/$target.tmp $HOME/$target
    success "Done."
  fi
}

removePatternFromFile ".zshrc" ".dotfiles"
removePatternFromFile ".vimrc" ".dotfiles"
removePatternFromFile ".vimrc" ".plugins.vim"
removePatternFromFile ".tmux.conf" ".dotfiles"
removePatternFromFile ".config/kitty/kitty.conf" ".dotfiles"

info "Removing ~/.plugins.vim..."
rm $HOME/.plugins.vim
success "Done."

info "Removing ~/.plugins.custom.vim..."
rm $HOME/.plugins.custom.vim
success "Done."

info "Removing ~/.vim-profiles..."
rm $HOME/.vim-profiles
success "Done."

info "Removing ~/.vim..."
rm -rf $HOME/.vim
success "Done."

info "Removing ~/.zsh..."
rm -rf $HOME/.zsh
success "Done."

info "Removing ~/.dotfiles..."
rm -rf $dotfilesDir
success "Done."
