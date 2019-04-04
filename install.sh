#!/bin/bash

set -e

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

accent='\033[0;33m'
note='\033[2;33m'
success='\033[0;92m'
error='\033[0;91m'
reset='\033[0m'

info()
{
    echo -e "${accent}$1${reset}"
}

note()
{
    echo -e "${note}$1${reset}"
}

success()
{
    echo -e "${success}$1${reset}"
}

error()
{
    echo -e "${error}$1${reset}"
}

profileFile='.bashrc'
if isOS darwin
then
    profileFile='.bash_profile'
fi

zshProfileFile='.zshrc'

skipVsCodeConfig=0
for var in "$@"
do
    case "$var" in
        "--skip-vsc")
            skipVsCodeConfig=1
            ;;
    esac
done

info "Searching for Git..."
if ! isProgramInstalled git
then
    error "No Git found!"
    exit
fi
success "Git found: $(which git)."

dotfilesDir=$HOME/.dotfiles
info "Cloning Repo..."
rm -rf $dotfilesDir
git clone --depth=1 https://github.com/tklepzig/dotfiles.git $dotfilesDir > /dev/null 2>&1
success "Done."


info "Configuring $profileFile..."
if [ ! -f $HOME/$profileFile ]
then
    touch $HOME/$profileFile
fi
if ! grep -q "$dotfilesDir/bashrc.sh" $HOME/$profileFile
then
    echo "if [ -f $dotfilesDir/bashrc.sh ]; then . $dotfilesDir/bashrc.sh; fi" >> $HOME/$profileFile;
fi
success "Done."


info "Configuring $zshProfileFile..."
if [ ! -f $HOME/$zshProfileFile ]
then
    touch $HOME/$zshProfileFile
fi
if ! grep -q "$dotfilesDir/zshrc.sh" $HOME/$zshProfileFile
then
    echo "if [ -f $dotfilesDir/zshrc.sh ]; then . $dotfilesDir/zshrc.sh; fi" >> $HOME/$zshProfileFile;
fi
success "Done."


info "Creating Symlinks..."
ln -sf $dotfilesDir/vimrc $HOME/.vimrc
success "Done."

info "Configuring Git..."
$dotfilesDir/git-config.sh
success "Done."

if isProgramInstalled code-insiders && [ "$skipVsCodeConfig" = "0" ]
then
    info "Installing VS Code extensions..."
    $dotfilesDir/vscode-extensions.sh
    success "Done."

    info "Creating Symlinks for VS Code config..."
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
    success "Done."
fi


if isProgramInstalled docker && isOS darwin
then
    info "Installing docker bash completion..."
    pushd /usr/local/etc/bash_completion.d > /dev/null
    ln -sf /Applications/Docker.app/Contents/Resources/etc/docker.bash-completion
    popd > /dev/null
    success "Done."
fi

if isProgramInstalled docker-machine && isOS darwin
then
    info "Installing docker-machine bash completion..."
    pushd /usr/local/etc/bash_completion.d > /dev/null
    ln -sf /Applications/Docker.app/Contents/Resources/etc/docker-machine.bash-completion
    popd > /dev/null
    success "Done."
fi

if isProgramInstalled docker-compose && isOS darwin
then
    info "Installing docker-compose bash completion..."
    pushd /usr/local/etc/bash_completion.d > /dev/null
    ln -sf /Applications/Docker.app/Contents/Resources/etc/docker-compose.bash-completion
    popd > /dev/null
    success "Done."
fi
