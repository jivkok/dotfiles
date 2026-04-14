#!/usr/bin/env bash
# Update shell profile bootstrap files to invoke the dotfiles

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

log_info "Syncing shell profiles (.bash_profile, .bashrc, .zshrc) ..."
append_or_merge_file "$dotdir/bash/.bash_profile" "$HOME/.bash_profile"
append_or_merge_file "$dotdir/bash/.bashrc" "$HOME/.bashrc"
append_or_merge_file "$dotdir/zsh/.zshrc" "$HOME/.zshrc"
log_info "Syncing shell profiles done."
