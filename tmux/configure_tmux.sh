#!/usr/bin/env bash
# Tmux configuration

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

log_info 'Configuring Tmux ...'

if $_is_debian; then
  install_or_upgrade_apt_package tmux
elif $_is_arch; then
  install_or_upgrade_pacman_package tmux
elif $_is_osx; then
  install_or_upgrade_brew_package tmux
else
  log_error "Unsupported OS: ${_OS}"
  exit 1
fi

# Config
make_symlink "$dotdir/tmux/.tmux.conf" "$HOME"
mkdir -p "$HOME/.tmux"
make_symlink "$dotdir/tmux/osc52.sh" "$HOME/.tmux"

log_info 'Configuring Tmux done.'
