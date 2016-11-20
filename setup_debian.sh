#!/bin/bash
# Configure Linux environment (Debian-style)

dotdir="$( cd "$( dirname "$0" )" && pwd )"
source "$dotdir/setupfunctions.sh"
pull_latest_dotfiles "$dotdir"

dot_trace "Configuring Linux environment (Debian-style) ..."

confirm_and_run "$dotdir/linux/packages.sh" "system packages"
confirm_and_run "$dotdir/linux/software.sh" "GUI packages"

source "$dotdir/setupcommon.sh"

dot_trace "Configuring Linux environment (Debian-style) done."
