#!/usr/bin/env zsh

if [ -d "$HOME/.asdf" ]
then
  echo "Warning: asdf already set up, exiting."
  exit 1
fi

git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf
cd $HOME/.asdf
git checkout "$(git describe --abbrev=0 --tags)"
cd -
source $HOME/.zshrc

for plugin in nodejs python ruby vim ctop
do
  asdf plugin add $plugin
  asdf install $plugin latest
  asdf global $plugin latest
done
