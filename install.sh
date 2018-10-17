#!/bin/bash

accent='\033[1;33m'
normal='\033[0m'

isOS()
{
    shopt -s nocasematch
    if [[ "$OSTYPE" == *"$1"* ]]
    then
        return 0;
    fi

    return 1;
}

isProgramInstalled()
{
    command -v $1 >/dev/null 2>&1 || { return 1 >&2; }
    return 0
}

if ! isProgramInstalled git
then
    echo "No Git found!"
    exit
fi

dotfilesDir='~/.dotfiles'
if [ ! -d $dotfilesDir ]; then
    git clone https://github.com/tklepzig/dotfiles.git $dotfilesDir
    cd $dotfilesDir
else
    cd $dotfilesDir
    git fetch && git merge --ff-only
fi

# now we are in ~/.dotfiles


# Add entry to .bashrc
profileFile='.bashrc'
if isOS darwin
then
    profileFile='.bash_profile'
fi

if [ ! -f ~/$profileFile ]
then
    touch ~/$profileFile
fi

if ! grep -q "~/.dotfiles/bashrc.sh" ~/$profileFile
then
    echo "if [ -f ~/.dotfiles/bashrc.sh ]; then . ~/.dotfiles/bashrc.sh; fi" >> ~/$profileFile;
fi


# create symlinks
ln -sf ~/.dotfiles/vimrc ~/.vimrc

# git config
./git-config.sh
