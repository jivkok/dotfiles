#!/usr/bin/env bash
# Configuring NodeJS (and NPM packages)

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
npm install -g bower # The browser package manager
npm install -g coffee-script # Unfancy JavaScript
npm install -g diff2html-cli # Fast Diff to colorized HTML
npm install -g eslint # An AST-based pattern checker for JavaScript
npm install -g express # Fast, unopinionated, minimalist web framework
npm install -g express-generator # Express application generator
npm install -g generator-angular # Yeoman generator for AngularJS
npm install -g generator-webapp # Scaffold out a front-end web app
npm install -g grunt-cli # The grunt command line interface
npm install -g gulp # The streaming build system
npm install -g http-server # A simple zero-configuration command-line http server
npm install -g jshint # Static analysis tool for JavaScript
npm install -g less # Leaner CSS
npm install -g n # Interactively Manage All Your Node Versions
npm install -g nodemon # Simple monitor script for use during development of a node.js app
npm install -g typescript # TypeScript is a language for application scale JavaScript development
npm install -g yo # CLI tool for running Yeoman generators

npm cache verify
