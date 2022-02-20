#!/usr/bin/env bash
# Configure OSX environment

dotdir="$( cd "$( dirname "$0" )/.." && pwd )"
source "$dotdir/setup/setup_functions.sh"

dot_trace "Configuring OSX environment ..."

# Command-line tools (must be first since they install gcc)
xcode-select -p >/dev/null 2>&1
if [ $? != 0 ]; then
    echo "Installing XCode command-line tools ..."
    # xcode-select --install
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
    PROD=$(softwareupdate -l | grep "\*.*Command Line" | head -n 1 | awk -F"*" '{print $2}' | sed -e 's/^ *//' | tr -d '\n')
    softwareupdate -i "$PROD"
fi

make_dotfiles_symlinks "$dotdir/osx" "$HOME"

source "$dotdir/osx/brew.sh"
source "$dotdir/osx/software.sh"
source "$dotdir/osx/alfred.sh"
source "$dotdir/osx/dotnet.sh"
source "$dotdir/osx/osx_defaults"

"$dotdir/setup/setup.sh"

dot_trace "Configuring OSX environment done."
