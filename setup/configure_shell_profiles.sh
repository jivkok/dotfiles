#!/usr/bin/env bash
# Update shell profile bootstrap files to invoke the dotfiles

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

dot_trace "Updating shell profile bootstrap files to invoke the dotfiles ..."
append_or_merge_file "$dotdir/bash/.bash_profile" "$HOME/.bash_profile"
append_or_merge_file "$dotdir/bash/.bashrc" "$HOME/.bashrc"
append_or_merge_file "$dotdir/zsh/.zshrc" "$HOME/.zshrc"
dot_trace "Updating shell profile bootstrap files to invoke the dotfiles done."
