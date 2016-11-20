#!/bin/bash
# Configure OSX environment

dotdir="$( cd "$( dirname "$0" )" && pwd )"
source "$dotdir/setupfunctions.sh"
pull_latest_dotfiles "$dotdir"

dot_trace "Configuring OSX environment ..."

# Command-line tools (must be first since they install gcc)
xcode-select -p
if [ $? != 0 ]; then
    dot_trace "Installing XCode command-line tools ..."
    xcode-select --install
fi

make_dotfiles_symlinks "$dotdir/osx" "$HOME"

confirm_and_run "$dotdir/osx/brew.sh" "system packages"
confirm_and_run "$dotdir/osx/software.sh" "GUI packages"
confirm_and_run "$dotdir/osx/alfred.sh" "Alfred"
confirm_and_run "$dotdir/osx/dotnet.sh" "dotNet"
confirm_and_run "$dotdir/osx/osx_defaults" "sensible OSX defaults"
confirm_and_run "$dotdir/configure_brackets.sh" "Brackets"

# Karabiner
[ -f "$HOME/Library/Application Support/Karabiner/private.xml" ] && cp -f "$HOME/Library/Application Support/Karabiner/private.xml" "$HOME/Library/Application Support/Karabiner/private.xml.backup"
mkdir -p "$HOME/Library/Application Support/Karabiner/"
cp -f "$dotdir/osx/karabiner.private.xml" "$HOME/Library/Application Support/Karabiner/private.xml"

source "$dotdir/setupcommon.sh"

echo "Configuring OSX environment done."
