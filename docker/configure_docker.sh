#!/usr/bin/env bash
# Configuring Docker
set -uo pipefail

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

log_info "Configuring Docker ..."

if $_is_debian; then
  # https://docs.docker.com/engine/install/debian/
  log_trace "Removing conflicting Docker packages ..."
  for pkg in docker docker-engine docker.io containerd runc docker-compose; do
    if dpkg -s "$pkg" >/dev/null 2>&1; then
      sudo apt-get purge -y "$pkg"
    fi
  done

  log_trace "Installing Docker (Debian/Ubuntu) ..."
  sudo apt-get update -qq
  install_or_upgrade_apt_package ca-certificates
  install_or_upgrade_apt_package curl

  if [ ! -f /etc/apt/keyrings/docker.asc ]; then
    sudo install -m 0755 -d /etc/apt/keyrings
    # shellcheck disable=SC1091
    sudo curl -fsSL "https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg" \
      -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    log_trace "Docker GPG key added."
  else
    log_trace "Docker GPG key already present."
  fi

  if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    # shellcheck disable=SC1091
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    log_trace "Docker apt repo added."
  else
    log_trace "Docker apt repo already configured."
  fi

  sudo apt-get update -qq
  install_or_upgrade_apt_package docker-ce
  install_or_upgrade_apt_package docker-ce-cli
  install_or_upgrade_apt_package containerd.io
  install_or_upgrade_apt_package docker-buildx-plugin
  install_or_upgrade_apt_package docker-compose-plugin

elif $_is_arch; then
  log_trace "Installing Docker (Arch) ..."
  install_or_upgrade_pacman_package docker
  install_or_upgrade_pacman_package docker-compose

elif $_is_osx; then
  log_trace "Installing Docker (macOS) ..."
  install_or_upgrade_cask_package docker

else
  log_error "Unsupported OS: ${_OS}"
  exit 1
fi

# Post-install steps (Linux only)
# https://docs.docker.com/engine/install/linux-postinstall/
if $_is_linux; then
  log_trace "Configuring Docker post-install (group, permissions, service) ..."
  _current_user="$(id -un)"
  sudo groupadd -f docker
  sudo usermod -aG docker "$_current_user"
  [ -d "$HOME/.docker" ] && sudo chown "$_current_user":"$_current_user" "$HOME/.docker" -R && sudo chmod g+rwx "$HOME/.docker" -R

  if _has systemctl; then
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
  fi
fi

log_info "Configuring Docker done."
