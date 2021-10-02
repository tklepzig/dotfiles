Remove packages

    sudo pacman -Rcs

Lists all packages that were installed as a dependency and are no longer needed

    sudo pacman -Qdt

Remove all no longer needed packages

    sudo pacman -Qdtq | sudo pacman -Rcs -

List Packages

    sudo pacman -Q

Get Info about specific package

    sudo pacman -Qi <package>

Clear Cache for all non-installed packages

    sudo pacman -Sc

Clear Cache completely

    sudo pacman -Scc
