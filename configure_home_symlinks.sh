#!/usr/bin/env bash
# Configure HOME symlinks

dotdir="$( cd "$( dirname "$0" )" && pwd )"
source "$dotdir/setupfunctions.sh"

dot_trace "Configuring HOME symlinks ..."

make_dotfiles_symlinks "$dotdir" "$HOME"

dot_trace "Configuring HOME symlinks done."
