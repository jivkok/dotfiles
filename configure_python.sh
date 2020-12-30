#!/bin/bash
# Configuring Python

os=$(uname -s)
if [ "$os" = "Linux" ]; then
    sudo add-apt-repository universe
    sudo apt-get update
    sudo apt-get install -y python3
    sudo apt-get install -y python3-pip
    sudo -H pip3 install --upgrade pip setuptools
elif [ "$os" = "Darwin" ]; then
    ! brew ls --versions python3 >/dev/null 2>&1 && brew install python3 && brew postinstall python3 && brew link python3
    python3 -m pip install --upgrade pip setuptools
else
    echo "Unsupported OS: $os"
    return
fi

# Install virtual environments globally
# It fails to install virtualenv if PIP_REQUIRE_VIRTUALENV was true
export PIP_REQUIRE_VIRTUALENV=false
python3 -m pip install --user --upgrade virtualenv
python3 -m pip install --user --upgrade virtualenvwrapper

# Packages
python3 -m pip install --user --upgrade cdiff # color diff. Use it within a Git repo.
python3 -m pip install --user --upgrade glances # system stats
python3 -m pip install --user --upgrade httpie # curl-like with colorized output
python3 -m pip install --user --upgrade icdiff # improved color diff. Use it diffing two files.
python3 -m pip install --user --upgrade jsbeautifier # reformat and reindent JavaScript code. jsbeautifier.org. Use with 'js-beautify somefile.js'
python3 -m pip install --user --upgrade jupyter # Jupyter Notebooks
python3 -m pip install --user --upgrade mitmproxy # http traffic interception
python3 -m pip install --user --upgrade pygments # syntax highlighter
python3 -m pip install --user --upgrade pylint # Python linter
