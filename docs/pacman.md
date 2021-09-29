Remove packages

    pacman -Rcs

Lists all packages that were installed as a dependency and are no longer needed

    pacman -Qdt

Remove all no longer needed packages

    pacman -Qdtq | pacman -Rcs -

List Packages

    ls /var/cache/pacman/pkg/ | less

Clear Cache for all non-installed packages

    sudo pacman -Sc

Clear Cache completely

    sudo pacman -Scc
