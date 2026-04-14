#!/usr/bin/env bash
# Configure HOME symlinks

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

log_info "Configuring HOME symlinks ..."

make_dotfiles_symlinks "$dotdir/misc" "$HOME"

log_info "Configuring HOME symlinks done."
