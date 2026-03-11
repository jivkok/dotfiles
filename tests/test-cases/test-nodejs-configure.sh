#!/usr/bin/env bash
# REQUIRES: node
set -euo pipefail

DOTDIR="$(cd "$(dirname "$0")/../.." && pwd)"

# In non-login bash subshells the PATH is minimal. Restore the locations that
# configure_nodejs.sh uses: Homebrew's prefix, the npm global bin dir, and
# /usr/local/bin (used by `n` on Linux).
for _brew_prefix in /opt/homebrew /usr/local; do
  if [[ -x "${_brew_prefix}/bin/brew" ]]; then
    eval "$("${_brew_prefix}/bin/brew" shellenv)"
    break
  fi
done
unset _brew_prefix

npm_global_bin="$(npm prefix -g 2>/dev/null)/bin"
if [[ -d "$npm_global_bin" ]]; then
  export PATH="${npm_global_bin}:${PATH}"
fi
unset npm_global_bin

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

# ── Test helpers ───────────────────────────────────────────────────────────────

assert_node_lts() {
  local version major
  version=$(node --version 2>/dev/null | sed 's/v//')
  major=$(echo "$version" | cut -d. -f1)
  # LTS releases use even-numbered major versions; minimum supported is 18
  if [[ "$major" -ge 18 ]] && [[ $((major % 2)) -eq 0 ]]; then
    ok "node version is LTS: v${version}"
  else
    fail "node version is not LTS (expected even major >= 18): v${version}"
  fi
}

# ── Runtime ────────────────────────────────────────────────────────────────────
log_trace "--- configure_nodejs.sh: runtime ---"

assert_cmd node
assert_cmd npm

# ── Node version ───────────────────────────────────────────────────────────────
# apt packages an old Node, so configure_nodejs.sh upgrades to LTS via `n`.
# Arch (pacman) and macOS (Homebrew) are rolling/current — no LTS pin applied.
log_trace "--- configure_nodejs.sh: node version ---"

if [[ "$(uname -s)" = "Linux" ]] && command -v apt-get >/dev/null 2>&1; then
  assert_node_lts
fi

# ── Global npm package binaries ────────────────────────────────────────────────
log_trace "--- configure_nodejs.sh: global npm package binaries ---"

assert_cmd eslint
assert_cmd http-server
assert_cmd n
assert_cmd nodemon
assert_cmd tsc         # typescript

# ── Summary ───────────────────────────────────────────────────────────────────
finish_test
