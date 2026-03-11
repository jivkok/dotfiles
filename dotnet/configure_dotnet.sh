#!/usr/bin/env bash
# Install .Net

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

dotnet_install() {
  local script_path="${TMPDIR:-/tmp}/dotnet-install.sh"

  dot_trace "Downloading dotnet-install.sh ..."
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL https://dot.net/v1/dotnet-install.sh -o "$script_path"
  elif command -v wget >/dev/null 2>&1; then
    wget https://dot.net/v1/dotnet-install.sh -O "$script_path"
  else
    dot_error "Neither curl nor wget found. Cannot download dotnet-install.sh."
    return 1
  fi
  chmod +x "$script_path"

  dot_trace "Running dotnet-install.sh (LTS) ..."
  "$script_path" --channel LTS --version latest
  # "$script_path" --channel STS --version latest
}

dot_trace "Configuring DotNet ..."

os=$(uname -s)

# https://learn.microsoft.com/en-us/dotnet/core/install/macos#install-net-with-a-script
# https://learn.microsoft.com/en-us/dotnet/core/install/linux-scripted-manual#scripted-install
if [ "$os" = "Linux" ] || [ "$os" = "Darwin" ]; then
  dotnet_install
else
  dot_error "Unsupported OS: $os"
  exit 1
fi

dot_trace "Configuring DotNet done."
