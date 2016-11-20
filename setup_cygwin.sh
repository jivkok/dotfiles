#!/bin/bash
# Configure Windows environment (Cygwin)

dotdir="$( cd "$( dirname "$0" )" && pwd )"
source "$dotdir/setupfunctions.sh"
pull_latest_dotfiles "$dotdir"

dot_trace "Configuring Windows environment (Cygwin) ..."

source "$dotdir/setupcommon.sh"

dot_trace "Configuring Windows environment (Cygwin) done."
