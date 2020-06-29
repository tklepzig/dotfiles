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
skipClone=0
profiles="basic,extended"
for var in "$@"
do
    case "$var" in
        "--skip-clone")
            skipClone=1
            ;;
        "-u")
            updateOnly=1
            ;;
          --profiles=*)
            profiles="${profiles},${var#*=}"
            ;;
    esac
done

hasProfile() {
  local IFS=','
  for profile in $profiles
  do
    if [ "$profile" = "$1" ]
    then
      return 0
    fi
  done
  return 1
}

addPlugin() {
  sed 's/\"pluginfile/source \$HOME\/.dotfiles\/vim\/'"$1"'\/plugins.vim\
\"pluginfile/g' $HOME/.plugins.vim > $HOME/.plugins.vim.tmp && mv $HOME/.plugins.vim.tmp $HOME/.plugins.vim
}



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

addLinkToFile "$dotfilesDir/zshrc.sh" "$HOME/.zshrc"
addLinkToFile "$dotfilesDir/tmux.conf" "$HOME/.tmux.conf"


if [ -f $HOME/.plugins.vim ]
then
  mv $HOME/.plugins.vim $HOME/.plugins.vim.backup
fi

cp $dotfilesDir/vim/plugins.vim $HOME/.plugins.vim

addPlugin basic

if hasProfile extended
then
  addPlugin extended
fi

addLinkToFile "$HOME/.plugins.vim" "$HOME/.vimrc"
addLinkToFile "$dotfilesDir/vim/basic/vimrc" "$HOME/.vimrc"

if hasProfile extended
then
  addLinkToFile "$dotfilesDir/vim/extended/vimrc" "$HOME/.vimrc"
fi

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

if hasProfile extended
then
  info "Creating Symlinks..."
  mkdir -p $HOME/.vim
  ln -sf $dotfilesDir/vim/extended/coc-settings.json $HOME/.vim/coc-settings.json
  success "Done."
fi

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
$dotfilesDir/git/git-config.sh
success "Done."

# Docker completion for zsh
if isProgramInstalled docker
then
  info "Installing docker completion..."
  mkdir -p $HOME/.zsh/completion
  curl -L https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker > $HOME/.zsh/completion/_docker 2>/dev/null
  curl -L https://raw.githubusercontent.com/docker/compose/master/contrib/completion/zsh/_docker-compose > $HOME/.zsh/completion/_docker-compose 2>/dev/null
  success "Done."
fi

if isProgramInstalled zsh && [ "$SHELL" != "$(which zsh)" ]
then
  info "Setting default shell to zsh..."
  chsh -s $(which zsh)
  success "Done. Please notice: In order to use the new shell, you have to logout and back in."
fi

checkInstallation tmux
checkInstallation zsh
checkInstallation lynx

if hasProfile extended
then
  checkInstallation ag silversearcher-ag
  checkInstallation ranger
  checkInstallation fzf
fi
