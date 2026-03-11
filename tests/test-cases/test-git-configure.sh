#!/usr/bin/env bash
# REQUIRES: git
set -euo pipefail

DOTDIR="$(cd "$(dirname "$0")/../.." && pwd)"

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

# ── Test helpers ───────────────────────────────────────────────────────────────

assert_git_cfg() {
  local key="$1" expected="$2"
  local actual
  actual=$(git config --global --get "$key" 2>/dev/null || true)
  if [[ "$actual" == "$expected" ]]; then
    ok "git config $key = $expected"
  else
    fail "git config $key: expected '$expected', got '$actual'"
  fi
}

assert_git_cfg_set() {
  local key="$1"
  if git config --global --get "$key" >/dev/null 2>&1; then
    ok "git config $key is set"
  else
    fail "git config $key is not set"
  fi
}

# ── Isolated environment ───────────────────────────────────────────────────────
# Run configure_git.sh with a temp HOME and GIT_CONFIG_GLOBAL so the real
# git config and ~/.gitignore.global are not touched.

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

export HOME="$tmpdir"
export GIT_CONFIG_GLOBAL="$tmpdir/.gitconfig"

# Suppress tput errors in non-terminal environments
export TERM="${TERM:-dumb}"

bash "$DOTDIR/git/configure_git.sh" >/dev/null 2>&1

# ── Core settings ──────────────────────────────────────────────────────────────
log_trace "---configure_git.sh: core settings ---"

assert_git_cfg "core.autocrlf"    "input"
assert_git_cfg "core.fscache"     "true"
assert_git_cfg "core.preloadindex" "true"
assert_git_cfg "core.safecrlf"    "true"
assert_git_cfg "help.format"      "html"
assert_git_cfg "push.default"     "current"
assert_git_cfg "rebase.autosquash" "true"

# ── Global gitignore ───────────────────────────────────────────────────────────
log_trace "---configure_git.sh: global gitignore ---"

assert_file_exists "$tmpdir/.gitignore.global"
assert_file_content "$tmpdir/.gitignore.global" ".DS_Store"
assert_file_content "$tmpdir/.gitignore.global" "*.swp"
assert_git_cfg "core.excludesfile" "$tmpdir/.gitignore.global"

# ── Colors ────────────────────────────────────────────────────────────────────
log_trace "---configure_git.sh: color settings ---"

assert_git_cfg "color.ui"          "true"
assert_git_cfg "color.status.new"  "red bold"
assert_git_cfg "color.status.added" "green bold"
assert_git_cfg "color.diff.old"    "red bold"
assert_git_cfg "color.diff.new"    "green bold"

# ── Aliases ───────────────────────────────────────────────────────────────────
log_trace "---configure_git.sh: aliases ---"

assert_git_cfg "alias.st"       "status -sb"
assert_git_cfg "alias.co"       "checkout"
assert_git_cfg "alias.cm"       "commit -m"
assert_git_cfg "alias.br"       "branch"
assert_git_cfg "alias.a"        "add -A"
assert_git_cfg "alias.amend"    "commit --amend -C HEAD"
assert_git_cfg "alias.pp"       "pull --prune"
assert_git_cfg "alias.zap"      "reset --hard HEAD"
assert_git_cfg "alias.uncommit" "reset --soft HEAD~"
assert_git_cfg "alias.unstage"  "reset HEAD --"
assert_git_cfg_set "alias.hist"
assert_git_cfg_set "alias.lg"

# ── Summary ───────────────────────────────────────────────────────────────────
finish_test
