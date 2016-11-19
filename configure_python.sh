#!/bin/bash
# Configuring Python

os=$(uname -s)
if [ "$os" = "Linux" ]; then
    sudo apt-get install python
    sudo apt-get install python3
    sudo pip install --upgrade pip setuptools

    # Packages
    sudo pip install --upgrade glances # system stats
    sudo pip install --upgrade httpie # curl-like with colorized output
    sudo pip install --upgrade jsbeautifier # reformat and reindent JavaScript code. jsbeautifier.org. Use with 'js-beautify somefile.js'
    sudo pip install --upgrade mitmproxy # http traffic interception
    sudo pip install --upgrade Pygments # syntax highlighter
elif [ "$os" = "Darwin" ]; then
    ! brew ls --versions python >/dev/null 2>&1 && brew install python
    ! brew ls --versions python3 >/dev/null 2>&1 && brew install python3
    pip install --upgrade pip setuptools

    # Install virtual environments globally
    # It fails to install virtualenv if PIP_REQUIRE_VIRTUALENV was true
    export PIP_REQUIRE_VIRTUALENV=false
    pip install virtualenv
    pip install virtualenvwrapper

    # Packages
    pip install --upgrade glances # system stats
    pip install --upgrade httpie # curl-like with colorized output
    pip install --upgrade jsbeautifier # reformat and reindent JavaScript code. jsbeautifier.org. Use with 'js-beautify somefile.js'
    pip install --upgrade mitmproxy # http traffic interception
    pip install --upgrade Pygments # syntax highlighter (colorize)
else
    echo "Unsupported OS: $os"
    return
fi
