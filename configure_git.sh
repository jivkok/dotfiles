#!/bin/bash
# Configuring Git settings. Inspired by
# https://git.wiki.kernel.org/index.php/Aliases
# https://gist.github.com/bradwilson/4215933
# https://gist.github.com/oli/1637874

# Core

var="$(git config --global --get user.name)"
if [ -z "$var" ]; then
    read -p 'What name would you like to use for Git commits? ' -d $'\n' var

    if [ -z "$var" ]; then
        echo 'Skipping setting Git user.name'
    else
        git config --global user.name "$var"
    fi
else
    echo "Git user name: $var"
fi

var="$(git config --global --get user.email)"
if [ -z "$var" ]; then
    read -p 'What email would you like to use for Git commits? ' -d $'\n' var

    if [ -z "$var" ]; then
        echo 'Skipping setting Git user.email'
    else
        git config --global user.email "$var"
    fi
else
    echo "Git user email: $var"
fi

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
git config --global color.branch.remote "yellow bold"
git config --global color.branch.plain normal
git config --global color.diff.meta "yellow bold"
git config --global color.diff.frag "magenta bold"
git config --global color.diff.old "red bold"
git config --global color.diff.new "green bold"
git config --global color.status.header normal
git config --global color.status.new "red bold"
git config --global color.status.added "green bold"
git config --global color.status.updated "cyan bold"
git config --global color.status.changed "cyan bold"
git config --global color.status.untracked "red bold"
git config --global color.status.nobranch "red bold"

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
git config --global alias.dump 'cat-file -p'
git config --global alias.files '! git ls-files | grep -i'
git config --global alias.filelog 'log -u'
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
git config --global alias.undo 'reset HEAD~'
git config --global alias.unstage 'reset HEAD'
git config --global alias.vimdiff 'difftool --tool=vimdiff --no-prompt'
git config --global alias.wdiff 'diff --word-diff'
git config --global alias.who 'shortlog -s -e --'
git config --global alias.zap 'reset --hard HEAD'

os=$(uname -s)
if [ "$os" = "Darwin" ]; then
    # OSX default FileMerge
    git config --global alias.opendiff 'difftool --tool=opendiff --no-prompt'

    # P4Merge installed with homebrew
    if [ -f $HOME/Applications/p4merge.app/Contents/Resources/launchp4merge ]; then
        echo Setting P4Merge as diff and merge tool

        git config --global mergetool.keepBackup false
        git config --global mergetool.keepTemporaries false
        git config --global mergetool.prompt false

        git config --global merge.tool p4mergetool
        git config --global mergetool.p4mergetool.cmd "$HOME/Applications/p4merge.app/Contents/Resources/launchp4merge \$PWD/\$BASE \$PWD/\$REMOTE \$PWD/\$LOCAL \$PWD/\$MERGED"
        git config --global mergetool.p4mergetool.trustExitCode false

        git config --global difftool.prompt false

        git config --global diff.tool p4mergetool
        git config --global difftool.p4mergetool.cmd "$HOME/Applications/p4merge.app/Contents/Resources/launchp4merge \$LOCAL \$REMOTE"
    fi
fi
