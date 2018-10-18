#!/bin/bash
git fetch
currentBranch=$(git symbolic-ref HEAD)
for branch in $(git for-each-ref --format='%(refname)' refs/heads/); do
    if [ $currentBranch != $branch ]
    then
        git fetch origin +$branch:$branch
    fi
done
git fetch origin $currentBranch
git merge --ff-only
