#!/usr/bin/env bash
# Configuring Python

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
    brew install python3
  else
    dot_trace "Updating Python"
    brew upgrade python3
  fi
  brew postinstall python3
  brew link python3

  dot_trace "Installing/updating packages pip & setuptools (system-scope)"
  python3 -m pip install --upgrade pip setuptools

  if ! brew ls --versions python3 >/dev/null 2>&1; then
    dot_trace "Installing pipx"
    brew install pipx
  else
    dot_trace "Updating pipx"
    brew upgrade pipx
  fi
else
  dot_error "Unsupported system:"
  uname -a
  return 1 >/dev/null 2>&1
  exit 1
fi

dot_trace "Installing/updating packages (user-scope)"
pipx upgrade-all
pipx install glances # system stats      APT YAY BREW
pipx install httpie  # curl-like with colorized output    APT PACMAN BREW
pipx install icdiff  # improved color diff. Use it for diffing two files.     HOME_BIN

# Packages used at one point
# python3 -m pip install --user --upgrade jsbeautifier # reformat and reindent JavaScript code. jsbeautifier.org. Use with 'js-beautify somefile.js'
# python3 -m pip install --user --upgrade jupyter # Jupyter Notebooks
# python3 -m pip install --user --upgrade mitmproxy # http traffic interception
# python3 -m pip install --user --upgrade pygments # syntax highlighter
# python3 -m pip install --user --upgrade pylint # Python linter
# python3 -m pip install --user --upgrade ydiff # color diff. Use it within a Git repo.

dot_trace "Configuring Python done."
