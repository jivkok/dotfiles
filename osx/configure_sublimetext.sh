#!/bin/sh
# Configuring SublimeText

settingsDir="$HOME/dotfiles/sublimetext"

sublimeUserDataPath="$HOME/Library/Application Support/Sublime Text 3/Packages/User"
mkdir -p $sublimeUserDataPath
sublimeInstalledPackagesPath="$HOME/Library/Application Support/Sublime Text 3/Installed Packages"
mkdir -p $sublimeInstalledPackagesPath

cp -f $settingsDir/*.sublime-settings "$sublimeUserDataPath"
cp -f "$settingsDir/Default (OSX).sublime-keymap" "$sublimeUserDataPath"

wget -O "$sublimeInstalledPackagesPath/Package Control.sublime-package" http://sublime.wbond.net/Package%20Control.sublime-package
