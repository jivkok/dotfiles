#!/bin/bash
# Configure OSX environment

# $1 - file
# $2 - message
function ask_and_run ()
{
    if [ ! -f $1 ]; then return; fi
    read -p "$2" -n 1 -r
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then return; fi
    echo

    source $1

    tput bel

    return
}

cd $HOME

# repo
if [ -d dotfiles/.git ]; then
    cd dotfiles
    git pull origin master
    cd ..
else
    if [ -d dotfiles ]; then
        mv dotfiles dotfiles.old
    fi
    git clone https://github.com/jivkok/dotfiles.git dotfiles
fi

# dotfiles
ln -sF dotfiles/osx/.vim .
ln -sf dotfiles/osx/.aliases .
ln -sf dotfiles/osx/.bash_profile .
ln -sf dotfiles/osx/.bash_prompt .
ln -sf dotfiles/osx/.bashrc .
ln -sf dotfiles/osx/.duti .
ln -sf dotfiles/osx/.exports .
ln -sf dotfiles/osx/.functions .
ln -sf dotfiles/osx/.screenrc .
ln -sf dotfiles/osx/.vimrc .
ln -sf dotfiles/osx/.wgetrc .
curl -o git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

# Packages
ask_and_run dotfiles/osx/brew.sh "Would you like to install Homebrew packages? "

# Software
ask_and_run dotfiles/osx/software.sh "Would you like to install additional software? "

# OSX tweaks
ask_and_run dotfiles/osx/.osx "Would you like to set sensible OSX defaults? "

# Configure Git
ask_and_run dotfiles/configure_git.sh "Would you like to configure Git? "

# Configure SublimeText
ask_and_run dotfiles/osx/configure_sublimetext.sh "Would you like to configure SublimeText? "
