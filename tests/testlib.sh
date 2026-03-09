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

log_error() { if _should_log $LOG_LEVEL_ERROR; then echo "$*"; fi }
log_info()  { if _should_log $LOG_LEVEL_INFO;  then echo "$*"; fi }
log_trace() { if _should_log $LOG_LEVEL_TRACE; then echo "$*"; fi }

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
  echo "  ${FAIL_COLOR}FAIL${RESET}: $*" >&2
}
