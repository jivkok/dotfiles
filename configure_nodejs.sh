#!/bin/bash
# Configuring NodeJS (and NPM packages)
# Note: this installs `npm` too.

os=$(uname -s)
if [ "$os" = "Linux" ]; then
    sudo apt-get remove --purge node # unrelated package

    curl -sL https://deb.nodesource.com/setup | sudo bash -

    sudo apt-get install -y nodejs
    # sudo apt-get install -y npm # NodeJS is installed from custom PPE which carries npm too
    sudo apt-get install -y build-essential

    sudo ln -sf /usr/bin/nodejs /usr/bin/node
    sudo npm install -g npm@latest

    # Packages
    sudo npm install -g grunt-cli
    sudo npm install -g http-server
    sudo npm install -g express
    sudo npm install -g express-generator
    sudo npm install -g yo
    sudo npm install -g generator-angular
    sudo npm install -g bower
    sudo npm install -g nodemon
    sudo npm install -g typescript

    sudo npm cache clean
elif [ "$os" = "Darwin" ]; then
    brew install node

    # Packages
    npm install -g grunt-cli
    npm install -g http-server
    npm install -g express
    npm install -g express-generator
    npm install -g yo
    npm install -g generator-angular
    npm install -g bower
    npm install -g nodemon
    npm install -g typescript

    npm cache clean
else
    echo "Unsupported OS: $os"
    return
fi
