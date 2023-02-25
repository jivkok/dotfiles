#!/usr/bin/env bash
# Configure HOME symlinks

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

dot_trace "Configuring HOME symlinks ..."

make_dotfiles_symlinks "$dotdir/bash" "$HOME"
make_dotfiles_symlinks "$dotdir/misc" "$HOME"
make_dotfiles_symlinks "$dotdir/sh" "$HOME"
make_dotfiles_symlinks "$dotdir/zsh" "$HOME"

dot_trace "Configuring HOME symlinks done."
