# Git

## Find deleted file in history

If you know the exact path

    git lna --full-history -- path/to/file

If you only know some parts

    git lna --full-history -- **/thefile.*

Restore the file

    g show <SHA>:./path/to/file

> Alternatives
>
>     g cat-file -p <SHA>:./path/to/file
>     git checkout <SHA> -- path/to/file

## Change base branch

Given you're working on a branch called `feature` and you want to change the
base from `oldBase` to `newBase`

    git rebase --onto newBase oldBase feature

## Push existing branch of old repo into new created repo

    cd old-repo
    git push https://github.com/new/repo.git +old-branch:new-branch [+old-other:new-other ...]
