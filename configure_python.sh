#!/bin/bash
# Configuring Python

os=$(uname -s)
if [ "$os" = "Linux" ]; then
    sudo apt-get install -y python3
    sudo apt-get install -y python3-pip
    sudo -H pip3 install --upgrade pip setuptools
elif [ "$os" = "Darwin" ]; then
    ! brew ls --versions python3 >/dev/null 2>&1 && brew install python3
    pip3 install --upgrade pip setuptools
else
    echo "Unsupported OS: $os"
    return
fi

# Install virtual environments globally
# It fails to install virtualenv if PIP_REQUIRE_VIRTUALENV was true
export PIP_REQUIRE_VIRTUALENV=false
pip install --user --upgrade virtualenv
pip install --user --upgrade virtualenvwrapper

# Packages
pip install --user --upgrade glances # system stats
pip install --user --upgrade httpie # curl-like with colorized output
pip install --user --upgrade jsbeautifier # reformat and reindent JavaScript code. jsbeautifier.org. Use with 'js-beautify somefile.js'
pip install --user --upgrade mitmproxy # http traffic interception
pip install --user --upgrade Pygments # syntax highlighter
pip install --user --upgrade pylint # Python linter
pip install --user --upgrade jupyter # Jupyter Notebooks
pip install --user --upgrade cdiff # color diff
pip install --user --upgrade icdiff # improved color diff
