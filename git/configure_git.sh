#!/usr/bin/env bash
# Configuring Git settings. Inspired by
# https://git.wiki.kernel.org/index.php/Aliases
# https://gist.github.com/bradwilson/4215933
# https://gist.github.com/oli/1637874

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

dot_trace "Configuring git ..."

# Core

var="$(git config --global --get user.name)"
if [ -z "$var" ]; then
  var=JK
  git config --global user.name "$var"
fi
dot_trace "Git user name: $var"

var="$(git config --global --get user.email)"
if [ -z "$var" ]; then
  var="jivkokgit@gmail.com"
  git config --global user.email "$var"
fi
dot_trace "Git user email: $var"

git config --global core.autocrlf input
git config --global core.fscache true
git config --global core.preloadindex true
git config --global core.safecrlf true
git config --global help.format html
git config --global pack.packSizeLimit 2g
git config --global push.default current
git config --global rebase.autosquash true

# Colors
git config --global color.branch.current "red bold"
git config --global color.branch.local normal
git config --global color.branch.plain normal
git config --global color.branch.remote "yellow bold"
git config --global color.diff.meta "yellow"
git config --global color.diff.frag "magenta bold"
git config --global color.diff.func "146 bold"
git config --global color.diff.commit "yellow bold"
git config --global color.diff.old "red bold"
git config --global color.diff.new "green bold"
git config --global color.diff.whitespace "red reverse"
git config --global color.diff-highlight.oldNormal "red bold"
git config --global color.diff-highlight.oldHighlight "red bold 52"
git config --global color.diff-highlight.newNormal "green bold"
git config --global color.diff-highlight.newHighlight "green bold 22"
git config --global color.status.header normal
git config --global color.status.new "red bold"
git config --global color.status.added "green bold"
git config --global color.status.updated "cyan bold"
git config --global color.status.changed "cyan bold"
git config --global color.status.untracked "red bold"
git config --global color.status.nobranch "red bold"
git config --global color.ui true

# Aliases
git config --global alias.a 'add -A'
git config --global alias.aliases 'config --get-regexp alias'
git config --global alias.amend 'commit --amend -C HEAD'
git config --global alias.bl 'blame -w -M -C'
git config --global alias.br 'branch'
git config --global alias.bra 'branch -rav'
git config --global alias.branches 'branch -rav'
git config --global alias.cat 'cat-file -t'
git config --global alias.cl 'clean -x -d -f'
git config --global alias.cm 'commit -m'
git config --global alias.co 'checkout'
git config --global alias.df 'diff --word-diff=color --word-diff-regex=. -w --patience'
git config --global alias.dft 'difftool'
git config --global alias.dump 'cat-file -p'
git config --global alias.files '! git ls-files | grep -i'
git config --global alias.filelog 'log -u'
git config --global alias.fza "! git ls-files -m -o --exclude-standard | fzf -m --print0 | xargs -0 git add"
git config --global alias.hist "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue) [%an]%Creset' --abbrev-commit --date=relative"
git config --global alias.l 'log --pretty=format:\"%h %ad | %s%d [%an]\" --date=short'
git config --global alias.last 'log -p --max-count=1 --word-diff'
git config --global alias.lastref 'rev-parse --short HEAD'
git config --global alias.lasttag 'describe --tags --abbrev=0'
git config --global alias.lg 'log --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short'
git config --global alias.loglist 'log --oneline'
git config --global alias.pick 'add -p'
git config --global alias.pp 'pull --prune'
git config --global alias.pullom 'pull origin master'
git config --global alias.pushom 'push origin master'
git config --global alias.re 'rebase'
git config --global alias.reabort 'rebase --abort'
git config --global alias.rego 'rebase --continue'
git config --global alias.reskip 'rebase --skip'
git config --global alias.remotes 'remote -v show'
git config --global alias.st 'status -sb'
git config --global alias.stats 'diff --stat'
git config --global alias.uncommit 'reset --soft HEAD~'
git config --global alias.unstage 'reset HEAD --'
git config --global alias.vimdiff 'difftool --tool=vimdiff --no-prompt'
git config --global alias.wdiff 'diff --word-diff'
git config --global alias.who 'shortlog -s -e --'
git config --global alias.zap 'reset --hard HEAD'

if command -V delta >/dev/null 2>&1; then
  dot_trace "Setting delta as pager"

  git config --global core.pager "delta"
  git config --global interactive.diffFilter "delta --color-only"
  git config --bool --global delta.navigate true
  git config --bool --global delta.light false
  git config --global merge.conflictstyle "diff3"
  git config --global diff.colorMoved "default"
elif command -V diff-so-fancy >/dev/null 2>&1; then
  dot_trace "Setting diff-so-fancy as pager"

  git config --global core.pager "diff-so-fancy | less --tabs=4 -RFX"
  git config --global interactive.diffFilter "diff-so-fancy --patch"
  git config --bool --global diff-so-fancy.markEmptyLines false
fi

if command -V difft >/dev/null 2>&1; then
  dot_trace "Setting difftastic as diff tool"

  git config --bool --global pager.difftool true
  git config --bool --global difftool.prompt false
  git config --global diff.tool difftastic
  git config --global difftool.difftastic.cmd "difft \$LOCAL \$REMOTE"
fi

os=$(uname -s)
if [ "$os" = "Darwin" ]; then
  git config --global alias.opendiff 'difftool --tool=opendiff --no-prompt'

  if [ -f "/Applications/p4merge.app/Contents/Resources/launchp4merge" ]; then
    dot_trace "Setting P4Merge as diff&merge tool"

    git config --global mergetool.keepBackup false
    git config --global mergetool.keepTemporaries false
    git config --global mergetool.prompt false

    git config --global merge.tool p4mergetool
    git config --global mergetool.p4mergetool.cmd "/Applications/p4merge.app/Contents/Resources/launchp4merge \$PWD/\$BASE \$PWD/\$REMOTE \$PWD/\$LOCAL \$PWD/\$MERGED"
    git config --global mergetool.p4mergetool.trustExitCode false

    git config --global difftool.prompt false

    git config --global diff.tool p4mergetool
    git config --global difftool.p4mergetool.cmd "/Applications/p4merge.app/Contents/Resources/launchp4merge \$LOCAL \$REMOTE"
  elif [ -f "/Applications/kdiff3.app/Contents/MacOS/kdiff3" ]; then
    dot_trace "Setting KDiff3 as diff&merge tool"

    git config --global mergetool.keepBackup false
    git config --global mergetool.keepTemporaries false
    git config --global mergetool.prompt false

    git config --global merge.tool kdiff3
    git config --global mergetool.kdiff3.path "/Applications/kdiff3.app/Contents/MacOS/kdiff3"
    git config --global mergetool.kdiff3.trustExitCode false

    git config --global difftool.prompt false

    git config --global diff.tool kdiff3
    git config --global difftool.kdiff3.path "/Applications/kdiff3.app/Contents/MacOS/kdiff3"
  fi
fi

dot_trace "Configuring git done."
