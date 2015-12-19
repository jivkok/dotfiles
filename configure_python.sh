#!/bin/bash
# Configuring Python

os=$(uname -s)
if [ "$os" = "Linux" ]; then
    sudo apt-get install python
    sudo pip install --upgrade pip setuptools
    # Packages
    sudo pip install --upgrade httpie # curl-like with colorized output
    sudo pip install --upgrade Pygments # syntax highlighter
elif [ "$os" = "Darwin" ]; then
    brew install python
    pip install --upgrade pip setuptools
    # Packages
    pip install --upgrade httpie # curl-like with colorized output
    pip install --upgrade mitmproxy # http traffic interception
    pip install --upgrade Pygments # syntax highlighter
else
    echo "Unsupported OS: $os"
    return
fi
