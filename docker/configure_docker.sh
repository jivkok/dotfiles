#!/usr/bin/env bash
# Configuring Docker

os=$(uname -s)

if [ "$os" = "Linux" ] && command -V apt-get >/dev/null 2>&1; then
  # https://docs.docker.com/engine/install/debian/
  sudo apt-get purge docker
  sudo apt-get purge docker-engine
  sudo apt-get purge docker.io
  sudo apt-get purge containerd
  sudo apt-get purge runc
  sudo apt-get install -y -qq apt-transport-https ca-certificates curl gnupg-agent software-properties-common
  distribution=$(grep '^ID=' /etc/os-release | cut -d '=' -f2)
  codename=$(lsb_release -cs)
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository -y "deb [arch=amd64] https://download.docker.com/linux/$distribution $codename stable"
  sudo apt-get update -qq
  sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io
  sudo apt-get install -y -qq docker-compose-plugin

elif [ "$os" = "Linux" ] && command -V pacman >/dev/null 2>&1; then
  sudo pacman -S --noconfirm --needed docker
  yay -S docker-compose

else
  echo "Unsupported OS: $os"
  return 1 >/dev/null 2>&1
  exit 1
fi

# https://docs.docker.com/engine/install/linux-postinstall/
sudo groupadd docker
sudo usermod -aG docker "$USER"
[ -d "$HOME/.docker" ] && sudo chown "$USER":"$USER" "$HOME/.docker" -R && sudo chmod g+rwx "$HOME/.docker" -R

