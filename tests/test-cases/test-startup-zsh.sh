#!/usr/bin/env bash
# COVERS: setup/*.sh sh/*.sh fzf/configure_fzf.sh git/configure_git.sh nodejs/configure_nodejs.sh python/configure_python.sh tmux/configure_tmux.sh tmux/osc52.sh vim/configure_vim.sh linux/configure_packages_debian.sh linux/configure_packages_arch.sh osx/configure_osx.sh osx/configure_osx_packages.sh osx/setenv.sh zsh/*.sh
set -euo pipefail
IFS=$'\n\t'

DOTDIR="$(cd "$(dirname "$0")/../.." && pwd)"
STARTUP_TESTS="$(cd "$(dirname "$0")" && pwd)/helpers/startup-checks.sh"

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

log_trace "Test: ZSH startup. Dotfiles dir: ${DOTDIR}"
zsh -l "${STARTUP_TESTS}"
log_trace "PASSED: ZSH startup."
