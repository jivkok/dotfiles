#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

DOTDIR="$(cd "$(dirname "$0")/../.." && pwd)"
STARTUP_TESTS="$(cd "$(dirname "$0")" && pwd)/helpers/startup-checks.sh"

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

log_trace "Test: ZSH startup. Dotfiles dir: ${DOTDIR}"
zsh -l "${STARTUP_TESTS}"
log_trace "PASSED: ZSH startup."
