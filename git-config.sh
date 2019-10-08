#!/bin/bash

logCommon="-c core.pager='less -SRF' log --graph --all --date=human --format='%C(yellow)%h%C(reset) %C(cyan)%><(15)%ad%C(reset) %s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%Creset'"
reflogCommon="-c core.pager='less -SRF' reflog --date=human --format='%C(yellow)%h%C(reset) %C(dim yellow)%<(10)%gd%C(reset) %C(cyan)%><(15)%ad%C(reset) %gs%C(reset)%C(auto)%d%Creset'"
stashCommon="-c core.pager='less -SRF' stash list --date=human --format='%C(yellow)%h%C(reset) %C(dim yellow)%<(10)%gd%C(reset) %C(cyan)%><(15)%ad%C(reset) %gs%C(reset)'"

# general config
git config --global credential.helper store
git config --global push.default simple
git config --global fetch.prune true
git config --global pull.rebase true
#git config --global diff.tool meld
#git config --global merge.tool kdiff3
#git config --global mergetool.keepBackup false
#git config --global merge.kdiff3.keepBackup false
#git config --global merge.kdiff3.trustExitCode false
#git config --global merge.kdiff3.keepTemporaries false
git config --global core.editor "vim"
git config --global color.status always
git config --global grep.extendedRegexp true

# aliases
git config --global alias.s  "status -sb"
git config --global alias.sa "status -sb -uall"
git config --global alias.si "status -sb --ignored"

git config --global alias.dt "difftool --dir-diff"
git config --global alias.dts "difftool --dir-diff --staged"

git config --global alias.d "diff --word-diff"
git config --global alias.ds "diff --staged --word-diff"

git config --global alias.l "$logCommon -10"
git config --global alias.ll "$logCommon"
git config --global alias.lm "$logCommon --merges"
git config --global alias.ln "$logCommon --name-status"
git config --global alias.lp "$logCommon -p"
git config --global alias.ld "$logCommon --date-order"
git config --global alias.ls "$logCommon --simplify-by-decoration"
git config --global alias.lf "$logCommon --follow"
git config --global alias.lfp "$logCommon --follow -p"

git config --global alias.lb "!f() { currentBranch=\$(git rev-parse --abbrev-ref HEAD); git log --oneline --graph --date=human --format='%C(yellow)%h%C(reset) %C(cyan)%><(15)%ad%C(reset) %s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%Creset' --no-merges \${1:-\$currentBranch} --not \$(git for-each-ref --format=\"%(refname)\" refs/heads | grep -Fv refs/heads/\${1:-\$currentBranch}); }; f"
git config --global alias.lbp "!f() { currentBranch=\$(git rev-parse --abbrev-ref HEAD); git log --oneline --graph --date=human --format='%C(yellow)%h%C(reset) %C(cyan)%><(15)%ad%C(reset) %s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%Creset' --no-merges -p \${1:-\$currentBranch} --not \$(git for-each-ref --format=\"%(refname)\" refs/heads | grep -Fv refs/heads/\${1:-\$currentBranch}); }; f"

git config --global alias.rl "$reflogCommon -10"
git config --global alias.rll "$reflogCommon"

git config --global alias.r "reset"
git config --global alias.rh "reset --hard"
git config --global alias.rs "reset --soft"

git config --global alias.a "add --all"
git config --global alias.ap "add --patch"
git config --global alias.cm "commit -m"
git config --global alias.cma "commit --amend"
git config --global alias.acm "!f() { git add --all && git commit -m \"\$1\"; }; f"
git config --global alias.acmp "!f() { git add --all && git commit -m \"\$1\" && git push --follow-tags; }; f"

git config --global alias.p "push --follow-tags"
git config --global alias.pn "!f() { currentBranch=\$(git rev-parse --abbrev-ref HEAD); git push -u \${1:-origin} \$currentBranch; }; f"
#git config --global alias.pt "push --tags"

git config --global alias.c "checkout"
git config --global alias.cb "checkout -b"

git config --global alias.b "branch"
git config --global alias.bd "branch -d"
git config --global alias.ba "branch -a"
git config --global alias.bnm "branch --no-merged"
git config --global alias.bv "branch -vv"
git config --global alias.bc "!f() { git remote prune origin; git branch -vv | grep 'origin/.*: gone]' | awk '{print \$1}' | xargs git branch -d; }; f"
git config --global alias.bcD "!f() { git remote prune origin; git branch -vv | grep 'origin/.*: gone]' | awk '{print \$1}' | xargs git branch -D; }; f"

git config --global alias.f "fetch"
git config --global alias.fm "!f() { . ~/.dotfiles/git-fetch-merge.sh; }; f"

git config --global alias.m "merge"
git config --global alias.ma "merge --abort"
git config --global alias.mff "merge --ff-only"
git config --global alias.mr "merge --no-ff"
git config --global alias.mt "mergetool"

git config --global alias.rb "rebase"
git config --global alias.rbc "rebase --continue"
git config --global alias.rba "rebase --abort"

git config --global alias.undo "!f() { git reset --hard \$1 && git clean -df \$1; }; f"

git config --global alias.dummy "commit --allow-empty -m 'dummy commit, contains no change'"

git config --global alias.sw "show --word-diff --format=\"%C(yellow)%h%C(reset) - %C(cyan)(%ar)%C(reset) %B%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%Creset\""
git config --global alias.swn "show --word-diff --name-status --format=\"%C(yellow)%h%C(reset) - %C(cyan)(%ar)%C(reset) %s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%Creset\""

git config --global alias.st "stash"
git config --global alias.stp "stash pop"
git config --global alias.stl "$stashCommon"
git config --global alias.sta "stash apply"
git config --global alias.sts "stash show"

git config --global alias.t "tag"
git config --global alias.td "tag -d"
git config --global alias.tl "tag --list"
git config --global alias.tlr "!f() { git show-ref --tags | sed 's?.*refs/tags/??'; }; f"

git config --global alias.wta "worktree add"
git config --global alias.wtp "worktree prune"
git config --global alias.wtl "worktree list"

git config --global alias.cp "cherry-pick"
git config --global alias.cpn "cherry-pick -n"

git config --global alias.rv "revert"
git config --global alias.rvn "revert -n"

git config --global alias.prn "!f() { . ~/.dotfiles/git-github-pr.sh new; }; f"
git config --global alias.pro "!f() { . ~/.dotfiles/git-github-pr.sh; }; f"
