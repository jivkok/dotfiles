#!/usr/bin/env bash
# Install .Net

dotnet_install() {
  script_path="${TMPDIR:-/tmp}/dotnet-install.sh"

  wget https://dot.net/v1/dotnet-install.sh -O "$script_path"
  chmod +x "$script_path"

  "$script_path" --channel LTS --version latest
  # "$script_path" --channel STS --version latest
}

echo 'Configuring DotNet ...'

os=$(uname -s)

# https://learn.microsoft.com/en-us/dotnet/core/install/remove-runtime-sdk-versions
# https://learn.microsoft.com/en-us/dotnet/core/install/linux-scripted-manual#scripted-install
# This script  installs artifacts for current user. Read docs for system-wide install:
# https://learn.microsoft.com/en-us/dotnet/core/install/linux
if [ "$os" = "Linux" ]; then
  sudo rm -rf /usr/share/dotnet/
  sudo rm -rf /usr/lib/dotnet/
  rm -rf "$HOME/.dotnet"

  dotnet_install

elif [ "$os" = "Darwin" ]; then
  dotnet_install
  brew install --cask visual-studio-code

else
  echo "Unsupported OS: $os"
  return
fi

echo 'Configuring DotNet done.'
