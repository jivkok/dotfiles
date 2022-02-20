#!/usr/bin/env bash
# Configuring Go

os=$(uname -s)
if [ "$os" = "Linux" ] && command -V apt >/dev/null 2>&1; then
  sudo apt install -y golang-go
elif [ "$os" = "Linux" ] && command -V pacman >/dev/null 2>&1; then
  sudo pacman -S --noconfirm go
elif [ "$os" = "Darwin" ]; then
  ! brew ls --versions golang >/dev/null 2>&1 && brew install golang
else
  echo "Unsupported OS: $os"
  return 1 >/dev/null 2>&1
  exit 1
fi

GOPATH="$HOME/go"
mkdir -p "$GOPATH" "$GOPATH/src" "$GOPATH/pkg" "$GOPATH/bin"
