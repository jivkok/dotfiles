#!/bin/bash
# Configure Windows environment (Babun distro for Cygwin)

dotdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$dotdir/setupfunctions.sh"
pull_latest_dotfiles "$dotdir"

dot_trace "Configuring Windows environment (Babun distro for Cygwin) ..."

# Packages
pact update
pact install tmux

source "$dotdir/setupcommon.sh"

dot_trace "Configuring Windows environment (Babun distro for Cygwin) done."
