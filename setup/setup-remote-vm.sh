#!/usr/bin/env bash
# Setup a "minimal" remote VM environment (Linux only)
# Analogous to setup.sh but for minimal, disposable VMs.
# Does NOT set up: zsh, oh-my-zsh, vim plugins, git identity, fzf, python, nodejs, go

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "${dotdir}/setup/setup_functions.sh"

os=$(uname -s)

if [[ "${os}" != "Linux" ]]; then
  dot_error "setup-remote-vm.sh is Linux-only. Detected OS: ${os}"
  exit 1
fi

os_description=""
os_setup_path=""

if command -v apt-get >/dev/null 2>&1; then
  os_description="Linux (Debian and derivative distros)"
  os_setup_path="${dotdir}/linux/configure_packages_minimal_debian.sh"

elif command -v pacman >/dev/null 2>&1; then
  os_description="Linux (Arch and derivative distros)"
  os_setup_path="${dotdir}/linux/configure_packages_minimal_arch.sh"

else
  dot_error "Unsupported Linux distro (no apt-get or pacman found)"
  exit 1
fi

dot_trace "Configuring minimal packages for ${os_description} ..."
"${os_setup_path}"
dot_trace "Configuring minimal packages for ${os_description} done."

# Shell profiles: bash only (no zsh)
dot_trace "Updating bash shell profile bootstrap files ..."
append_or_merge_file "${dotdir}/bash/.bash_profile" "${HOME}/.bash_profile"
append_or_merge_file "${dotdir}/bash/.bashrc" "${HOME}/.bashrc"
dot_trace "Updating bash shell profile bootstrap files done."

# Home bin symlinks (minimal-relevant only: tmux-status-ip.sh)
dot_trace "Configuring HOME bin directory ..."
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
dot_trace "Configuring HOME bin directory done."

# Home symlinks (misc dotfiles)
"${dotdir}/setup/configure_home_symlinks.sh"

# Locale
"${dotdir}/setup/configure_locale.sh"

# Tmux (symlink config only, no plugin cloning)
dot_trace "Configuring tmux ..."
make_symlink "${dotdir}/tmux/.tmux.conf" "${HOME}"
dot_trace "Configuring tmux done."

dot_trace "Minimal remote VM setup complete."

DOT_RELOAD_SHELL="${DOT_RELOAD_SHELL:-1}"
if [[ "${DOT_RELOAD_SHELL}" == "1" ]]; then
  dot_trace "Reloading shell ${SHELL}"
  exec "${SHELL}" -l
fi
