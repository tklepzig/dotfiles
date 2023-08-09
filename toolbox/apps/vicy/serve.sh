#!/usr/bin/env zsh

cd $dotfiles_path/toolbox/apps/vicy
[ ! -f package-lock.json ] && npm i && npm run build
npm start
cd -
