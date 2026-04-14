#!/usr/bin/env bash
# Setup a "minimal" remote VM environment (Linux only)
# Analogous to setup.sh but for minimal, disposable VMs.
# Does NOT set up: zsh, oh-my-zsh, vim plugins, git identity, fzf, python, nodejs, go

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "${dotdir}/setup/setup_functions.sh"

if ! $_is_linux; then
  log_error "setup-remote-vm.sh is Linux-only. Detected OS: ${_OS}"
  exit 1
fi

os_description=""
os_setup_path=""

if $_is_debian; then
  os_description="Linux (Debian and derivative distros)"
  os_setup_path="${dotdir}/linux/configure_packages_minimal_debian.sh"

elif $_is_arch; then
  os_description="Linux (Arch and derivative distros)"
  os_setup_path="${dotdir}/linux/configure_packages_minimal_arch.sh"

else
  log_error "Unsupported Linux distro (no apt-get or pacman found)"
  exit 1
fi

log_info "Setting up minimal remote VM ..."

log_trace "Configuring minimal packages for ${os_description} ..."
"${os_setup_path}"
log_trace "Configuring minimal packages for ${os_description} done."

# Shell profiles: bash only (no zsh)
log_trace "Updating bash shell profile bootstrap files ..."
append_or_merge_file "${dotdir}/bash/.bash_profile" "${HOME}/.bash_profile"
append_or_merge_file "${dotdir}/bash/.bashrc" "${HOME}/.bashrc"
log_trace "Updating bash shell profile bootstrap files done."

# Home bin symlinks (minimal-relevant only: tmux-status-ip.sh)
log_trace "Configuring HOME bin directory ..."
mkdir -p "${HOME}/bin"
make_symlink "${dotdir}/bin/tmux-status-ip.sh" "${HOME}/bin"

# On Debian/Ubuntu, bat is installed as batcat; create a bat symlink so it is on PATH.
if [ ! -L "${HOME}/bin/bat" ] && [ -f "/usr/bin/batcat" ]; then
  make_symlink "/usr/bin/batcat" "${HOME}/bin" "bat"
fi
# On Debian/Ubuntu, fd-find is installed as fdfind; create an fd symlink.
if [ ! -L "${HOME}/bin/fd" ] && [ -f "/usr/bin/fdfind" ]; then
  make_symlink "/usr/bin/fdfind" "${HOME}/bin" "fd"
fi
log_trace "Configuring HOME bin directory done."

# Home symlinks (misc dotfiles)
"${dotdir}/setup/configure_home_symlinks.sh"

# Locale
"${dotdir}/setup/configure_locale.sh"

# Tmux (symlink config only, no plugin cloning)
log_trace "Configuring tmux ..."
make_symlink "${dotdir}/tmux/.tmux.conf" "${HOME}"
log_trace "Configuring tmux done."

log_info "Setting up minimal remote VM complete."

DOT_RELOAD_SHELL="${DOT_RELOAD_SHELL:-1}"
if [[ "${DOT_RELOAD_SHELL}" == "1" ]]; then
  log_trace "Reloading shell ${SHELL}"
  exec "${SHELL}" -l
fi
