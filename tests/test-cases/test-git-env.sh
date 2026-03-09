#!/usr/bin/env bash
# REQUIRES: git
set -euo pipefail

DOTDIR="$(cd "$(dirname "$0")/../.." && pwd)"

# ── Test helpers ───────────────────────────────────────────────────────────────
_pass=0
_fail=0

ok()   { echo "  OK  : $*"; _pass=$(( _pass + 1 )); }
fail() { echo "  FAIL: $*" >&2; _fail=$(( _fail + 1 )); }

assert_alias() {
  local name="$1" expected="$2"
  local actual
  actual=$(alias "$name" 2>/dev/null | sed "s/^alias ${name}='//;s/'$//") || true
  if [[ "$actual" == "$expected" ]]; then
    ok "alias $name='$expected'"
  else
    fail "alias $name: expected '$expected', got '$actual'"
  fi
}

assert_function() {
  local name="$1"
  if declare -f "$name" >/dev/null 2>&1; then
    ok "function $name defined"
  else
    fail "function $name not defined"
  fi
}

# ── Source git.sh ─────────────────────────────────────────────────────────────
# Enable alias expansion so aliases are testable in a non-interactive shell.
shopt -s expand_aliases

# git.sh expects $dotdir to NOT be set (it uses source paths directly); it
# does not use $dotdir. Source it directly.
# shellcheck source=../../git/git.sh
source "$DOTDIR/git/git.sh"

# ── Aliases ───────────────────────────────────────────────────────────────────
echo "--- git.sh: aliases ---"

assert_alias "g"  "git"
assert_alias "lg" "lazygit"

# ── Functions ─────────────────────────────────────────────────────────────────
echo "--- git.sh: functions ---"

assert_function "git_pull_all"
assert_function "git_pull_submodules"
assert_function "git-fzf-checkout-branch"
assert_function "git-fzf-checkout-tag"
assert_function "git-fzf-checkout-branch-or-tag"
assert_function "git-fzf-checkout-commit"
assert_function "git-fzf-commits"
assert_function "git-fzf-sha"
assert_function "git-fzf-stashes"
assert_function "git-fzf-status"
assert_function "git-fzf-tags"
assert_function "gitf"

# ── git_pull_all: no-op on dir without .git ────────────────────────────────────
echo "--- git.sh: git_pull_all behaviour ---"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# Directory with no git repos: function should complete without error
git_pull_all "$tmpdir"
ok "git_pull_all runs cleanly on empty directory"

# ── git_pull_submodules: exits cleanly when no .gitmodules ────────────────────
echo "--- git.sh: git_pull_submodules behaviour ---"

output=$(git_pull_submodules "$tmpdir" 2>&1)
if [[ "$output" == *"No submodules found"* ]]; then
  ok "git_pull_submodules reports no submodules"
else
  fail "git_pull_submodules unexpected output: $output"
fi

# ── gitf: usage message on unknown subcommand ─────────────────────────────────
echo "--- git.sh: gitf dispatch ---"

gitf_out=$(gitf "unknown-subcommand" 2>&1 || true)
if [[ "$gitf_out" == *"Usage:"* ]]; then
  ok "gitf prints usage for unknown subcommand"
else
  fail "gitf did not print usage for unknown subcommand: $gitf_out"
fi

gitf_out=$(gitf "checkout" "unknown" 2>&1 || true)
if [[ "$gitf_out" == *"Usage:"* ]]; then
  ok "gitf checkout prints usage for unknown target"
else
  fail "gitf checkout did not print usage: $gitf_out"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
echo
echo "Passed: ${_pass}, Failed: ${_fail}"
if [[ "${_fail}" -gt 0 ]]; then
  echo "==> FAILED."
  exit 1
fi
echo "==> PASSED."
