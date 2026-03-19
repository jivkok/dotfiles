# shellcheck shell=bash

# Returns whether the given command is available
_has() {
  command -v "$1" >/dev/null 2>&1
}

# OS detection
_OS="$(uname -s)"
_is_osx=false;  [[ "$_OS" == "Darwin" ]] && _is_osx=true
_is_linux=false;  [[ "$_OS" == "Linux"  ]] && _is_linux=true

# Distro detection (Linux only)
_is_arch=false;   [[ -f /etc/arch-release ]]   && _is_arch=true
_is_debian=false; [[ -f /etc/debian_version ]] && _is_debian=true
