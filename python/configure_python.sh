#!/usr/bin/env bash
# Configuring Python

os=$(uname -s)
if [ "$os" = "Linux" ] && command -V apt >/dev/null 2>&1; then
  sudo add-apt-repository universe
  sudo apt-get update
  sudo apt-get install -y python3 python3-pip
  sudo -H pip3 install --upgrade pip setuptools
elif [ "$os" = "Linux" ] && command -V pacman >/dev/null 2>&1; then
  sudo pacman -S --noconfirm python3 python-pip
elif [ "$os" = "Darwin" ]; then
  ! brew ls --versions python3 >/dev/null 2>&1 && brew install python3 && brew postinstall python3 && brew link python3
  python3 -m pip install --upgrade pip setuptools
else
  echo "Unsupported system:"
  uname -a
  return 1 >/dev/null 2>&1
  exit 1
fi

# Packages installed by default
python3 -m pip install --user --upgrade glances # system stats      APT YAY BREW
python3 -m pip install --user --upgrade httpie  # curl-like with colorized output    APT PACMAN BREW
python3 -m pip install --user --upgrade icdiff  # improved color diff. Use it for diffing two files.     HOME_BIN

# Packages used at one point
# python3 -m pip install --user --upgrade jsbeautifier # reformat and reindent JavaScript code. jsbeautifier.org. Use with 'js-beautify somefile.js'
# python3 -m pip install --user --upgrade jupyter # Jupyter Notebooks
# python3 -m pip install --user --upgrade mitmproxy # http traffic interception
# python3 -m pip install --user --upgrade pygments # syntax highlighter
# python3 -m pip install --user --upgrade pylint # Python linter
# python3 -m pip install --user --upgrade ydiff # color diff. Use it within a Git repo.
