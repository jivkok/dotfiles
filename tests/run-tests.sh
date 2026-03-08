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
# Execution:
#   - Runs selected tests in each environment (local first, then Docker images).
#   - Fails immediately on any test failure.

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
testenv_file="${tests_root}/.testenv"
test_cases_dir="${tests_root}/test-cases"

# ── Argument parsing ───────────────────────────────────────────────────────────

mode="default"   # default | all | filter
filter_cmd=""

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
    *)
      echo "ERROR: unknown argument: $1" >&2
      echo "Usage: $0 [--all | --filter <cmd>]" >&2
      exit 1
      ;;
  esac
done

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
        else
          echo "  SKIPPED: ${name} (requires: ${requires})"
        fi
        ;;
      all)
        selected+=("$f")
        ;;
      filter)
        [[ " ${requires} " == *" ${filter_cmd} "* ]] && selected+=("$f")
        ;;
    esac
  done
  [[ ${#selected[@]} -gt 0 ]] && printf '%s\n' "${selected[@]}"
}

mapfile -t test_files < <(select_tests)

if [[ ${#test_files[@]} -eq 0 ]]; then
  echo "No tests selected."
  exit 0
fi

# ── Runners ────────────────────────────────────────────────────────────────────

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
  bash "${test_file}"
}

run_local() {
  echo
  echo "==> Environment: local"
  for test_file in "${test_files[@]}"; do
    echo
    echo "Test file: ${test_file##*/}"
    run_test "${test_file}"
  done
}

run_in_docker() {
  local image="$1"
  local container_tests="/home/test/dotfiles/tests"
  local container_test_cases="${container_tests}/test-cases"
  echo
  echo "==> Environment: Docker image ${image}"
  for test_file in "${test_files[@]}"; do
    local test_name="${test_file##*/}"
    echo
    echo "Test file: ${test_name}"
    docker run --rm \
      -v "${tests_root}:${container_tests}:ro" \
      "${image}" bash -li "${container_test_cases}/${test_name}"
  done
}

# ── Execute ────────────────────────────────────────────────────────────────────

run_local

if [[ -f "${testenv_file}" ]]; then
  while IFS='=' read -r key value; do
    [[ "$key" =~ _DOCKER_IMAGE$ ]] || continue
    [[ -n "$value" ]] || continue
    run_in_docker "$value"
  done < "${testenv_file}"
fi

echo
echo "==> All tests passed."

