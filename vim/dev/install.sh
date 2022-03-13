#!/usr/bin/env zsh

checkInstallation ag silversearcher-ag
checkInstallation ranger
checkInstallation fzf
checkInstallation bat

mkdir -p $HOME/.vim
ln -sf $dotfilesDir/vim/dev/coc-settings.json $HOME/.vim/coc-settings.json
