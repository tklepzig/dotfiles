#!/bin/bash

url=$1
name=$(curl -L $url 2>/dev/null | grep -oE "<title>.*</title>" | sed 's/<title>//' | sed 's/<\/title>//')

echo "[$name]($url)" >> $HOME/bookmarks.md

