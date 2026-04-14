#!/usr/bin/env bash
# Configure OSX
set -uo pipefail

dotdir="$( cd "$( dirname "$0" )/.." && pwd )"
source "$dotdir/setup/setup_functions.sh"

log_info "Configuring OSX-specific settings ..."

# Command-line tools (must be first since they install gcc)
xcode-select -p >/dev/null 2>&1
if [ $? != 0 ]; then
    log_trace "Installing XCode command-line tools ..."
    # xcode-select --install
    touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
    PROD=$(softwareupdate -l | grep "\*.*Command Line" | head -n 1 | awk -F"*" '{print $2}' | sed -e 's/^ *//' | tr -d '\n')
    softwareupdate -i "$PROD"
fi

make_dotfiles_symlinks "$dotdir/osx" "$HOME"

"$dotdir/osx/configure_osx_packages.sh"
"$dotdir/osx/configure_browsers.sh"
"$dotdir/bin/configure_fonts.sh"
# source "$dotdir/osx/osx_defaults" # https://raw.githubusercontent.com/mathiasbynens/dotfiles/main/.macos

#curl "https://raw.githubusercontent.com/github/linguist/master/lib/linguist/languages.yml" \
#    | yq -r '{C,"C++","C#",Java,JavaScript,TypeScript,Python,Shell} | to_entries | (map(.value.extensions) | flatten) - [null] | unique | .[]' \
#    | xargs -L 1 -I "{}" openwith com.microsoft.VSCode {} all

log_info "Configuring OSX-specific settings done."
