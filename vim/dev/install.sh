#!/bin/bash

checkInstallation ag silversearcher-ag
checkInstallation ranger
checkInstallation fzf

mkdir -p $HOME/.vim
ln -sf $dotfilesDir/vim/dev/coc-settings.json $HOME/.vim/coc-settings.json
