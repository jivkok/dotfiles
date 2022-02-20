#!/usr/bin/env bash
# Configuring Docker

os=$(uname -s)

if [ "$os" = "Linux" ] && command -V apt >/dev/null 2>&1; then
    # https://docs.docker.com/install/linux/docker-ce/ubuntu/
    sudo apt-get remove docker docker-engine docker.io containerd runc
    sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io

    # https://docs.docker.com/install/linux/linux-postinstall/
    sudo groupadd docker
    sudo usermod -aG docker "$USER"
    [ -d "$HOME/.docker" ] && sudo chown "$USER":"$USER" "$HOME/.docker" -R && sudo chmod g+rwx "$HOME/.docker" -R

    # https://docs.docker.com/compose/install/
    sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

elif [ "$os" = "Linux" ] && command -V pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm docker

    # https://docs.docker.com/install/linux/linux-postinstall/
    sudo groupadd docker
    sudo usermod -aG docker "$USER"
    [ -d "$HOME/.docker" ] && sudo chown "$USER":"$USER" "$HOME/.docker" -R && sudo chmod g+rwx "$HOME/.docker" -R

    # docker-compose
    yay -S docker-compose

elif [ "$os" = "Darwin" ]; then
    ! brew ls --versions python3 >/dev/null 2>&1 && brew install python3
    pip3 install --upgrade pip setuptools

else
    echo "Unsupported OS: $os"
    return 1 >/dev/null 2>&1
    exit 1
fi
