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
