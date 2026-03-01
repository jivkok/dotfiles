#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

DOTDIR="$(cd "$(dirname "$0")/../.." && pwd)"
STARTUP_TESTS="$(cd "$(dirname "$0")" && pwd)/helpers/startup-checks.sh"

echo "Test: Bash startup. Dotfiles dir: ${DOTDIR}"
bash -l "${STARTUP_TESTS}"
echo "PASSED: Bash startup."
