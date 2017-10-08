#!/bin/bash
# Configuring NodeJS (and NPM packages)
# Note: this installs `npm` too.

os=$(uname -s)
if [ "$os" = "Linux" ] ; then
    sudo apt-get remove --purge node # unrelated package

    # https://github.com/nodesource/distributions
    curl -sL https://deb.nodesource.com/setup_8.x | sudo bash -

    sudo apt-get install -y nodejs # this package includes npm too
    sudo apt-get install -y build-essential
elif [ "$os" = "Darwin" ] ; then
    ! brew ls --versions node >/dev/null 2>&1 && brew install node
    brew link --overwrite node
else
    echo "Unsupported OS: $os"
    return
fi

# Packages
npm install -g bower
npm install -g coffee-script
npm install -g eslint
npm install -g express
npm install -g express-generator
npm install -g generator-angular
npm install -g generator-webapp
npm install -g grunt-cli
npm install -g gulp
npm install -g http-server
npm install -g jshint
npm install -g less
npm install -g n
npm install -g nodemon
npm install -g typescript
npm install -g yo

npm cache verify
