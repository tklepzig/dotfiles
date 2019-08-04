#!/bin/bash

set -e
dotfilesDir=$HOME/.dotfiles

if [ ! -f $dotfilesDir/common.sh ]
then
  source <(curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/common.sh)
else
  source $dotfilesDir/common.sh
fi

profileFile='.bashrc'
if isOS darwin
then
    profileFile='.bash_profile'
fi

zshProfileFile='.zshrc'

skipVsCodeConfig=0
skipClone=0
for var in "$@"
do
    case "$var" in
        "--skip-vsc")
            skipVsCodeConfig=1
            ;;
        "--skip-clone")
            skipClone=1
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

if [ "$skipClone" = "0" ]
then
  info "Cloning Repo..."
  rm -rf $dotfilesDir
  git clone --depth=1 https://github.com/tklepzig/dotfiles.git $dotfilesDir > /dev/null 2>&1
  success "Done."
fi


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
ln -sf $dotfilesDir/tmux.conf $HOME/.tmux.conf
success "Done."

if [ ! -d "$HOME/.vim/bundle/Vundle.vim" ]
then
    info "Installing Vundle..."
    git clone https://github.com/VundleVim/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim > /dev/null 2>&1
    success "Done."
fi

info "Installing vim plugins..."
# "echo" to suppress the "Please press ENTER to continue...
echo | vim +PluginInstall +qall > /dev/null 2>&1
success "Done."

# if [ ! -d "$HOME/.tmux/plugins/tpm" ]
# then
#     info "Installing TPM..."
#     git clone https://github.com/tmux-plugins/tpm $HOME/.tmux/plugins/tpm > /dev/null 2>&1
#     success "Done."
# fi

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

# Docker completion for zsh on linux

if isProgramInstalled docker && isOS linux
then
  mkdir -p $HOME/.zsh/completion
  curl -L https://raw.githubusercontent.com/docker/compose/1.24.0/contrib/completion/zsh/_docker-compose > $HOME/.zsh/completion/_docker-compose 2>/dev/null
fi
