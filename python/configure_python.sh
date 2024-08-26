#!/usr/bin/env bash
# Configuring Python

install_pipx_package() {
  if [ -z "$1" ]; then
    echo "Package name not specified."
    return
  fi

  local package="$1"
  local installed=$(pipx list | grep "package $package")

  if [ -z "$installed" ]; then
    pipx install --quiet "$package"
  fi
}

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

dot_trace "Configuring Python ..."

os=$(uname -s)
if [ "$os" = "Linux" ] && command -V apt-get >/dev/null 2>&1; then
  # sudo add-apt-repository universe
  sudo apt-get update -qq
  sudo apt-get install -y -qq python3 python3-pip pipx
elif [ "$os" = "Linux" ] && command -V pacman >/dev/null 2>&1; then
  sudo pacman -S --noconfirm --needed python3 python-pip python-pipx
elif [ "$os" = "Darwin" ]; then
  if ! brew ls --versions python3 >/dev/null 2>&1; then
    dot_trace "Installing Python"
    brew install --quiet python3
  else
    dot_trace "Updating Python"
    brew upgrade --quiet python3
  fi
  brew postinstall --quiet python3
  brew link --quiet python3

  if ! brew ls --versions pipx >/dev/null 2>&1; then
    dot_trace "Installing pipx"
    brew install --quiet pipx
  else
    dot_trace "Updating pipx"
    brew upgrade --quiet pipx
  fi
else
  dot_error "Unsupported system:"
  uname -a
  return 1 >/dev/null 2>&1
  exit 1
fi

dot_trace "Installing/updating packages (user-scope)"
pipx upgrade-all --quiet # pipx reinstall-all --quiet
install_pipx_package glances # system stats      APT YAY BREW
install_pipx_package httpie  # curl-like with colorized output    APT PACMAN BREW
install_pipx_package icdiff  # improved color diff. Use it for diffing two files.     HOME_BIN

# Packages used at one point
# python3 -m pip install --user --upgrade jsbeautifier # reformat and reindent JavaScript code. jsbeautifier.org. Use with 'js-beautify somefile.js'
# python3 -m pip install --user --upgrade jupyter # Jupyter Notebooks
# python3 -m pip install --user --upgrade mitmproxy # http traffic interception
# python3 -m pip install --user --upgrade pygments # syntax highlighter
# python3 -m pip install --user --upgrade pylint # Python linter
# python3 -m pip install --user --upgrade ydiff # color diff. Use it within a Git repo.

dot_trace "Configuring Python done."
