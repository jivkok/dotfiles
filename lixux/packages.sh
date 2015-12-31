#!/bin/bash
# Packages

# Common
sudo apt-get update
sudo apt-get install -y cifs-utils
sudo apt-get install -y collectl
sudo apt-get install -y curl
sudo apt-get install -y dstat
sudo apt-get install -y exuberant-ctags
sudo apt-get install -y git
sudo apt-get install -y git-extras
sudo apt-get install -y gitk
sudo apt-get install -y gitstats
sudo apt-get install -y jq
sudo apt-get install -y libwww-perl
sudo apt-get install -y lnav
sudo apt-get install -y ngrep
sudo apt-get install -y python-pip
sudo apt-get install -y python-pygments # colorize
sudo apt-get install -y rlwrap
sudo apt-get install -y silversearcher-ag
sudo apt-get install -y shellcheck
sudo apt-get install -y tmux
sudo apt-get install -y tree
sudo apt-get install -y vim
sudo apt-get install -y wget

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

sudo apt-get clean
sudo apt-get autoremove
