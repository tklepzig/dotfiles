#!/bin/bash

set -e
dotfilesDir=$HOME/.dotfiles

if [ ! -f $dotfilesDir/common.sh ]
then
  source <(curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/common.sh)
else
  source $dotfilesDir/common.sh
fi

removeLinkFromFile ".zshrc"
removeLinkFromFile ".vimrc"
removeLinkFromFile ".tmux.conf"

info "Removing ~/.vim..."
rm -rf $HOME/.vim
success "Done."

info "Removing ~/.zsh..."
rm -rf $HOME/.zsh
success "Done."

info "Removing ~/.dotfiles..."
rm -rf $dotfilesDir
success "Done."
