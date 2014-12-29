#!/bin/bash -x
# Configuring SublimeText

scriptdir="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
settingsDir="$HOME/dotfiles/sublimetext"

sublimeUserDataPath="$HOME/.config/sublime-text-3/Packages/User"
mkdir -p $sublimeUserDataPath
sublimeInstalledPackagesPath="$HOME/.config/sublime-text-3/Installed Packages"
mkdir -p $sublimeInstalledPackagesPath

cp -f $settingsDir/*.sublime-settings "$sublimeUserDataPath"
cp -f "$settingsDir/Default (Linux).sublime-keymap" "$sublimeUserDataPath"

wget -O "$sublimeInstalledPackagesPath/Package Control.sublime-package" http://sublime.wbond.net/Package%20Control.sublime-package
