#!/bin/bash
# Configuring Python

os=$(uname -s)
if [ "$os" = "Linux" ]; then
    sudo apt-get install python
    sudo pip install --upgrade pip setuptools
    # Packages
    sudo pip install --upgrade httpie
    sudo pip install --upgrade Pygments
elif [ "$os" = "Darwin" ]; then
    brew install python
    pip install --upgrade pip setuptools
    # Packages
    pip install --upgrade httpie
    pip install --upgrade Pygments
else
    echo "Unsupported OS: $os"
    return
fi
