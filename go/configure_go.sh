#!/usr/bin/env bash
# Configuring Go

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

log_info "Configuring Go ..."

if $_is_debian; then
  install_or_upgrade_apt_package golang
elif $_is_arch; then
  install_or_upgrade_pacman_package go
elif $_is_osx; then
  install_or_upgrade_brew_package golang
else
  log_error "Unsupported OS: ${_OS}"
  exit 1
fi

GOPATH="$HOME/go"
log_trace "Setting up GOPATH: $GOPATH"
mkdir -p "$GOPATH" "$GOPATH/src" "$GOPATH/pkg" "$GOPATH/bin"

log_trace "Installing Go tools ..."
export GOPATH
export PATH="$GOPATH/bin:$PATH"

go install golang.org/x/tools/gopls@latest            # Go language server
go install honnef.co/go/tools/cmd/staticcheck@latest  # static analysis
go install golang.org/x/tools/cmd/goimports@latest    # auto-manage imports

log_info "Configuring Go done."
