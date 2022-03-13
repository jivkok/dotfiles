#!/usr/bin/env bash
# Setup machine environment

# dotfiles location
# dotdir="$( cd "$( dirname "$0" )" && pwd )"
# Solution for executable scripts (not just sourced files):
# dotdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Solution for executable scripts with symlinks:
# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-which-directory-it-is-stored-in
# SOURCE="${BASH_SOURCE[0]}"
# while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
#   DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
#   SOURCE="$(readlink "$SOURCE")"
#   [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
# done
# DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

dotdir="$( cd "$( dirname "$0" )/.." && pwd )"
source "$dotdir/setup/setup_functions.sh"
pull_latest_dotfiles "$dotdir"

"$dotdir/setup/configure_home_symlinks.sh"
"$dotdir/setup/configure_home_bin.sh"
"$dotdir/git/configure_git.sh"
"$dotdir/python/configure_python.sh"
"$dotdir/vim/configure_vim.sh"
"$dotdir/zsh/configure_zsh.sh"
"$dotdir/tmux/configure_tmux.sh"

dot_trace "Reloading shell $SHELL"
exec $SHELL -l
