#!/bin/bash

set -e
. ../common.sh

if isUbuntu
then
    info "Adding universe repository..."
    sudo add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe"
    sudo apt-get -y update
    success "Done."
fi

info "Installing some basic tools..."
sudo apt-get -y install curl gnome-tweak-tool vim xdotool gparted sshfs tmux pwgen xclip
success "Done."

info "Installing Google Chrome..."
. ./chrome.sh
success "Done."

info "Installing Visual Studio Code Insiders..."
. ./vscode.sh
success "Done."

info "Installing Git, npm, node and yarn..."
# npm & nodejs, for version 10.x
curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -

# yarn
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

sudo apt-get -y update
sudo apt-get -y install git nodejs yarn
success "Done."

if isUbuntu
then
    info "Installing latest version of git and seafile client..."
    #install latest version of git
    sudo add-apt-repository -y ppa:git-core/ppa
    
    # install seafile client
    sudo add-apt-repository ppa:seafile/seafile-client
    
    sudo apt-get -y update
    sudo apt-get -y install git seafile-gui
    success "Done."
fi

info "Installing some media tools..."
sudo apt-get -y install winff easytag audacity gimp vlc
success "Done."

info "Modifing gnome settings..."
gsettings set org.gnome.desktop.interface show-battery-percentage true
gsettings set org.gnome.shell enable-hot-corners false
gsettings set org.gnome.shell.app-switcher current-workspace-only true
success "Done."

info "Running dotfiles setup..."
. ../install.sh
success "Done."

info "Installing vim plugins..."
vim +PluginInstall +qall
success "Done."
