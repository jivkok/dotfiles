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

# Plugins
_tmux_plugins_dir="$HOME/.tmux/plugins"
log_trace "Install & configure Tmux plugins into $_tmux_plugins_dir"
mkdir -p "$_tmux_plugins_dir"
for _plugin in {tpm,tmux-cpu,tmux-resurrect,tmux-yank}; do
  log_trace "Tmux plugin: $_plugin"
  clone_or_update_repo "https://github.com/tmux-plugins/$_plugin" "$_tmux_plugins_dir/$_plugin"
done

log_info 'Configuring Tmux done.'
