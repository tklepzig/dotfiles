#!/bin/bash

set -e
dotfilesDir=$HOME/.dotfiles

if [ ! -f $dotfilesDir/common.sh ]
then
  source <(curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/common.sh)
else
  source $dotfilesDir/common.sh
fi

updateOnly=0
skipVsCodeConfig=1
skipClone=0
for var in "$@"
do
    case "$var" in
        "--include-vsc")
            skipVsCodeConfig=0
            ;;
        "--skip-clone")
            skipClone=1
            ;;
        "-u")
            updateOnly=1
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

addLinkToFile "bashrc.sh" $profileFile
addLinkToFile "zshrc.sh" ".zshrc"
addLinkToFile "vim/vimrc" ".vimrc"
addLinkToFile "tmux.conf" ".tmux.conf"

if [ "$updateOnly" = "0" ]
then
  info "Creating Backup..."
  if [ -d $HOME/.vim ]
  then
    cp -r $HOME/.vim $HOME/.vim-backup
  fi
  if [ -d $HOME/.zsh ]
  then
    cp -r $HOME/.zsh $HOME/.zsh-backup
  fi
  success "Done."
fi

info "Creating Symlinks..."
mkdir -p $HOME/.vim
ln -sf $dotfilesDir/vim/coc-settings.json $HOME/.vim/coc-settings.json
success "Done."

if [ ! -d "$HOME/.vim/autoload/plug.vim" ]
then
    info "Installing vim-plug..."
    curl -fLo $HOME/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim>/dev/null 2>&1
    success "Done."
fi

info "Installing vim plugins..."
# "echo" to suppress the "Please press ENTER to continue...
echo | vim +PlugInstall +qall > /dev/null 2>&1
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

# Docker completion for zsh on linux
if isProgramInstalled docker && isOS linux
then
  info "Installing docker completion..."
  mkdir -p $HOME/.zsh/completion
  curl -L https://raw.githubusercontent.com/docker/compose/1.24.0/contrib/completion/zsh/_docker-compose > $HOME/.zsh/completion/_docker-compose 2>/dev/null
  success "Done."
fi
