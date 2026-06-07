#!/usr/bin/env bash
# Configuring Rust

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

log_info "Configuring Rust ..."

if $_is_debian; then
  # rustup is not reliably packaged in apt; install via the official installer
  if ! command -v rustup >/dev/null 2>&1; then
    log_trace "Installing rustup via official installer ..."
    download_file "https://sh.rustup.rs" "$HOME/.cache/rustup-init.sh"
    chmod +x "$HOME/.cache/rustup-init.sh"
    "$HOME/.cache/rustup-init.sh" -y --no-modify-path
    rm -f "$HOME/.cache/rustup-init.sh"
  else
    log_trace "rustup already installed, updating ..."
    rustup self update
  fi
elif $_is_arch; then
  install_or_upgrade_pacman_package rustup
elif $_is_osx; then
  install_or_upgrade_brew_package rustup
else
  log_error "Unsupported OS: ${_OS}"
  exit 1
fi

export PATH="$HOME/.cargo/bin:$PATH"

log_trace "Installing stable toolchain ..."
rustup toolchain install stable
rustup default stable

log_trace "Installing Rust components ..."
rustup component add rust-analyzer  # language server
rustup component add clippy         # linting
rustup component add rustfmt        # formatting

log_info "Configuring Rust done."
