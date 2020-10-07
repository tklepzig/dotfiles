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

checkInstallation()
{
  [[ -n $2 ]] && installName=$2 || installName=$1

  if ! isProgramInstalled $1
  then
    error "Warning: $1 is not installed (Try \"apt install $installName\")"
  fi
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

addLinkToFile() {
  src=$1
  target=$2
  info "Adding link to $target..."
  if [ ! -f $target ]
  then
    touch $target
  fi
  if ! grep -q "$src" $target
  then
    echo "source $src" >> $target;
  fi
  success "Done."
}

removePatternFromFile() {
  target=$1
  pattern=$2
  info "Remove link from $target... with pattern $pattern"
  if [ -f $HOME/$target ]
  then
    sed /$pattern/d $HOME/$target > $HOME/$target.tmp && mv $HOME/$target.tmp $HOME/$target
  fi
  success "Done."
}
