#!/bin/bash

mkdir -p $HOME/.config/solargraph
ln -sf $dotfilesDir/vim/ruby/solargraph.yaml $HOME/.config/solargraph/config.yml
ln -sf $dotfilesDir/vim/ruby/default-gems $HOME/.default-gems
