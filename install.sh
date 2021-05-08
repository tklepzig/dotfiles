#!/bin/bash

set -e
dotfilesDir=$HOME/.dotfiles

if [ ! -f $dotfilesDir/common.sh ]
then
  source <(curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/common.sh)
else
  source $dotfilesDir/common.sh
fi

skipClone=0
profiles="basic"
for var in "$@"
do
  case "$var" in
    "--skip-clone")
      skipClone=1
      ;;
    --profiles=*)
      profiles="${profiles},${var#*=}"
      ;;
  esac
done

addPlugin() {
  sed 's/\"pluginfile/source \$HOME\/.dotfiles\/vim\/'"$1"'\/plugins.vim\
\"pluginfile/g' $HOME/.plugins.vim > $HOME/.plugins.vim.tmp && mv $HOME/.plugins.vim.tmp $HOME/.plugins.vim
}

installProfiles() {
  local IFS=','
  for profile in $profiles
  do
    info "Installing Profile $profile..."
    addPlugin $profile
    addLinkToFile "$dotfilesDir/vim/$profile/vimrc" "$HOME/.vimrc"
    if [ -f $dotfilesDir/vim/$profile/install.sh ]
    then
      source $dotfilesDir/vim/$profile/install.sh
    fi
    success "Done."
  done
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

if isOS darwin
then
  addLinkToFile "$dotfilesDir/tmux/vars.osx.conf" "$HOME/.tmux.conf"
else
  addLinkToFile "$dotfilesDir/tmux/vars.linux.conf" "$HOME/.tmux.conf"
fi
addLinkToFile "$dotfilesDir/tmux/tmux.conf" "$HOME/.tmux.conf"
addLinkToFile "$dotfilesDir/tmux/themes/tmux.lcars.conf" "$HOME/.tmux.conf"

checkInstallation exa
checkInstallation tmux
checkInstallation zsh
checkInstallation lynx

if [ -f $HOME/.plugins.vim ]
then
  mv $HOME/.plugins.vim $HOME/.plugins.vim.backup
fi
cp $dotfilesDir/vim/plugins.vim $HOME/.plugins.vim
addLinkToFile "$HOME/.plugins.vim" "$HOME/.vimrc"

installProfiles

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
