#!/usr/bin/env zsh

git fetch
currentBranch=$(git symbolic-ref HEAD)
if [ "$1" = "--all" ]
then
    for branch in $(git for-each-ref --format='%(refname)' refs/heads/); do
        if [ $currentBranch != $branch ]
        then
            git fetch origin +$branch:$branch
        fi
    done
fi
git fetch origin $currentBranch
git merge --ff-only
