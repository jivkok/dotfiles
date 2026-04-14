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

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "${dotdir}/setup/setup_functions.sh"

DOT_PULL_DOTFILES="${DOT_PULL_DOTFILES:-1}"
if [[ "${DOT_PULL_DOTFILES}" == "1" ]]; then
  pull_latest_dotfiles "${dotdir}"
fi

os_description=""
os_setup_path=""

if $_is_debian; then
  os_description="Linux (Debian and derivative distros)"
  os_setup_path="${dotdir}/linux/configure_packages_debian.sh"

elif $_is_arch; then
  os_description="Linux (Arch and derivative distros)"
  os_setup_path="${dotdir}/linux/configure_packages_arch.sh"

elif $_is_osx; then
  os_description="OSX"
  os_setup_path="${dotdir}/osx/configure_osx.sh"

else
  log_error "Unsupported OS: ${_OS}"
  exit 1
fi

log_trace "OS: ${os_description}"
"${os_setup_path}"

"${dotdir}/setup/configure_shell_profiles.sh"
"${dotdir}/setup/configure_home_symlinks.sh"
"${dotdir}/setup/configure_home_bin.sh"
"${dotdir}/setup/configure_locale.sh"
"${dotdir}/git/configure_git.sh"
"${dotdir}/python/configure_python.sh"
"${dotdir}/nodejs/configure_nodejs.sh"
"${dotdir}/vim/configure_vim.sh"
"${dotdir}/zsh/configure_zsh.sh"
"${dotdir}/tmux/configure_tmux.sh"
"${dotdir}/fzf/configure_fzf.sh"

log_info "Configuring system done."

DOT_RELOAD_SHELL="${DOT_RELOAD_SHELL:-1}"
if [[ "${DOT_RELOAD_SHELL}" == "1" ]]; then
  log_trace "Reloading shell ${SHELL}"
  exec ${SHELL} -l
fi
