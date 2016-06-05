#!/bin/bash
# Configuring databases

os=$(uname -s)
if [ "$os" = "Linux" ]; then
    sudo apt-get update

    # Elastic Search
    sudo apt-get install openjdk-7-jre
    wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
    echo "deb https://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch-2.x.list
    sudo apt-get update
    sudo apt-get install -y elasticsearch

    sudo apt-get install -y mysql-server
    sudo apt-get install -y mongodb
    sudo apt-get install -y postgresql postgresql-contrib
    sudo apt-get install -y redis-server redis-tools

    sudo apt-get clean && sudo apt-get autoremove
elif [ "$os" = "Darwin" ]; then
    brew update

    brew install elasticsearch
    brew install mysql
    brew install mongo
    brew install postgresql
    brew install redis

    brew cask install --appdir="/Applications" mysqlworkbench

    brew cleanup
else
    echo "Unsupported OS: $os"
    return
fi
