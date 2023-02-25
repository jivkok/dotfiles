#!/usr/bin/env bash
# Configure OSX-specific software

dotdir="$( cd "$( dirname "$0" )/.." && pwd )"
source "$dotdir/setup/setup_functions.sh"

dot_trace "Configuring OSX-specific software ..."

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

source "$dotdir/osx/homebrew_packages.sh"
# source "$dotdir/osx/osx_defaults" # https://raw.githubusercontent.com/mathiasbynens/dotfiles/main/.macos

#curl "https://raw.githubusercontent.com/github/linguist/master/lib/linguist/languages.yml" \
#    | yq -r '{C,"C++","C#",Java,JavaScript,TypeScript,Python,Shell} | to_entries | (map(.value.extensions) | flatten) - [null] | unique | .[]' \
#    | xargs -L 1 -I "{}" openwith com.microsoft.VSCode {} all

dot_trace "Configuring OSX-specific software done."
