#!/usr/bin/env bash
# Configure locale

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

log_info "Configuring locale ..."

if $_is_debian; then
  sudo localectl set-locale LANG=en_US.UTF-8
  sudo locale-gen --purge "en_US.UTF-8"
  sudo dpkg-reconfigure --frontend noninteractive locales

elif $_is_arch; then
  sudo localectl set-locale LANG=en_US.UTF-8
  sudo locale-gen --purge "en_US.UTF-8"

elif $_is_osx; then
  log_trace "Handled via 'System Preferences'"

else
  log_error "Unsupported OS: ${_OS}"
  exit 1
fi

log_info "Configuring locale done."
