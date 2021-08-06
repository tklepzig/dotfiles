#!/bin/bash

read -p "Please confirm (Type 'yes') " confirm
if [ "$confirm" != "yes" ]
then
  exit 1 
fi

set -e
dotfilesDir=$HOME/.dotfiles

if [ ! -f $dotfilesDir/install.shared.sh ]
then
  source <(curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/install.shared.sh)
else
  source $dotfilesDir/install.shared.sh
fi

removePatternFromFile ".zshrc" ".dotfiles"
removePatternFromFile ".vimrc" ".dotfiles"
removePatternFromFile ".vimrc" ".plugins.vim"
removePatternFromFile ".tmux.conf" ".dotfiles"

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
