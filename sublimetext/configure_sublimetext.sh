#!/usr/bin/env bash
# Configuring SublimeText

os=$(uname -s)
os_label=$os
if [ "$os" = "Linux" ]; then
    sublimeUserDataPath="$HOME/.config/sublime-text-3/Packages/User"
    sublimeInstalledPackagesPath="$HOME/.config/sublime-text-3/Installed Packages"
elif [ "$os" = "Darwin" ]; then
    sublimeUserDataPath="$HOME/Library/Application Support/Sublime Text 3/Packages/User"
    sublimeInstalledPackagesPath="$HOME/Library/Application Support/Sublime Text 3/Installed Packages"
    os_label=OSX
else
    echo "Unsupported OS: $os"
    return
fi

mkdir -p "$sublimeUserDataPath"
mkdir -p "$sublimeInstalledPackagesPath"

# dotdir="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
[ -z "$dotdir" ] && dotdir="$HOME/dotfiles"
settingsDir="$dotdir/sublimetext"

cp -f "$settingsDir"/*.sublime-settings "$sublimeUserDataPath"
cp -f "$settingsDir/Default ($os_label).sublime-keymap" "$sublimeUserDataPath"

curl -o "$sublimeInstalledPackagesPath/Package Control.sublime-package" https://packagecontrol.io/Package%20Control.sublime-package
