#!/bin/bash

mkdir -p $HOME/.vim
ln -sf $dotfilesDir/vim/extended/coc-settings.json $HOME/.vim/coc-settings.json

checkInstallation ag silversearcher-ag
checkInstallation ranger
checkInstallation fzf
