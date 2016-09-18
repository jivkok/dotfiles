#!/bin/bash
# Packages

sudo add-apt-repository ppa:aacebedo/fasd
sudo apt-get update

# Common
sudo apt-get install -y cifs-utils
sudo apt-get install -y collectl
sudo apt-get install -y curl
sudo apt-get install -y dstat
sudo apt-get install -y exuberant-ctags
sudo apt-get install -y fasd
sudo apt-get install -y git
sudo apt-get install -y git-extras
sudo apt-get install -y gitk
sudo apt-get install -y gitstats
sudo apt-get install -y graphviz
sudo apt-get install -y jq
sudo apt-get install -y libwww-perl
sudo apt-get install -y lnav
sudo apt-get install -y ngrep
sudo apt-get install -y mosh
sudo apt-get install -y python-pip
sudo apt-get install -y python-pygments # colorize
sudo apt-get install -y rlwrap
sudo apt-get install -y silversearcher-ag
sudo apt-get install -y shellcheck
sudo apt-get install -y tmux
sudo apt-get install -y tree
sudo apt-get install -y vim
sudo apt-get install -y wget

apt-get install libxml2-dev
apt-get install libxslt1-dev
apt-get install python-dev

git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --key-bindings --completion --no-update-rc

# Security-related
sudo apt-get install -y htop
sudo apt-get install -y iftop
sudo apt-get install -y lsof
sudo apt-get install -y ltrace
sudo apt-get install -y nethogs
sudo apt-get install -y secure-delete
sudo apt-get install -y strace

# TaskWarrior
sudo apt-get install -y task
sudo apt-get install -y vit

sudo apt-get clean
sudo apt-get autoremove
