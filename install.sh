#!/bin/bash

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

accent='\033[1;33m'
normal='\033[0m'
profileFile='.bashrc'
if isOS darwin
then
    profileFile='.bash_profile'
fi

echo -e "${accent}Searching for Git...${normal}"
if ! isProgramInstalled git
then
    echo -e "${accent}No Git found!${normal}"
    exit
fi
echo -e "${accent}Git found: $(which git).${normal}"


echo -e "${accent}Cloning Repo...${normal}"
pushd ~
rm -rf .dotfiles
git clone --depth=1 https://github.com/tklepzig/dotfiles.git .dotfiles
popd
echo -e "${accent}Done.${normal}"


echo -e "${accent}Configuring $profileFile...${normal}"
if [ ! -f ~/$profileFile ]
then
    touch ~/$profileFile
fi
if ! grep -q "~/.dotfiles/bashrc.sh" ~/$profileFile
then
    echo "if [ -f ~/.dotfiles/bashrc.sh ]; then . ~/.dotfiles/bashrc.sh; fi" >> ~/$profileFile;
fi
echo -e "${accent}Done.${normal}"


echo -e "${accent}Creating Symlinks...${normal}"
ln -sf ~/.dotfiles/vimrc ~/.vimrc
echo -e "${accent}Done.${normal}"

echo -e "${accent}Configuring Git${normal}"
~/.dotfiles/git-config.sh
echo -e "${accent}Done.${normal}"

if isProgramInstalled code-insiders
then
    echo -e "${accent}Installing VS Code extensions${normal}"
    ~/.dotfiles/vscode-extensions.sh
    echo -e "${accent}Done.${normal}"

    echo -e "${accent}Creating Symlinks for VS Code config...${normal}"
    vscodeConfigPath=""
    if isOS linux
    then
        vscodeConfigPath="~/.config/Code/User"
        ln -sf ~/.dotfiles/vscode-keybindings.json $vscodeConfigPath/settings.json
    fi
    if isOS darwin
    then
        vscodeConfigPath="~/Library/Application Support/Code/User"
        ln -sf ~/.dotfiles/vscode-keybindings-macos.json $vscodeConfigPath/settings.json
    fi
    ln -sf ~/.dotfiles/vscode-settings.json $vscodeConfigPath/keybindings.json
    echo -e "${accent}Done.${normal}"
fi
