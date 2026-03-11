#!/usr/bin/env bash
# Configuring Go

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

dot_trace "Configuring Go ..."

os=$(uname -s)
if [ "$os" = "Linux" ] && command -V apt-get >/dev/null 2>&1; then
  sudo apt install -y -qq golang
elif [ "$os" = "Linux" ] && command -V pacman >/dev/null 2>&1; then
  sudo pacman -S --noconfirm --needed go
elif [ "$os" = "Darwin" ]; then
  if ! brew ls --versions golang >/dev/null 2>&1; then
    dot_trace "Installing Go"
    brew install --quiet golang
  else
    dot_trace "Updating Go"
    brew upgrade --quiet golang
  fi
else
  dot_error "Unsupported OS: $os"
  return 1 >/dev/null 2>&1
  exit 1
fi

GOPATH="$HOME/go"
dot_trace "Setting up GOPATH: $GOPATH"
mkdir -p "$GOPATH" "$GOPATH/src" "$GOPATH/pkg" "$GOPATH/bin"

dot_trace "Installing Go tools ..."
export GOPATH
export PATH="$GOPATH/bin:$PATH"

go install golang.org/x/tools/gopls@latest         # Go language server
go install honnef.co/go/tools/cmd/staticcheck@latest  # static analysis
go install golang.org/x/tools/cmd/goimports@latest    # auto-manage imports

dot_trace "Configuring Go done."
