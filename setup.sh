#!/bin/bash
# Configure computer environment

os=$(uname -s)
echo "OS: $os"

# Ensure git is present
if [ "$os" = "Linux" ]; then
    if ! command -V git >/dev/null 2>&1; then
        echo "Installing Git on Linux"
        sudo apt-get install -y git
    fi
elif [ "$os" = "Darwin" ]; then
    xcode-select -p >/dev/null 2>&1
    if [ $? != 0 ]; then
        echo "Installing XCode command-line tools ..."
        # xcode-select --install
        touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
        PROD=$(softwareupdate -l | grep "\*.*Command Line" | head -n 1 | awk -F"*" '{print $2}' | sed -e 's/^ *//' | tr -d '\n')
        softwareupdate -i "$PROD"
    fi
    if ! command -V git >/dev/null 2>&1; then
        if ! command -V brew >/dev/null 2>&1; then
            echo "Installing HomeBrew ..."
            /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
        fi
        echo "Installing Git on OSX"
        brew install -y git
    fi
elif [[ "$os" == CYGWIN* ]]; then
    if ! command -V git >/dev/null 2>&1; then
        if command -V pact >/dev/null 2>&1; then # Babun
            echo "Installing Git on Cygwin/Babun"
            pact install git
        else
            echo "Git not found. Please manually install Git and retry."
            return
        fi
    fi
else
    echo "Unsupported OS: $os"
    return
fi

# dotfiles location
export dotdir="$HOME/dotfiles"
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
    . "$dotdir/setup_debian.sh"
elif [ "$os" = "Darwin" ]; then
    echo "Starting OSX setup ..."
    . "$dotdir/setup_osx.sh"
elif [[ "$os" == CYGWIN* ]]; then
    if command -V pact >/dev/null 2>&1; then # Babun
        echo "Starting Cygwin/Babun setup ..."
        . "$dotdir/setup_babun.sh"
    else
        echo "Starting Cygwin setup ..."
        . "$dotdir/setup_cygwin.sh"
    fi
else
    echo "Unsupported OS: $os"
    return
fi
