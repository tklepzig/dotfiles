#!/usr/bin/env zsh

[ ! -f ./package-lock.json ] && npm i && npm run build
npm start
