Remove packages

    pacman -Rcs

Lists all packages that were installed as a dependency and are no longer needed

    pacman -Qdt

Remove all no longer needed packages

    pacman -Qdtq | pacman -Rcs -
