#!/usr/bin/env bash
# Configuring NodeJS (and NPM packages)

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

dot_trace "Configuring NodeJS ..."

os=$(uname -s)
if [ "$os" = "Linux" ] && command -V apt-get >/dev/null 2>&1; then
  sudo apt-get install -y -qq nodejs npm
elif [ "$os" = "Linux" ] && command -V pacman >/dev/null 2>&1; then
  sudo pacman -S --noconfirm --needed nodejs npm
elif [ "$os" = "Darwin" ]; then
  ! brew ls --versions node >/dev/null 2>&1 && brew install node
else
  dot_error "Unsupported OS: $os"
  exit 1
fi

dot_trace "Installing NPM packages ..."
npm install -g n               # Node version manager

# apt packages Node conservatively (often behind LTS); upgrade via n.
# Arch (pacman) and macOS (Homebrew) are rolling/current — n would install
# to /usr/local/bin but be shadowed by the system binary, so skip it there.
if [ "$os" = "Linux" ] && command -v apt-get >/dev/null 2>&1; then
  sudo n lts
fi

npm install -g diff2html-cli  # Fast Diff to colorized HTML
npm install -g eslint          # JavaScript/TypeScript linter
npm install -g http-server     # Zero-configuration command-line HTTP server
npm install -g nodemon         # Auto-restart node apps on file changes
npm install -g typescript      # TypeScript language

npm cache verify

dot_trace "Configuring NodeJS done."
