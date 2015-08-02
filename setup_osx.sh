#!/bin/bash
# Configure OSX environment

# $1 - file
# $2 - message
function ask_and_run ()
{
    if [ ! -f $1 ]; then return; fi
    shh=$(ps -p $$ -oargs=)
    if [ "-zsh" = $shh ]; then
        read "REPLY?$2 "
    else
        read -p "$2 " -n 1 -r
    fi
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then return; fi

    source $1

    return
}

cd $HOME

# repo
if [ -d dotfiles/.git ]; then
    cd dotfiles
    git pull --prune --recurse-submodules
    git submodule init
    git submodule update --remote --recursive
    cd ..
else
    if [ -d dotfiles ]; then
        mv dotfiles dotfiles.old
    fi
    git clone --recursive https://github.com/jivkok/dotfiles.git dotfiles
fi

# dotfiles
ln -sF dotfiles/.vim .
ln -sf dotfiles/.aliases .
ln -sf dotfiles/.bash_profile .
ln -sf dotfiles/.bash_prompt .
ln -sf dotfiles/.bashrc .
ln -sf dotfiles/.exports .
ln -sf dotfiles/.functions .
ln -sf dotfiles/.tmux.conf .
ln -sf dotfiles/.vim/.vimrc .
ln -sf dotfiles/.wgetrc .
ln -sf dotfiles/osx/.duti .
curl -o git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

# Command-line tools
xcode-select -p
if [ $? != 0 ]; then
    read -p "Would you like to install the XCode command-line tools?" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        xcode-select --install
    fi
fi

# Packages
ask_and_run dotfiles/osx/brew.sh "Would you like to install Homebrew packages?"

# Software
ask_and_run dotfiles/osx/software.sh "Would you like to install additional software?"

# OSX tweaks
ask_and_run dotfiles/osx/.osx "Would you like to set sensible OSX defaults?"

# Python
ask_and_run dotfiles/configure_python.sh "Would you like to configure Python and install Python packages?"

# Ruby
ask_and_run dotfiles/configure_ruby.sh "Would you like to configure Ruby and install Ruby packages?"

# Configure Git
ask_and_run dotfiles/configure_git.sh "Would you like to configure Git?"

# ZSH
ask_and_run dotfiles/configure_zsh.sh "Would you like to configure Zsh?"

# Vim
ask_and_run dotfiles/configure_vim.sh "Would you like to configure Vim?"

# SublimeText
ask_and_run dotfiles/configure_sublimetext.sh "Would you like to configure SublimeText?"

# Alfred workflows
ask_and_run dotfiles/osx/alfred.sh "Would you like to configure Alfred workflows?"

# DotNet
ask_and_run dotfiles/osx/dotnet.sh "Would you like to configure DotNet?"

echo "Done"
