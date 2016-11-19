#!/bin/bash
# Configure computer environment

os=$(uname -s)
echo "OS: $os"

# Ensure git is present
if ! command -v git >/dev/null 2>&1; then
    if [ "$os" = "Linux" ]; then
        echo "Installing Git on Linux"
        sudo apt-get install -y git
    elif [ "$os" = "Darwin" ]; then
        if ! command -v brew >/dev/null 2>&1; then
            echo "Installing HomeBrew ..."
            /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        fi
        echo "Installing Git on OSX"
        brew install -y git
    elif [[ "$os" == CYGWIN* ]]; then
        if command -v pact >/dev/null 2>&1; then # Babun
            echo "Installing Git on Cygwin/Babun"
            pact install git
        else
            echo "Git not found. Please manually install Git and retry."
            return
        fi
    else
        echo "Unsupported OS: $os"
        return
    fi
fi

# dotfiles location
dotdir="$HOME/dotfiles"
if [ -n "$1" ]; then
    if  [[ $1 == /* ]] ; then
        dotdir="$1"
    else
        dotdir="$PWD/$1"
    fi
fi
echo "Dotfiles location: $dotdir"

if [ -d "$dotdir/.git" ] && [ -f "$dotdir/setup.sh" ]; then
    echo "Pulling the latest dotfiles ..."
    git -C "$dotdir" pull --prune --recurse-submodules
    git -C "$dotdir" submodule update --init --recursive
else
    if [ -d "$dotdir" ]; then
        echo "Backing up existing directory   $dotdir   to   ${dotdir}.backup ..."
        mv "$dotdir" "${dotdir}.backup"
    fi
    echo "Cloning dotfiles ..."
    git clone --recursive https://github.com/jivkok/dotfiles.git "$dotdir"
fi

# Run appropriate OS setup
if [ "$os" = "Linux" ]; then
    echo "Starting Linux setup ..."
    source "$dotdir/setup_debian"
elif [ "$os" = "Darwin" ]; then
    echo "Starting OSX setup ..."
    source "$dotdir/setup_osx"
elif [[ "$os" == CYGWIN* ]]; then
    if command -v pact >/dev/null 2>&1; then # Babun
        echo "Starting Cygwin/Babun setup ..."
        source "$dotdir/setup_babun"
    else
        echo "Starting Cygwin setup ..."
        source "$dotdir/setup_cygwin"
    fi
else
    echo "Unsupported OS: $os"
    return
fi
