#!/usr/bin/env zsh

echo "# Toolbox - Docs" > $(dirname "$0")/index.md
for file in $(dirname "$0")/*.md
do
  if [ "$(basename $file)" = "index.md" ]
  then
    continue
  fi
echo "- [$(basename "$file" ".md")]($(basename "$file" ))" >> $(dirname "$0")/index.md
done
