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

> When there should be no history at all, create a orphaned branch in the
> old-repo, see
> https://git-scm.com/docs/git-checkout#Documentation/git-checkout.txt---orphanltnew-branchgt

## Ignore files/dirs when doing git log

    git log -- ':!path/to/ignore' ':!path/to/ignore2'

For example when using `g lp` and ignoring changes in `package-lock.json`

    g lp -- ':!package-lock.json'
