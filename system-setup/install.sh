#!/bin/bash

. ../common.sh

if isUbuntu
then
    sudo add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe"
    sudo apt-get -y update
fi


# remove quiet splash from cmdline-linux-default in /etc/default/grub
# anschließend sudo update-grub


sudo apt-get -y install curl gnome-tweak-tool vim xdotool gparted sshfs tmux pwgen xclip

echo -e "${accent}Installing Google Chrome${normal}"
. ./chrome.sh

echo -e "${accent}Installing Visual Studio Code Insiders${normal}"
. ./vscode.sh

# npm & nodejs, for version 10.x
curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -

# yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

sudo apt-get -y update
sudo apt-get -y install git nodejs yarn

if isUbuntu
then
    #install latest version of git
    sudo add-apt-repository -y ppa:git-core/ppa
    
    # install seafile client
    sudo add-apt-repository ppa:seafile/seafile-client
    
    sudo apt-get -y update
    sudo apt-get -y install git seafile-gui
fi

sudo apt-get -y install winff easytag audacity gimp vlc

# install all gnome extensions:
# Chrome exension: https://chrome.google.com/webstore/detail/gnome-shell-integration/gphhapmejobijbbhgpjhcjognlahblep
sudo apt-get install chrome-gnome-shell

https://extensions.gnome.org/extension/413/dash-hotkeys/
https://extensions.gnome.org/extension/495/topicons/

gsettings set org.gnome.desktop.interface show-battery-percentage true
gsettings set org.gnome.shell enable-hot-corners false
gsettings set org.gnome.shell.app-switcher current-workspace-only true

# dann dotfiles

# install vim plugins
vim +PluginInstall +qall
