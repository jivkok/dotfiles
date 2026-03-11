#!/usr/bin/env bash
# REQUIRES: dotnet
set -euo pipefail

# dotnet-install.sh places the SDK and global tools under $HOME/.dotnet.
export DOTNET_ROOT="${DOTNET_ROOT:-$HOME/.dotnet}"
export PATH="$DOTNET_ROOT:$DOTNET_ROOT/tools:$PATH"

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

# ── Runtime ────────────────────────────────────────────────────────────────────
log_trace "--- configure_dotnet.sh: runtime ---"

assert_cmd dotnet

# ── dotnet version ─────────────────────────────────────────────────────────────
log_trace "--- configure_dotnet.sh: dotnet version ---"

dotnet_version=$(dotnet --version 2>/dev/null)
dotnet_major=$(echo "$dotnet_version" | cut -d. -f1)
if [[ "$dotnet_major" -ge 6 ]]; then
  ok "dotnet version is acceptable: ${dotnet_version}"
else
  fail "dotnet version is too old (expected >= 6): ${dotnet_version}"
fi

# ── Installation directories ───────────────────────────────────────────────────
log_trace "--- configure_dotnet.sh: installation directories ---"

assert_dir "$DOTNET_ROOT"

# ── Summary ───────────────────────────────────────────────────────────────────
finish_test
