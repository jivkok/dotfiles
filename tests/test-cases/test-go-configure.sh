#!/usr/bin/env bash
# REQUIRES: go
set -euo pipefail

# Ensure GOPATH/bin is on PATH so go-installed tools are reachable.
GOPATH="${GOPATH:-$HOME/go}"
export GOPATH
export PATH="$GOPATH/bin:$PATH"

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

# ── Runtime ────────────────────────────────────────────────────────────────────
log_trace "--- configure_go.sh: runtime ---"

assert_cmd go

# ── Go version ─────────────────────────────────────────────────────────────────
log_trace "--- configure_go.sh: go version ---"

go_version=$(go version 2>/dev/null | sed 's/go version go//' | cut -d' ' -f1)
go_major=$(echo "$go_version" | cut -d. -f1)
go_minor=$(echo "$go_version" | cut -d. -f2)
if [[ "$go_major" -gt 1 ]] || { [[ "$go_major" -eq 1 ]] && [[ "$go_minor" -ge 18 ]]; }; then
  ok "go version is acceptable: ${go_version}"
else
  fail "go version is too old (expected >= 1.18): ${go_version}"
fi

# ── GOPATH directories ─────────────────────────────────────────────────────────
log_trace "--- configure_go.sh: GOPATH directories ---"

assert_dir "$GOPATH"
assert_dir "$GOPATH/src"
assert_dir "$GOPATH/pkg"
assert_dir "$GOPATH/bin"

# ── Go tools ──────────────────────────────────────────────────────────────────
log_trace "--- configure_go.sh: go tools ---"

assert_cmd gopls
assert_cmd staticcheck
assert_cmd goimports

# ── Summary ───────────────────────────────────────────────────────────────────
finish_test
