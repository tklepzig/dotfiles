#!/bin/bash

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

info "Removing ~/.vim..."
rm -rf $HOME/.vim
success "Done."

info "Removing ~/.zsh..."
rm -rf $HOME/.zsh
success "Done."

info "Removing ~/.dotfiles..."
rm -rf $dotfilesDir
success "Done."
