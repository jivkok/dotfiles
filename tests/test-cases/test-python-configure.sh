#!/usr/bin/env bash
set -euo pipefail

DOTDIR="$(cd "$(dirname "$0")/../.." && pwd)"

# Ensure pipx-installed binaries are on PATH.
# pipx defaults to ~/.local/bin; on macOS brew also links into its prefix.
for _pipx_bin in "$HOME/.local/bin" "$HOME/Library/Python/3.12/bin" "$HOME/Library/Python/3.11/bin"; do
  if [[ -d "$_pipx_bin" ]]; then
    export PATH="${_pipx_bin}:${PATH}"
  fi
done
unset _pipx_bin

# Homebrew prefix (macOS).
for _brew_prefix in /opt/homebrew /usr/local; do
  if [[ -x "${_brew_prefix}/bin/brew" ]]; then
    eval "$("${_brew_prefix}/bin/brew" shellenv)"
    break
  fi
done
unset _brew_prefix

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

# ── Test helpers ───────────────────────────────────────────────────────────────

assert_pipx_package() {
  local pkg="$1"
  if pipx list 2>/dev/null | grep -q "package $pkg"; then
    ok "pipx package installed: $pkg"
  else
    fail "pipx package not installed: $pkg"
  fi
}

# ── Runtime ────────────────────────────────────────────────────────────────────
log_trace "--- configure_python.sh: runtime ---"

assert_cmd python3
assert_cmd pip3 || assert_cmd pip
assert_cmd pipx

# ── Python version ─────────────────────────────────────────────────────────────
log_trace "--- configure_python.sh: python version ---"

python_version=$(python3 --version 2>&1 | sed 's/Python //')
python_major=$(echo "$python_version" | cut -d. -f1)
if [[ "$python_major" -ge 3 ]]; then
  ok "python3 version is acceptable: ${python_version}"
else
  fail "python3 version is too old: ${python_version}"
fi

# ── pipx packages ──────────────────────────────────────────────────────────────
log_trace "--- configure_python.sh: pipx packages ---"

assert_pipx_package glances
assert_pipx_package httpie
assert_pipx_package icdiff

# Verify their binaries are actually reachable on PATH.
assert_cmd glances
assert_cmd http    # httpie installs the 'http' binary
assert_cmd icdiff

# ── Summary ───────────────────────────────────────────────────────────────────
finish_test
