#!/usr/bin/env bash
# Configuring NodeJS (and NPM packages)

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

log_info "Configuring NodeJS ..."

if $_is_debian; then
  install_or_upgrade_apt_package nodejs
  install_or_upgrade_apt_package npm
elif $_is_arch; then
  install_or_upgrade_pacman_package nodejs
  install_or_upgrade_pacman_package npm
elif $_is_osx; then
  install_or_upgrade_brew_package node
else
  log_error "Unsupported OS: ${_OS}"
  exit 1
fi

log_trace "Installing NPM packages ..."
install_or_upgrade_npm_package n               # Node version manager

# apt packages Node conservatively (often behind LTS); upgrade via n.
# Arch (pacman) and macOS (Homebrew) are rolling/current — n would install
# to /usr/local/bin but be shadowed by the system binary, so skip it there.
if $_is_debian; then
  sudo env "PATH=$PATH" n lts
fi

install_or_upgrade_npm_package diff2html-cli   # Fast Diff to colorized HTML
install_or_upgrade_npm_package eslint          # JavaScript/TypeScript linter
install_or_upgrade_npm_package http-server     # Zero-configuration command-line HTTP server
install_or_upgrade_npm_package nodemon         # Auto-restart node apps on file changes
install_or_upgrade_npm_package typescript      # TypeScript language

npm cache verify >/dev/null

log_info "Configuring NodeJS done."
