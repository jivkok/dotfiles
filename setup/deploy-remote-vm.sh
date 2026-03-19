#!/usr/bin/env bash
# Deploy and run the minimal setup on a remote VM via rsync + SSH.
# Usage: deploy-remote-vm.sh [-p <port>] <user@host>
#
# Assumes SSH access is already configured (key-based, password-less).
# The dotfiles subset is rsynced to ~/dotfiles on the remote, then
# setup-remote-vm.sh is invoked via SSH.

set -euo pipefail

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "${dotdir}/setup/setup_functions.sh"

ssh_port=""

# Parse optional -p <port> before positional argument
while [[ $# -gt 0 ]]; do
  case "$1" in
    -p)
      ssh_port="$2"
      shift 2
      ;;
    *)
      break
      ;;
  esac
done

if [[ $# -lt 1 ]]; then
  dot_error "Usage: deploy-remote-vm.sh [-p <port>] <user@host>"
  exit 1
fi

remote_target="$1"
# Remote path: tilde is intentional — rsync and SSH expand it on the remote.
# shellcheck disable=SC2088
remote_dotfiles_dir="~/dotfiles"

# Build SSH and rsync extra options for non-default ports
ssh_opts=(-o StrictHostKeyChecking=no)
rsync_ssh_opts="ssh -o StrictHostKeyChecking=no"
if [[ -n "${ssh_port}" ]]; then
  ssh_opts+=(-p "${ssh_port}")
  rsync_ssh_opts="ssh -p ${ssh_port} -o StrictHostKeyChecking=no"
fi

dot_trace "Deploying minimal dotfiles to ${remote_target} ..."

# Rsync only the minimal-relevant subset of the dotfiles repo.
# Trailing slash on source means "contents of", not "directory itself".
# The destination uses ~ which rsync resolves on the remote host.
# shellcheck disable=SC2088
rsync -az --delete \
  -e "${rsync_ssh_opts}" \
  --include="bash/" \
  --include="bash/.bash_profile" \
  --include="bash/.bashrc" \
  --include="bash/setenv.sh" \
  --include="bash/completion.sh" \
  --include="bash/options.sh" \
  --include="bash/prompt.sh" \
  --exclude="bash/starship.toml" \
  --exclude="bash/*" \
  --include="bin/" \
  --include="bin/tmux-status-ip.sh" \
  --exclude="bin/*" \
  --include="linux/" \
  --include="linux/configure_packages_minimal_debian.sh" \
  --include="linux/configure_packages_minimal_arch.sh" \
  --exclude="linux/*" \
  --include="misc/" \
  --include="misc/.*" \
  --exclude="misc/*" \
  --include="setup/" \
  --include="setup/setup-remote-vm.sh" \
  --include="setup/setup_functions.sh" \
  --include="setup/configure_home_symlinks.sh" \
  --include="setup/configure_locale.sh" \
  --exclude="setup/*" \
  --include="sh/" \
  --include="sh/**" \
  --include="tmux/" \
  --include="tmux/**" \
  --exclude="*" \
  "${dotdir}/" "${remote_target}:${remote_dotfiles_dir}"

dot_trace "Dotfiles rsynced. Running setup-remote-vm.sh on ${remote_target} ..."

# shellcheck disable=SC2029  # Intentional: remote_dotfiles_dir with ~ expands on the remote
ssh -t "${ssh_opts[@]}" "${remote_target}" "DOT_RELOAD_SHELL=0 bash ${remote_dotfiles_dir}/setup/setup-remote-vm.sh"

dot_trace "Minimal setup complete on ${remote_target}."
