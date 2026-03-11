#!/usr/bin/env bash
# Configuring Docker
set -euo pipefail

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

dot_trace "Configuring Docker ..."

os=$(uname -s)

if [ "$os" = "Linux" ] && command -v apt-get >/dev/null 2>&1; then
  # https://docs.docker.com/engine/install/debian/
  dot_trace "Removing conflicting Docker packages ..."
  for pkg in docker docker-engine docker.io containerd runc docker-compose; do
    sudo apt-get purge -y "$pkg" 2>/dev/null || true
  done

  dot_trace "Installing Docker (Debian/Ubuntu) ..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq ca-certificates curl

  sudo install -m 0755 -d /etc/apt/keyrings
  # shellcheck disable=SC1091
  sudo curl -fsSL "https://download.docker.com/linux/$(. /etc/os-release && echo "$ID")/gpg" \
    -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  # shellcheck disable=SC1091
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update -qq
  sudo apt-get install -y -qq \
    docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

elif [ "$os" = "Linux" ] && command -v pacman >/dev/null 2>&1; then
  dot_trace "Installing Docker (Arch) ..."
  sudo pacman -S --noconfirm --needed docker docker-compose

elif [ "$os" = "Darwin" ]; then
  dot_trace "Installing Docker (macOS) ..."
  if ! brew list --cask docker >/dev/null 2>&1; then
    brew install --cask docker
  else
    dot_trace "Docker Desktop already installed."
  fi

else
  dot_error "Unsupported OS: $os"
  exit 1
fi

# Post-install steps (Linux only)
# https://docs.docker.com/engine/install/linux-postinstall/
if [ "$os" = "Linux" ]; then
  dot_trace "Configuring Docker post-install (group, permissions, service) ..."
  _current_user="$(id -un)"
  sudo groupadd -f docker
  sudo usermod -aG docker "$_current_user"
  [ -d "$HOME/.docker" ] && sudo chown "$_current_user":"$_current_user" "$HOME/.docker" -R && sudo chmod g+rwx "$HOME/.docker" -R

  if command -v systemctl >/dev/null 2>&1; then
    sudo systemctl enable docker.service
    sudo systemctl enable containerd.service
  fi
fi

dot_trace "Configuring Docker done."
