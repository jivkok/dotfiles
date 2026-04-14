#!/usr/bin/env bash
# Configuring SublimeText

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

log_info "Configuring SublimeText ..."

if $_is_linux; then
  sublimeUserDataPath="$HOME/.config/sublime-text-3/Packages/User"
  sublimeInstalledPackagesPath="$HOME/.config/sublime-text-3/Installed Packages"
  os_label=Linux
elif $_is_osx; then
  sublimeUserDataPath="$HOME/Library/Application Support/Sublime Text 3/Packages/User"
  sublimeInstalledPackagesPath="$HOME/Library/Application Support/Sublime Text 3/Installed Packages"
  os_label=OSX
else
  log_error "Unsupported OS: ${_OS}"
  return
fi

mkdir -p "$sublimeUserDataPath"
mkdir -p "$sublimeInstalledPackagesPath"

settingsDir="$dotdir/sublimetext"

cp -f "$settingsDir"/*.sublime-settings "$sublimeUserDataPath"
cp -f "$settingsDir/Default ($os_label).sublime-keymap" "$sublimeUserDataPath"

download_file "https://packagecontrol.io/Package%20Control.sublime-package" "$sublimeInstalledPackagesPath/Package Control.sublime-package"

log_info "Configuring SublimeText done."
