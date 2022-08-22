#!/usr/bin/env zsh

set -e
dotfilesDir=$HOME/.dotfiles
#profilesPath=$HOME/.df-profiles

source <(curl -Ls https://raw.githubusercontent.com/tklepzig/dotfiles/master/logger.sh)

isOS()
{
  if [[ "$OSTYPE:l" == *"$1:l"* ]]
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

checkInstallation()
{
  [[ -n $2 ]] && installName=$2 || installName=$1

  if ! isProgramInstalled $1
  then
    error "Warning: $1 is not installed (Try \"apt install $installName\")"
  fi
}

addLinkToFile() {
  src=$1
  target=$2
  cmd=${3:-source}

  if [ ! -f $target ]
  then
    touch $target
  fi
  if ! grep -q "$src" $target
  then
    info "Adding link to $target..."
    echo "$cmd $src" >> $target;
    success "Done."
  fi
}

addVimPlugin() {
  sed 's/\"pluginfile/source \$HOME\/.dotfiles\/vim\/'"$1"'\/plugins.vim\
\"pluginfile/g' $HOME/.plugins.vim > $HOME/.plugins.vim.tmp && mv $HOME/.plugins.vim.tmp $HOME/.plugins.vim
}

installProfiles() {
  for profile in basic ${=DOTFILES_PROFILES}
  do
    info "Installing Profile $profile..."

    addVimPlugin $profile
    addLinkToFile "$dotfilesDir/vim/$profile/vimrc" "$HOME/.vimrc"
    if [ -f $dotfilesDir/vim/$profile/install.sh ]
    then
      source $dotfilesDir/vim/$profile/install.sh
    fi

    addLinkToFile "$dotfilesDir/zsh/$profile/zshrc.zsh" "$HOME/.zshrc"

    success "Done."
  done
}

skipClone=0
for var in "$@"
do
  case "$var" in
    "--skip-clone")
      skipClone=1
      ;;
  esac
done

info "Searching for zsh..."
if ! isProgramInstalled zsh
then
  error "No zsh found!"
  error "Aborting"
  exit
fi
success "zsh found: $(which zsh)."

info "Searching for Git..."
if ! isProgramInstalled git
then
  error "No Git found!"
  error "Aborting"
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

source $dotfilesDir/setTheme.zsh
addLinkToFile "$dotfilesDir/colours.vim" "$HOME/.vimrc"
addLinkToFile "$dotfilesDir/colours.zsh" "$HOME/.zshrc"
addLinkToFile "$dotfilesDir/colours.zsh" "$HOME/.tmux.conf"

if [ ! -f "$HOME/.plugins.custom.vim" ]
then
  echo "\"Plug 'any/vim-plugin'" > $HOME/.plugins.custom.vim
fi

if [ -f "$HOME/.plugins.vim" ]
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

info "Installing and updating vim plugins..."
# "echo" to suppress the "Please press ENTER to continue...
echo | vim +PlugInstall +PlugUpdate +qall > /dev/null 2>&1
success "Done."

# TODO
# Ensure the following line is in .zshrc after all df includes
# [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

info "Setting up zsh sounds..."
mkdir -p $HOME/.zsh-sounds
cp $dotfilesDir/zsh/sounds-readme.md $HOME/.zsh-sounds/README.md
success "Done."

if isOS darwin
then
  addLinkToFile "$dotfilesDir/tmux/vars.osx.conf" "$HOME/.tmux.conf"
else
  addLinkToFile "$dotfilesDir/tmux/vars.linux.conf" "$HOME/.tmux.conf"
fi
addLinkToFile "$dotfilesDir/tmux/tmux.conf" "$HOME/.tmux.conf"

if isProgramInstalled kitty
then
  addLinkToFile "$dotfilesDir/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf" "include"

  if [ "$DOTFILES_THEME" = "lcars-light" ]
  then
    addLinkToFile "$dotfilesDir/kitty/kitty.lcars-light.conf" "$HOME/.config/kitty/kitty.conf" "include"
  fi
fi

checkInstallation exa
checkInstallation tmux
checkInstallation zsh
checkInstallation lynx

info "Configuring Git..."
$dotfilesDir/git/git-config.sh
success "Done."

if isProgramInstalled docker
then
  info "Installing docker completion..."
  mkdir -p $HOME/.zsh/completion
  curl -L https://raw.githubusercontent.com/docker/cli/master/contrib/completion/zsh/_docker > $HOME/.zsh/completion/_docker 2>/dev/null
  curl -L https://raw.githubusercontent.com/docker/compose/master/contrib/completion/zsh/_docker-compose > $HOME/.zsh/completion/_docker-compose 2>/dev/null
  success "Done."
fi

if isOS darwin
then
  defaultShell=$(dscl . -read $HOME/ UserShell | sed 's/UserShell: //')
else
  defaultShell=$(grep ^$(id -un): /etc/passwd | cut -d : -f 7-)
fi

if [ "$defaultShell" != "$(which zsh)" ]
then
  info "Setting default shell to zsh..."
  chsh -s $(which zsh)
  success "Done. Please notice: In order to use the new shell, you have to logout and back in."
fi
