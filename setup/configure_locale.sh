#!/usr/bin/env bash
# Configure locale

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

dot_trace "Configuring locale ..."

os=$(uname -s)
if [ "$os" = "Linux" ] && command -V apt >/dev/null 2>&1; then
  sudo localectl set-locale LANG=en_US.UTF-8
  sudo locale-gen --purge "en_US.UTF-8"
  sudo dpkg-reconfigure --frontend noninteractive locales

elif [ "$os" = "Linux" ] && command -V pacman >/dev/null 2>&1; then
  sudo localectl set-locale LANG=en_US.UTF-8
  sudo locale-gen --purge "en_US.UTF-8"

elif [ "$os" = "Darwin" ]; then
  dot_trace "Handled via 'System Preferences'"

else
  dot_error "Unsupported OS: $os"
  return 1 >/dev/null 2>&1
  exit 1
fi

dot_trace "Configuring locale done."
