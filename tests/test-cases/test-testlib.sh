#!/usr/bin/env bash
# COVERS: tests/testlib.sh
# Tests for the shared test library's own assertion helpers.
set -euo pipefail

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# outcome <cmd...>  — run an assertion in a subshell; print "<passes> <fails>".
outcome() {
  ( _TEST_PASS=0 _TEST_FAIL=0; "$@" >/dev/null 2>&1; echo "${_TEST_PASS} ${_TEST_FAIL}" )
}

log_trace "--- check / check_not: pass/fail ---"
assert_eq "check: succeeding cmd passes" "1 0" "$(outcome check "t" true)"
assert_eq "check: failing cmd fails" "0 1" "$(outcome check "t" false)"
assert_eq "check_not: failing cmd passes" "1 0" "$(outcome check_not "t" false)"
assert_eq "check_not: succeeding cmd fails" "0 1" "$(outcome check_not "t" true)"

log_trace "--- check: output shown only on failure ---"
noisy_fail() { echo "why-it-failed"; return 1; }
out="$( (check "lbl" noisy_fail) 2>&1 )"
assert_contains "check: failure shows the command's output" "why-it-failed" "$out"
out="$( (_ACTIVE_LOG_LEVEL=2; check "lbl" echo hidden-output) 2>&1 )"
assert_not_contains "check: success hides the command's output" "hidden-output" "$out"

log_trace "--- check: runs in the current shell ---"
set_side_effects() { SIDE_VAR="set"; cd "$tmpdir"; }
SIDE_VAR=""
start_dir="$PWD"
check "side-effect function succeeds" set_side_effects
assert_eq "check: variable set by the command persists" "set" "$SIDE_VAR"
assert_eq "check: cd by the command persists" "$tmpdir" "$PWD"
cd "$start_dir"

# A background job holding stdout open must not block the check (a $(...)
# capture would wait for it to exit).
start_bg() { sleep 5 & BG_PID=$!; }
SECONDS=0
check "background-job function succeeds" start_bg
assert_eq "check: background job's pid persists" "1" "$([ -n "${BG_PID:-}" ] && echo 1)"
assert_eq "check: does not wait for a background job" "1" "$((SECONDS < 3))"
kill "$BG_PID" 2>/dev/null || true

# The command's own out/rc globals (testlib convention) aren't shadowed.
out="stale" rc="stale"
check "run_capture under check" run_capture sh -c 'echo fresh; exit 3'
assert_eq "check: command's \$out reaches the caller" "fresh" "$out"
assert_eq "check: command's \$rc reaches the caller" "3" "$rc"

log_trace "--- check: reads the caller's stdin ---"
check "check: stdin reaches the command" grep -qx data <<< "data"
check_not "check_not: stdin reaches the command" grep -qx other <<< "data"

finish_test
