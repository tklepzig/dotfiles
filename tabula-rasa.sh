#!/bin/bash

set -e
dotfilesDir=$HOME/.dotfiles

if [ ! -f $dotfilesDir/common.sh ]
then
  source <(curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/common.sh)
else
  source $dotfilesDir/common.sh
fi

removePatternFromFile ".zshrc" ".dotfiles"
removePatternFromFile ".vimrc" ".dotfiles"
removePatternFromFile ".vimrc" ".plugins.vim"
removePatternFromFile ".tmux.conf" ".dotfiles"

info "Removing ~/.plugins.vim..."
rm $HOME/.plugins.vim
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
