#!/usr/bin/env bash
# Configure ZSH

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

log_info "Configuring ZSH ..."

if $_is_debian; then
  install_or_upgrade_apt_package zsh
elif $_is_arch; then
  install_or_upgrade_pacman_package zsh
elif $_is_osx; then
  install_or_upgrade_brew_package zsh
else
  log_error "Unsupported OS: ${_OS}"
  exit 1
fi

log_trace "Installing zsh plugins ..."
zpluginsdir="$HOME/.zsh/plugins"
mkdir -p "$zpluginsdir"
clone_or_update_repo "https://github.com/zsh-users/zsh-autosuggestions" "$zpluginsdir/zsh-autosuggestions"
clone_or_update_repo "https://github.com/zsh-users/zsh-completions" "$zpluginsdir/zsh-completions"
clone_or_update_repo "https://github.com/zsh-users/zsh-syntax-highlighting" "$zpluginsdir/zsh-syntax-highlighting"
log_trace "Installing zsh plugins done."

_zsh=$(command -v zsh)

if [ -z "$(grep "$_zsh" /etc/shells)" ]; then
  log_trace "Adding ZSH as supported shell"
  echo "$_zsh" | sudo tee -a /etc/shells
else
  log_trace "Check: ZSH is supported shell"
fi

if [ "$SHELL" != "$_zsh" ]; then
  log_trace "Switching to ZSH as default shell"
  [ -f /etc/pam.d/chsh ] && sudo sed -ir 's/^\(auth\)\s\+\(required\)\s\+\(pam_shells\.so\)/\1 sufficient \3/' /etc/pam.d/chsh
  chsh -s "$_zsh"
else
  log_trace "Check: ZSH is default shell"
fi

unset _zsh

log_info "Configuring ZSH done."
