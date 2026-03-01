#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

DOTDIR="$(cd "$(dirname "$0")/../.." && pwd)"
STARTUP_TESTS="$(cd "$(dirname "$0")" && pwd)/helpers/startup-checks.sh"

echo "Test: ZSH startup. Dotfiles dir: ${DOTDIR}"
zsh -l "${STARTUP_TESTS}"
echo "PASSED: ZSH startup."
