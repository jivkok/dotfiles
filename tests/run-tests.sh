#!/usr/bin/env bash
set -euo pipefail

# Test runner.
#
# Environments:
#   - Always runs tests locally.
#   - Reads tests/.testenv to discover Docker environments: any variable matching
#     *_DOCKER_IMAGE with a non-empty value points to a built Docker image to test in.
#
# Test discovery:
#   - Tests are files matching tests/test-cases/test-*.sh.
#
# Test filtering (REQUIRES header):
#   - A test may declare at the top: # REQUIRES: cmd1 cmd2
#   - Default: tests whose required commands are not installed are skipped.
#   - --all: run all tests regardless; fail if a required command is missing.
#   - --filter <cmd>: run only tests that list <cmd> in their REQUIRES header.
#
# Log levels (--log-level <error|info|trace>, default: info):
#   See tests/testlib.sh for the full log-level model.
#
# Execution:
#   - Runs all selected tests in each environment (local first, then Docker images).
#   - Reports pass/fail counts; exits non-zero if any test fails.

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
testenv_file="${tests_root}/.testenv"
test_cases_dir="${tests_root}/test-cases"

# ── Argument parsing ───────────────────────────────────────────────────────────

mode="default"   # default | all | filter
filter_cmd=""
log_level_flag=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      mode="all"
      shift
      ;;
    --filter)
      [[ -n "${2:-}" ]] || { echo "ERROR: --filter requires a command name" >&2; exit 1; }
      mode="filter"
      filter_cmd="$2"
      shift 2
      ;;
    --log-level)
      [[ -n "${2:-}" ]] || { echo "ERROR: --log-level requires a value" >&2; exit 1; }
      log_level_flag="${2,,}"
      shift 2
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      echo "Usage: $0 [--all | --filter <cmd>] [--log-level <error|info|trace>]" >&2
      exit 1
      ;;
  esac
done

# ── LOG_LEVEL resolution ───────────────────────────────────────────────────────
# Precedence: CLI flag > LOG_LEVEL env var > default (info)

if [[ -n "$log_level_flag" ]]; then
  LOG_LEVEL="$log_level_flag"
elif [[ -n "${LOG_LEVEL:-}" ]]; then
  LOG_LEVEL="${LOG_LEVEL,,}"
else
  LOG_LEVEL="info"
fi

# ── Logging setup ──────────────────────────────────────────────────────────────
# shellcheck source=testlib.sh
source "${tests_root}/testlib.sh"

if [[ $_ACTIVE_LOG_LEVEL -eq -1 ]]; then
  echo "ERROR: invalid --log-level value: '${LOG_LEVEL}'. Valid values: error, info, trace." >&2
  echo "Usage: $0 [--all | --filter <cmd>] [--log-level <error|info|trace>]" >&2
  exit 1
fi

export LOG_LEVEL

# ── Test discovery ─────────────────────────────────────────────────────────────

mapfile -t all_test_files < <(find "${test_cases_dir}" -name 'test-*.sh' | sort)

if [[ ${#all_test_files[@]} -eq 0 ]]; then
  echo "No test files found in ${test_cases_dir}."
  exit 0
fi

# ── REQUIRES helpers ───────────────────────────────────────────────────────────

# Extract the space-separated command list from a test file's # REQUIRES: line.
get_requires() {
  grep -m1 '^# REQUIRES:' "$1" 2>/dev/null | sed 's/^# REQUIRES: *//' || true
}

# Return 0 if every command in the file's REQUIRES list is present in PATH.
requires_met() {
  local requires
  requires=$(get_requires "$1")
  [[ -z "$requires" ]] && return 0
  for cmd in $requires; do
    command -v "$cmd" >/dev/null 2>&1 || return 1
  done
}

# ── Test selection ─────────────────────────────────────────────────────────────

select_tests() {
  local -a selected=()
  for f in "${all_test_files[@]}"; do
    local name="${f##*/}"
    local requires
    requires=$(get_requires "$f")

    case "$mode" in
      default)
        if requires_met "$f"; then
          selected+=("$f")
        elif _should_log $LOG_LEVEL_INFO; then
          echo "  SKIPPED: ${name} (requires: ${requires})" >&2
        fi
        ;;
      all)
        selected+=("$f")
        ;;
      filter)
        if [[ " ${requires} " == *" ${filter_cmd} "* ]]; then selected+=("$f"); fi
        ;;
    esac
  done
  if [[ ${#selected[@]} -gt 0 ]]; then printf '%s\n' "${selected[@]}"; fi
}

mapfile -t test_files < <(select_tests)

if [[ ${#test_files[@]} -eq 0 ]]; then
  log_info "No tests selected."
  exit 0
fi

# ── Pass/fail tracking ─────────────────────────────────────────────────────────

_total_pass=0
_total_fail=0

# ── Runners ────────────────────────────────────────────────────────────────────

# Record result and print runner-level PASSED/FAILED indicator (info-level).
_record_result() {
  local exit_code=$1
  if [[ $exit_code -eq 0 ]]; then
    _total_pass=$((_total_pass + 1))
    log_info "  ${SUCCESS_COLOR}PASSED${RESET}"
  else
    _total_fail=$((_total_fail + 1))
    log_info "  ${FAIL_COLOR}FAILED${RESET}"
  fi
}

run_test() {
  local test_file="$1"
  local name="${test_file##*/}"

  if [[ "$mode" == "all" ]]; then
    local requires missing=()
    requires=$(get_requires "$test_file")
    for cmd in $requires; do
      command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
      echo "  ERROR: ${name} requires missing commands: ${missing[*]}" >&2
      return 1
    fi
  fi

  if _should_log $LOG_LEVEL_TRACE; then
    # Trace: output flows through directly (preserves TTY for subprocess color detection).
    local exit_code=0
    bash "${test_file}" || exit_code=$?
    return $exit_code
  fi

  # Info / error: capture and filter output.
  local output exit_code=0
  output=$(bash "${test_file}" 2>&1) || exit_code=$?

  # FAIL lines are error-level; visible at info and above (info >= error).
  if [[ $exit_code -ne 0 ]]; then
    grep '  FAIL:' <<< "$output" || true
  fi

  return $exit_code
}

run_local() {
  log_info ""
  log_info "==> Environment: local"

  for test_file in "${test_files[@]}"; do
    local name="${test_file##*/}"
    log_info ""
    log_info "Test file: ${name}"

    local test_exit=0
    run_test "${test_file}" || test_exit=$?
    _record_result "$test_exit"
  done
}

run_in_docker() {
  local image="$1"
  shift
  local -a files=("$@")
  local container_tests="/home/test/dotfiles/tests"
  local container_test_cases="${container_tests}/test-cases"

  log_info ""
  log_info "==> Environment: Docker image ${image}"

  for test_file in "${files[@]}"; do
    local test_name="${test_file##*/}"
    log_info ""
    log_info "Test file: ${test_name}"

    # Check REQUIRES inside the container; skip if any command is missing.
    local requires
    requires=$(get_requires "$test_file")
    if [[ -n "$requires" ]]; then
      local check_cmd="command -v ${requires// / && command -v }"
      if ! docker run --rm "${image}" bash -li -c "$check_cmd" >/dev/null 2>&1; then
        log_info "  SKIPPED (requires: ${requires})"
        continue
      fi
    fi

    local test_exit=0

    if _should_log $LOG_LEVEL_TRACE; then
      # Trace: Docker output flows through including preamble.
      docker run --rm \
        -e LOG_LEVEL \
        -v "${tests_root}:${container_tests}:ro" \
        "${image}" bash -li "${container_test_cases}/${test_name}" || test_exit=$?
    else
      local docker_output
      docker_output=$(docker run --rm \
        -e LOG_LEVEL \
        -v "${tests_root}:${container_tests}:ro" \
        "${image}" bash -li "${container_test_cases}/${test_name}" 2>&1) || test_exit=$?

      # FAIL lines are error-level; visible at info and above.
      if [[ $test_exit -ne 0 ]]; then
        grep '  FAIL:' <<< "$docker_output" || true
      fi
    fi

    _record_result "$test_exit"
  done
}

# ── Execute ────────────────────────────────────────────────────────────────────

run_local

if [[ -f "${testenv_file}" ]]; then
  # In default mode, Docker evaluates its own REQUIRES per container, so pass
  # all discovered tests. In filter/all modes the selection is already correct.
  _docker_files=("${all_test_files[@]}")
  if [[ "$mode" != "default" ]]; then
    _docker_files=("${test_files[@]}")
  fi

  while IFS='=' read -r key value; do
    [[ "$key" =~ _DOCKER_IMAGE$ ]] || continue
    [[ -n "$value" ]] || continue
    run_in_docker "$value" "${_docker_files[@]}"
  done < "${testenv_file}"
fi

# ── Final summary ──────────────────────────────────────────────────────────────

if [[ "${_total_fail}" -gt 0 ]]; then
  log_info ""
  log_info "Passed: ${_total_pass}, Failed: ${_total_fail}"
  log_error "${FAIL_COLOR}==> Some tests FAILED.${RESET}"
  exit 1
else
  log_info ""
  log_info "Passed: ${_total_pass}, Failed: ${_total_fail}"
  log_info "${SUCCESS_COLOR}==> All tests passed.${RESET}"
fi
