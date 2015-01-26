#!/bin/bash
# Configuring Linux environment (Debian-style)

# Packages
sudo apt-get update
sudo apt-get install -y curl
sudo apt-get install -y dstat
sudo apt-get install -y git
sudo apt-get install -y git-extras
sudo apt-get install -y gitk
sudo apt-get install -y gitstats
sudo apt-get install -y ngrep
sudo apt-get install -y python-pygments
sudo apt-get install -y rlwrap
sudo apt-get install -y tmux
sudo apt-get install -y tree
sudo apt-get install -y vim
sudo apt-get install -y wget
sudo apt-get clean
sudo apt-get autoremove

cd $HOME

# dotfiles
if [ -d dotfiles/.git ]; then
    cd dotfiles
    git pull origin master
    git submodule update --remote
    cd ..
else
    if [ -d dotfiles ]; then
        mv dotfiles dotfiles.old
    fi
    git clone --recursive https://github.com/jivkok/dotfiles.git dotfiles
fi

ln -sf dotfiles/.emacs.d .
ln -sf dotfiles/.vim .
ln -sb dotfiles/.aliases .
ln -sb dotfiles/.bash_profile .
ln -sb dotfiles/.bash_prompt .
ln -sb dotfiles/.bashrc .
ln -sb dotfiles/.curlrc .
ln -sb dotfiles/.exports .
ln -sb dotfiles/.functions .
ln -sb dotfiles/.tmux.conf .
ln -sb dotfiles/.vimrc .
ln -sb dotfiles/.wgetrc .
curl -o git-prompt.sh https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

# Git
[ -f ~/dotfiles/configure_git.sh ] && source ~/dotfiles/configure_git.sh

# ZSH
read -p "Would you like to install and configure ZSH ? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    source ~/dotfiles/configure_git.sh
fi

# SublimeText
read -p "Would you like to install and configure SublimeText ? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo add-apt-repository ppa:webupd8team/sublime-text-2
    sudo apt-get update
    sudo apt-get install -y sublime-text
    [ -f ~/dotfiles/configure_sublimetext.sh ] && source ~/dotfiles/configure_sublimetext.sh
fi

echo "Done"
