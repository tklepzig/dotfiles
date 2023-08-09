#!/bin/bash

printf "All installed kernel versions: \n\n`dpkg -l|grep linux-image`"
printf "\n\nCurrent kernel version: `uname -r`"
printf "\n\nEnter \"sudo apt-get purge linux-image-xxx-generic\" where xxx is the last but two kernel version\n\n\”"
