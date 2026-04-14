#!/usr/bin/env bash
# Install .Net

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

dotnet_install() {
  local script_path="${TMPDIR:-/tmp}/dotnet-install.sh"

  log_trace "Downloading dotnet-install.sh ..."
  download_file "https://dot.net/v1/dotnet-install.sh" "$script_path"
  chmod +x "$script_path"

  log_trace "Running dotnet-install.sh (LTS) ..."
  "$script_path" --channel LTS --version latest
  # "$script_path" --channel STS --version latest
}

log_info "Configuring DotNet ..."

# https://learn.microsoft.com/en-us/dotnet/core/install/macos#install-net-with-a-script
# https://learn.microsoft.com/en-us/dotnet/core/install/linux-scripted-manual#scripted-install
if $_is_osx || $_is_linux; then
  dotnet_install
else
  log_error "Unsupported OS: ${_OS}"
  exit 1
fi

log_info "Configuring DotNet done."
