#!/bin/bash
# Configuring Ruby

os=$(uname -s)
if [ "$os" = "Linux" ]; then
    # ## Using RVM:
    # gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
    # curl -L https://get.rvm.io | bash -s stable
    # source ~/.rvm/scripts/rvm
    # rvm requirements
    # touch $HOME/profile_extra
    # echo export PATH="\$PATH:\$HOME/.rvm/bin">>$HOME/.profile_extra
    # echo [[ -s "\$HOME/.rvm/scripts/rvm" ]] && source "\$HOME/.rvm/scripts/rvm">>$HOME/.profile_extra
    sudo apt-get install rubygems-integration
elif [ "$os" = "Darwin" ]; then
    # installed by default
    # Packages
    sudo gem install cocoapods
else
    echo "Unsupported OS: $os"
    return
fi

sudo gem install compass
sudo gem install tmuxinator

sudo gem update --system
