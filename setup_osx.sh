#!/bin/bash
# Configure OSX environment

# dotdir="$( cd "$( dirname "$0" )" && pwd )"
[ -z "$dotdir" ] && dotdir="$HOME/dotfiles"

source "$dotdir/setupfunctions.sh"
pull_latest_dotfiles "$dotdir"

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

confirm_and_run "$dotdir/osx/brew.sh" "system packages"
confirm_and_run "$dotdir/osx/software.sh" "GUI packages"
confirm_and_run "$dotdir/osx/alfred.sh" "Alfred"
confirm_and_run "$dotdir/osx/dotnet.sh" "dotNet"
confirm_and_run "$dotdir/osx/osx_defaults" "sensible OSX defaults"
confirm_and_run "$dotdir/configure_brackets.sh" "Brackets"

source "$dotdir/setupcommon.sh"

dot_trace "Configuring OSX environment done."
