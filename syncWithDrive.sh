#!/usr/bin/env zsh

if [ -z $1 ]
then
	echo "Usage: syncWithDrive.sh /path/to/drive"
	exit 1
fi

dotfilesDir=$HOME/.dotfiles
rsync -avz --stats --delete --exclude  ".git" "$dotfilesDir/" "$1/dotfiles"
