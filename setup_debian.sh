#!/bin/bash
# Configuring Linux environment (Debian-style)

# Packages
sudo apt-get update
sudo apt-get install -y curl
sudo apt-get install -y git
sudo apt-get install -y git-extras
sudo apt-get install -y gitk
sudo apt-get install -y gitstats
sudo apt-get install -y ngrep
sudo apt-get install -y rlwrap
sudo apt-get install -y screen
sudo apt-get install -y vim
sudo apt-get install -y wget
sudo apt-get clean
sudo apt-get autoremove

cd $HOME

# dotfiles
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

ln -sf dotfiles/linux/.emacs.d .
ln -sf dotfiles/linux/.vim .
ln -sb dotfiles/linux/.aliases .
ln -sb dotfiles/linux/.bash_profile .
ln -sb dotfiles/linux/.bash_prompt .
ln -sb dotfiles/linux/.bashrc .
ln -sb dotfiles/linux/.curlrc .
ln -sb dotfiles/linux/.exports .
ln -sb dotfiles/linux/.functions .
ln -sb dotfiles/linux/.screenrc .
ln -sb dotfiles/linux/.vimrc .
ln -sb dotfiles/linux/.wgetrc .
wget https://raw.githubusercontent.com/git/git/master/contrib/completion/git-prompt.sh

# Git
[ -f ~/dotfiles/configure_git.sh ] && source ~/dotfiles/configure_git.sh

# SublimeText
read -p "Would you like to install and configure SublimeText ? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo add-apt-repository ppa:webupd8team/sublime-text-2
    sudo apt-get update
    sudo apt-get install -y sublime-text
    [ -f ~/dotfiles/linux/configure_sublimetext.sh ] && source ~/dotfiles/linux/configure_sublimetext.sh
fi

source ~/.bash_profile

echo "Done"
