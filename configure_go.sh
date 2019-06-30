#!/bin/bash
# Configuring Go

os=$(uname -s)
if [ "$os" = "Linux" ]; then
  sudo apt install golang-go
elif [ "$os" = "Darwin" ]; then
  ! brew ls --versions golang >/dev/null 2>&1 && brew install golang
else
  echo "Unsupported OS: $os"
  return
fi

GOPATH="$HOME/go"
mkdir -p "$GOPATH" "$GOPATH/src" "$GOPATH/pkg" "$GOPATH/bin"

# Packages
go get github.com/jesseduffield/lazygit
go get github.com/jesseduffield/lazydocker
go get -u mvdan.cc/sh/cmd/shfmt
