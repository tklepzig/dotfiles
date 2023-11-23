#!/usr/bin/env zsh

logFormat="%C(yellow)%h%C(reset) %C(cyan)%><(15)%ad%C(reset) %s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%Creset"
withLess="-c core.pager='less -SRF'"
reflogCommon="-c core.pager='less -SRF' reflog --date=human --format='%C(yellow)%h%C(reset) %C(dim yellow)%<(10)%gd%C(reset) %C(cyan)%><(15)%ad%C(reset) %gs%C(reset)%C(auto)%d%Creset'"
stashCommon="-c core.pager='less -SRF' stash list --date=human --format='%C(yellow)%h%C(reset) %C(dim yellow)%<(10)%gd%C(reset) %C(cyan)%><(15)%ad%C(reset) %gs%C(reset)'"

# general config
git config --global credential.helper store
git config --global push.default simple
git config --global fetch.prune true
git config --global pull.rebase true
git config --global diff.tool vimdiff
git config --global merge.tool vimdiff
git config --global core.editor vim
git config --global color.status always
git config --global grep.extendedRegexp true
git config --global help.autoCorrect prompt
git config --global rerere.enabled true


# Try delta (https://dandavison.github.io/delta) as diff viewer
git config --global core.pager delta
git config --global diff.colorMoved default
git config --global merge.conflictstyle diff3
git config --global interactive.diffFilter "delta --color-only"
git config --global delta.navigate true
git config --global delta.side-by-side true
git config --global delta.line-numbers true

setDefaultBranch="defaultBranch=\$([ -f \"\$(git rev-parse --show-toplevel)/.git/refs/heads/master\" ] && echo master || echo main)"

# aliases
git config --global alias.s  "status -sb"
git config --global alias.sa "status -sb -uall"
git config --global alias.si "status -sb --ignored"

git config --global alias.dt "difftool --dir-diff"
git config --global alias.dts "difftool --dir-diff --staged"

git config --global alias.d "diff -w --word-diff"
git config --global alias.dw "diff -w --color --word-diff-regex=."
git config --global alias.ds "diff -w --staged --word-diff"
git config --global alias.dws "diff -w --staged --color --word-diff-regex=."

git config --global alias.l "$withLess log --graph --date=human --format='$logFormat'"
git config --global alias.la "$withLess log --graph --date=human --format='$logFormat' --all"
git config --global alias.ln "$withLess log --graph --date=human --format='$logFormat' --name-status"
git config --global alias.lna "$withLess log --graph --date=human --format='$logFormat' --name-status --all"
git config --global alias.lp "$withLess log --graph --date=human --format='$logFormat' -p"
git config --global alias.lpa "$withLess log --graph --date=human --format='$logFormat' -p --all"
git config --global alias.ld "$withLess log --graph --date=human --format='$logFormat' --date-order"
git config --global alias.lda "$withLess log --graph --date=human --format='$logFormat' --date-order --all"
git config --global alias.ls "$withLess log --graph --date=human --format='$logFormat' --simplify-by-decoration"
git config --global alias.lsa "$withLess log --graph --date=human --format='$logFormat' --simplify-by-decoration --all"
git config --global alias.lf "$withLess log --date=human --format='$logFormat' --follow"
git config --global alias.lfa "$withLess log --date=human --format='$logFormat' --follow --all"
git config --global alias.lfp "$withLess log --date=human --format='$logFormat' --follow -p"
git config --global alias.lfpa "$withLess log --date=human --format='$logFormat' --follow -p --all"

git config --global alias.lb "!f() { currentBranch=\$(git rev-parse --abbrev-ref HEAD); git log --graph --date=human --format='$logFormat' --no-merges \${1:-\$currentBranch} --not \$(git for-each-ref --format=\"%(refname)\" refs/heads | grep -Fv refs/heads/\${1:-\$currentBranch}); }; f"
git config --global alias.lbp "!f() { currentBranch=\$(git rev-parse --abbrev-ref HEAD); git log --graph --date=human --format='$logFormat' --no-merges -p \${1:-\$currentBranch} --not \$(git for-each-ref --format=\"%(refname)\" refs/heads | grep -Fv refs/heads/\${1:-\$currentBranch}); }; f"

git config --global alias.rl "$reflogCommon -10"
git config --global alias.rll "$reflogCommon"

git config --global alias.r "reset"
git config --global alias.rh "reset --hard"
git config --global alias.rs "reset --soft"
git config --global alias.rs1 "reset --soft HEAD~1"

git config --global alias.a "add --all"
git config --global alias.ap "add --patch"
git config --global alias.co "commit -m"
git config --global alias.coa "commit --amend"
git config --global alias.coe "commit --amend --no-edit"
git config --global alias.aco "!f() { git add --all && git commit -m \"\$1\"; }; f"
git config --global alias.acop "!f() { git add --all && git commit -m \"\$1\" && git push --follow-tags; }; f"

git config --global alias.p "push --follow-tags"
git config --global alias.pn "!f() { currentBranch=\$(git rev-parse --abbrev-ref HEAD); git push -u \${1:-origin} \$currentBranch; }; f"
git config --global alias.pf "push --force-with-lease"

git config --global alias.c "checkout"
git config --global alias.cb "checkout -b"
git config --global alias.cm "!f() { $setDefaultBranch; git checkout \$defaultBranch; }; f"

git config --global alias.b "branch"
git config --global alias.bd "branch -d"
git config --global alias.ba "branch -a"
git config --global alias.bnm "branch --no-merged"
git config --global alias.bv "branch -vv"
git config --global alias.bc "!f() { git remote prune origin; git branch -vv | grep 'origin/.*: gone]' | awk '{print \$1}' | xargs git branch -d; }; f"
git config --global alias.bcD "!f() { git remote prune origin; git branch -vv | grep 'origin/.*: gone]' | awk '{print \$1}' | xargs git branch -D; }; f"
# Show the commit hash of the first commit of the current or given branch --> "BranchFirstCommit"
git config --global alias.bfc "!f() { $setDefaultBranch; currentBranch=\$(git rev-parse --abbrev-ref HEAD); echo \$(git log \$defaultBranch..\${1:-\$currentBranch}  --oneline --pretty=format:'%h' | tail -1); }; f"
# List all changed files included in this branch compared to the default branch at the time the branch has been created
git config --global alias.bf "!f() { $setDefaultBranch; git diff --name-only \$(git merge-base \${1:-\$defaultBranch} HEAD); git ls-files --others --exclude-standard; }; f"
git config --global alias.bfp "!f() { $setDefaultBranch; git diff -p --word-diff \$(git merge-base \${1:-\$defaultBranch} HEAD); }; f"
git config --global alias.rbib "!f() { $setDefaultBranch; currentBranch=\$(git rev-parse --abbrev-ref HEAD); git rebase -i \$(git log \$defaultBranch..\${1:-\$currentBranch}  --oneline --pretty=format:'%h' | tail -1)^; }; f"

git config --global alias.f "fetch"
git config --global alias.fm "!f() { . ~/.dotfiles/toolbox/scripts/git-fetch-merge; }; f"
git config --global alias.fm-all "!f() { . ~/.dotfiles/toolbox/scripts/git-fetch-merge --all; }; f"

git config --global alias.m "merge"
git config --global alias.ma "merge --abort"
git config --global alias.mff "merge --ff-only"
git config --global alias.mr "merge --no-ff"
git config --global alias.mt "mergetool"

git config --global alias.rb "rebase"
git config --global alias.rbc "rebase --continue"
git config --global alias.rba "rebase --abort"
git config --global alias.rbm "!f() { $setDefaultBranch; git rebase \$defaultBranch; }; f"

git config --global alias.undo "!f() { git reset --hard \$1 && git clean -df \$1; }; f"

git config --global alias.dummy "commit --allow-empty -m 'dummy commit, contains no change'"

git config --global alias.sw "show --word-diff --format=\"%C(yellow)%h%C(reset) - %C(cyan)(%ar)%C(reset) %B%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%Creset\""
git config --global alias.swn "show --word-diff --name-status --format=\"%C(yellow)%h%C(reset) - %C(cyan)(%ar)%C(reset) %s%C(reset) %C(dim white)- %an%C(reset)%C(auto)%d%Creset\""

git config --global alias.st "stash -u"
git config --global alias.sts "stash --staged"
git config --global alias.stk "stash -u --keep-index"
git config --global alias.stp "stash pop"
git config --global alias.stl "$stashCommon"
git config --global alias.sta "stash apply"
git config --global alias.stsw "stash show --word-diff-regex=."

git config --global alias.t "tag"
git config --global alias.td "tag -d"
git config --global alias.tl "tag --list"
git config --global alias.tlr "!f() { git show-ref --tags | sed 's?.*refs/tags/??'; }; f"

git config --global alias.wta "worktree add"
git config --global alias.wtp "worktree prune"
git config --global alias.wtl "worktree list"

git config --global alias.cp "cherry-pick"
git config --global alias.cpn "cherry-pick -n"
# cpn all changes of branch $1
git config --global alias.cnb "!f() { $setDefaultBranch; git cherry-pick -n \$(git merge-base \$defaultBranch \$1)..\$1; }; f"

git config --global alias.rv "revert"
git config --global alias.rvn "revert -n"

git config --global alias.prn "!f() { . ~/.dotfiles/toolbox/scripts/git-github-pr new; }; f"
git config --global alias.pro "!f() { . ~/.dotfiles/toolbox/scripts/git-github-pr; }; f"


#search for regex in all files history
#git log -G regex [-- path/to/specific file]
#git log -p -G regex [-- path/to/specific file]
