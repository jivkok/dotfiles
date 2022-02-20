#!/usr/bin/env bash
# Configure computer environment - common steps

[ -z "$dotdir" ] && dotdir="$HOME/dotfiles"
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

source "$dotdir/setupfunctions.sh"
pull_latest_dotfiles "$dotdir"

confirm_and_run "$dotdir/configure_home_symlinks.sh" "Home symlinks"
confirm_and_run "$dotdir/configure_home_bin.sh" "Home bin folder"
confirm_and_run "$dotdir/configure_git.sh" "Git"
confirm_and_run "$dotdir/configure_python.sh" "Python (plus packages)"
confirm_and_run "$dotdir/configure_nodejs.sh" "NodeJS (plus packages)"
confirm_and_run "$dotdir/configure_go.sh" "Go"
confirm_and_run "$dotdir/configure_vim.sh" "Vim"
confirm_and_run "$dotdir/configure_zsh.sh" "Zsh"

dot_trace "Reloading shell $SHELL"
exec $SHELL -l
