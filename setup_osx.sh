#!/bin/bash
# Configure OSX environment

# $1 - file
# $2 - message
function ask_and_run ()
{
    if [ ! -f $1 ]; then return; fi
    read -p "$2" -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then return; fi

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
ln -sF dotfiles/.vim .
ln -sf dotfiles/.aliases .
ln -sf dotfiles/.bash_profile .
ln -sf dotfiles/.bash_prompt .
ln -sf dotfiles/.bashrc .
ln -sf dotfiles/.exports .
ln -sf dotfiles/.functions .
ln -sf dotfiles/.vimrc .
ln -sf dotfiles/.wgetrc .
ln -sf dotfiles/osx/.duti .
curl -o git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

# Packages
ask_and_run dotfiles/osx/brew.sh "Would you like to install Homebrew packages? "

# Software
ask_and_run dotfiles/osx/software.sh "Would you like to install additional software? "

# OSX tweaks
ask_and_run dotfiles/osx/.osx "Would you like to set sensible OSX defaults? "

# Configure Git
ask_and_run dotfiles/configure_git.sh "Would you like to configure Git? "

# ZSH
read -p "Would you like to install and configure ZSH ? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo apt-get install zsh
    curl -L http://install.ohmyz.sh | sh
    ln -sf dotfiles/.zprofile .
    ln -sf dotfiles/.zshrc .
    ln -sf dotfiles/.zsh-theme .
fi

# Configure SublimeText
ask_and_run dotfiles/configure_sublimetext.sh "Would you like to configure SublimeText? "

# Configure Alfred workflows
ask_and_run dotfiles/osx/alfred.sh "Would you like to configure Alfred workflows? "
