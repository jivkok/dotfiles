#!/bin/bash
# Packages

# Common
sudo apt-get update
sudo apt-get install -y cifs-utils
sudo apt-get install -y curl
sudo apt-get install -y dstat
sudo apt-get install -y exuberant-ctags
sudo apt-get install -y git
sudo apt-get install -y git-extras
sudo apt-get install -y gitk
sudo apt-get install -y gitstats
sudo apt-get install -y jq
sudo apt-get install -y libwww-perl
sudo apt-get install -y ngrep
sudo apt-get install -y python-pip
sudo apt-get install -y python-pygments
sudo apt-get install -y rlwrap
sudo apt-get install -y silversearcher-ag
sudo apt-get install -y tmux
sudo apt-get install -y tree
sudo apt-get install -y vim
sudo apt-get install -y wget

# Security-related
sudo apt-get install -y iftop

sudo apt-get clean
sudo apt-get autoremove
