isOS()
{
    shopt -s nocasematch
    if [[ "$OSTYPE" == *"$1"* ]]
    then
        return 0;
    fi

    return 1;
}

isUbuntu()
{
    shopt -s nocasematch
    if [[ `uname -v` == *"ubuntu"* ]]
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

addLinkToFile() {
  src=$1
  target=$2
  info "Adding link to $target..."
  if [ ! -f $HOME/$target ]
  then
    touch $HOME/$target
  fi
  if ! grep -q "$dotfilesDir/$src" $HOME/$target
  then
    echo "source $dotfilesDir/$src" >> $HOME/$target;
  fi
  success "Done."
}

removeLinkFromFile() {
  target=$1
  info "Remove link from $target..."
  if [ -f $HOME/$target ]
  then
    sed /.dotfiles/d $HOME/$target > $HOME/$target.tmp && mv $HOME/$target.tmp $HOME/$target
  fi
  success "Done."
}
