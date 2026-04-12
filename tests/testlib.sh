# shellcheck shell=bash
# Shared test library for the test suite.
#
# Source this file AFTER LOG_LEVEL has been set (or leave unset for the default).
# Compatible with both bash and zsh (sourced by startup-checks.sh via zsh -l).
#
# Provides:
#   FAIL_COLOR SUCCESS_COLOR RESET  — ANSI escape codes; empty when colors are disabled.
#   LOG_LEVEL_ERROR=0               — numeric level constants (error < info < trace).
#   LOG_LEVEL_INFO=1
#   LOG_LEVEL_TRACE=2
#   _ACTIVE_LOG_LEVEL               — resolved numeric level; -1 when LOG_LEVEL is invalid.
#   _TEST_PASS / _TEST_FAIL         — pass/fail counters, reset to 0 on each source.
#
# Functions:
#   log_error <msg>    — print msg when active level >= error (always, except invalid level).
#   log_info  <msg>    — print msg when active level >= info.
#   log_trace <msg>    — print msg when active level >= trace.
#   _should_log <N>    — returns 0 (true) when N <= _ACTIVE_LOG_LEVEL; use for conditional
#                        blocks that do more than print a single message.
#   ok   <msg>         — record a passing assertion; prints via log_trace.
#   fail <msg>         — record a failing assertion; always prints to stderr.

# ── Colors ─────────────────────────────────────────────────────────────────────
# Disabled when stdout is not a TTY or NO_COLOR is set (any non-empty value).

if [ -z "${NO_COLOR:-}" ] && [ -t 1 ]; then
  FAIL_COLOR=$'\033[31m'
  SUCCESS_COLOR=$'\033[32m'
  RESET=$'\033[0m'
else
  FAIL_COLOR='' SUCCESS_COLOR='' RESET=''
fi

# ── Level constants ────────────────────────────────────────────────────────────
# Ordered enumeration: error=0 < info=1 < trace=2.
# A message at level N is emitted when _ACTIVE_LOG_LEVEL >= N.
#
# What appears at each level:
#   error — FAIL lines and final failure summary only.
#   info  — + environment headers, test file names, PASSED/FAILED per file, counts.
#   trace — + individual OK lines, Docker preamble, all subprocess detail.

LOG_LEVEL_ERROR=0
LOG_LEVEL_INFO=1
LOG_LEVEL_TRACE=2

# ── Active level ───────────────────────────────────────────────────────────────

_resolve_log_level() {
  # Use tr for lowercasing: ${var,,} is bash-only and breaks when sourced by zsh.
  local level
  level=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
  case "$level" in
    error) printf '%s' 0 ;;
    info)  printf '%s' 1 ;;
    trace) printf '%s' 2 ;;
    *)     printf '%s' -1 ;;
  esac
}

_ACTIVE_LOG_LEVEL=$(_resolve_log_level "${LOG_LEVEL:-info}")

# ── Predicate ──────────────────────────────────────────────────────────────────

# Returns 0 (true) if N <= _ACTIVE_LOG_LEVEL.  Use this for conditional blocks
# that do more than emit a single message; for simple output use log_error/info/trace.
_should_log() {
  [ "$_ACTIVE_LOG_LEVEL" -ge "$1" ]
}

# ── Logging functions ──────────────────────────────────────────────────────────

log_error() { if _should_log $LOG_LEVEL_ERROR; then echo "[$(date '+%H:%M:%S')] $*"; fi }
log_info()  { if _should_log $LOG_LEVEL_INFO;  then echo "[$(date '+%H:%M:%S')] $*"; fi }
log_trace() { if _should_log $LOG_LEVEL_TRACE; then echo "[$(date '+%H:%M:%S')] $*"; fi }

# ── Assertion helpers ──────────────────────────────────────────────────────────

_TEST_PASS=0
_TEST_FAIL=0

# Record a passing assertion.  Prints the message at trace level only.
ok() {
  _TEST_PASS=$((_TEST_PASS + 1))
  log_trace "  ${SUCCESS_COLOR}OK  ${RESET}: $*"
}

# Record a failing assertion.  Always prints to stderr.
fail() {
  _TEST_FAIL=$((_TEST_FAIL + 1))
  echo "[$(date '+%H:%M:%S')]   ${FAIL_COLOR}FAIL${RESET}: $*" >&2
}

# ── Common test assertions ──────────────────────────────────────────────────────
#
# These are available to all test files without redefinition.

# assert_cmd <cmd>  — pass if cmd is on PATH.
assert_cmd() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    ok "command available: $cmd"
  else
    fail "command not found: $cmd"
  fi
}

# assert_dir <dir>  — pass if dir exists.
assert_dir() {
  local dir="$1"
  if [ -d "$dir" ]; then
    ok "directory exists: $dir"
  else
    fail "directory not found: $dir"
  fi
}

# assert_file_exists <file>  — pass if file exists.
assert_file_exists() { [ -f "$1" ] && ok "file exists: ${1##*/}" || fail "file missing: $1"; }

# assert_file_absent <file>  — pass if file does not exist.
assert_file_absent()  { [ ! -f "$1" ] && ok "file absent: ${1##*/}" || fail "file should not exist: $1"; }

# assert_file_content <file> <string>  — pass if file contains string (fixed).
assert_file_content() {
  grep -qF "$2" "$1" 2>/dev/null \
    && ok "content present in ${1##*/}: $2" \
    || fail "content missing '$2' in $1"
}

# assert_eq <label> <expected> <actual>  — pass if expected == actual.
assert_eq() {
  local label="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    ok "$label"
  else
    fail "$label (expected: '$expected', got: '$actual')"
  fi
}

# finish_test  — print summary and exit 1 if any assertions failed.
finish_test() {
  log_trace ""
  log_trace "Passed: ${_TEST_PASS}, Failed: ${_TEST_FAIL}"
  if [ "${_TEST_FAIL}" -gt 0 ]; then
    log_error "==> FAILED."
    exit 1
  fi
  log_trace "==> PASSED."
}
