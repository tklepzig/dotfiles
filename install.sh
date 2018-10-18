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

dotfilesDir=$HOME/.dotfiles
echo -e "${accent}Cloning Repo...${normal}"
rm -rf $dotfilesDir
git clone --depth=1 https://github.com/tklepzig/dotfiles.git $dotfilesDir
echo -e "${accent}Done.${normal}"


echo -e "${accent}Configuring $profileFile...${normal}"
if [ ! -f $HOME/$profileFile ]
then
    touch $HOME/$profileFile
fi
if ! grep -q "$dotfilesDir/bashrc.sh" $HOME/$profileFile
then
    echo "if [ -f $dotfilesDir/bashrc.sh ]; then . $dotfilesDir/bashrc.sh; fi" >> $HOME/$profileFile;
fi
echo -e "${accent}Done.${normal}"


echo -e "${accent}Creating Symlinks...${normal}"
ln -sf $dotfilesDir/vimrc $HOME/.vimrc
echo -e "${accent}Done.${normal}"

echo -e "${accent}Configuring Git${normal}"
$dotfilesDir/git-config.sh
echo -e "${accent}Done.${normal}"

if isProgramInstalled code-insiders
then
    echo -e "${accent}Installing VS Code extensions${normal}"
    $dotfilesDir/vscode-extensions.sh
    echo -e "${accent}Done.${normal}"

    echo -e "${accent}Creating Symlinks for VS Code config...${normal}"
    vscodeConfigPath=""
    if isOS linux
    then
        vscodeConfigPath="$HOME/.config/Code - Insiders/User"
        ln -sf $dotfilesDir/vscode-keybindings.json "$vscodeConfigPath/keybindings.json"
    fi
    if isOS darwin
    then
        vscodeConfigPath="$HOME/Library/Application Support/Code - Insiders/User"
        ln -sf $dotfilesDir/vscode-keybindings-macos.json "$vscodeConfigPath/keybindings.json"
    fi
    ln -sf $dotfilesDir/vscode-settings.json "$vscodeConfigPath/settings.json"
    echo -e "${accent}Done.${normal}"
fi
