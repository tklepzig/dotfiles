#!/bin/bash

set -e
dotfilesDir=$HOME/.dotfiles

if [ ! -f $dotfilesDir/install.shared.sh ]
then
  source <(curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/install.shared.sh)
else
  source $dotfilesDir/install.shared.sh
fi

info "Searching for Git..."
if ! isProgramInstalled git
then
    error "No Git found!"
    exit
fi
success "Git found: $(which git)."

info "Cloning Repo..."
rm -rf $dotfilesDir
git clone --depth=1 https://github.com/tklepzig/dotfiles.git $dotfilesDir > /dev/null 2>&1
success "Done."

cd $dotfilesDir/system-setup

if isUbuntu
then
    info "Adding universe repository..."
    sudo add-apt-repository -y "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe"
    sudo apt-get -y update
    success "Done."
fi

info "Installing some basic tools..."
sudo apt-get -y install curl gnome-tweak-tool vim-gnome xdotool gparted sshfs tmux pwgen xclip zsh silversearcher-ag ranger peco tig fzf lynx exa
success "Done."

info "Installing Google Chrome..."
. ./scripts/chrome.sh
success "Done."

# Skipped temporarily while testing setup with asdf
  #info "Installing Git, npm, node..."
  ## npm & nodejs, for version 13.x
  #curl -sL https://deb.nodesource.com/setup_13.x | sudo -E bash -

  ## yarn
  ##curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
  ##echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list

  #sudo apt-get -y update
  #sudo apt-get -y install git nodejs #yarn
  #success "Done."
# --

if isUbuntu
then
    info "Installing latest version of git and seafile client..."
    #install latest version of git
    sudo add-apt-repository -y ppa:git-core/ppa

    # install seafile client
    sudo add-apt-repository -y ppa:seafile/seafile-client

    sudo apt-get -y update
    sudo apt-get -y install git seafile-gui
    success "Done."
fi

info "Installing asdf..."
git clone https://github.com/asdf-vm/asdf.git $HOME/.asdf
cd $HOME/.asdf
git checkout "$(git describe --abbrev=0 --tags)"
cd -

# ToDo
# Install via asdf:
#- vim
#- npm, nodejs

info "Installing some media tools..."
sudo apt-get -y install winff easytag audacity gimp vlc
success "Done."

if isUbuntu
then
  info "Modifing gnome settings..."
  set +e
  gsettings set org.gnome.desktop.interface show-battery-percentage true
  gsettings set org.gnome.shell enable-hot-corners false
  gsettings set org.gnome.shell.app-switcher current-workspace-only true
  set -e
  success "Done."
fi

info "Running dotfiles setup..."
. ../install.sh --skip-clone
success "Done."
