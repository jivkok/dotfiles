# shellcheck shell=bash

# Returns whether the given command is available
_has() {
  command -v "$1" >/dev/null 2>&1
}

# OS detection
_OS="$(uname -s)"
[[ "$_OS" == "Darwin" ]] && _is_osx=true   || _is_osx=false
[[ "$_OS" == "Linux"  ]] && _is_linux=true  || _is_linux=false

# Distro detection (Linux only)
[[ -f /etc/arch-release ]]   && _is_arch=true   || _is_arch=false
[[ -f /etc/debian_version ]] && _is_debian=true || _is_debian=false
