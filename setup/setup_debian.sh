#!/usr/bin/env bash
# Configure Linux environment (Debian and derivative distros)

dotdir="$( cd "$( dirname "$0" )/.." && pwd )"
source "$dotdir/setup/setup_functions.sh"

dot_trace "Configuring Linux environment (Debian and derivative distros) ..."
"$dotdir/linux/packages.sh"
"$dotdir/setup/setup.sh"
dot_trace "Configuring Linux environment (Debian and derivative distros) done."
