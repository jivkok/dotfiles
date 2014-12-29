#!/bin/bash
# Configuring OSX environment

# private helper
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

# Install homebrew
if [ ! -f /usr/local/bin/brew ]; then
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

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

# Ask for the administrator password upfront.
sudo -v
# Keep-alive: update existing `sudo` time stamp until the script has finished.
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

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

# Packages
ask_and_run dotfiles/osx/brew.sh "Would you like to install Homebrew packages? "

# Software
ask_and_run dotfiles/osx/software.sh "Would you like to install additional software? "

# OSX tweaks
ask_and_run dotfiles/osx/.osx "Would you like to set sensible OSX defaults? "

# Git
ask_and_run dotfiles/configure_git.sh "Would you like to configure Git? "

# SublimeText
ask_and_run dotfiles/osx/configure_sublimetext.sh "Would you like to configure SublimeText? "
