#!/bin/bash
# Configuring Ruby

os=$(uname -s)
if [ "$os" = "Linux" ]; then
    # Using RVM: https://gorails.com/setup/ubuntu/14.04
    # sudo apt-get install libgdbm-dev libncurses5-dev automake libtool bison libffi-dev
    # gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    # curl -sSL https://get.rvm.io | bash -s stable
    # source ~/.rvm/scripts/rvm
    # rvm install 2.3.1
    # rvm use 2.3.1 --default
    # ruby -v
    sudo apt-get install -y rubygems-integration
elif [ "$os" = "Darwin" ]; then
    ! brew ls --versions ruby-build >/dev/null 2>&1 && brew install ruby-build
    ! brew ls --versions rbenv >/dev/null 2>&1 && brew install rbenv

    # Packages
    gem install --user-install cocoapods
else
    echo "Unsupported OS: $os"
    return
fi

# Packages
gem install --user-install compass
gem install --user-install tmuxinator

sudo gem update --system
gem update -y
