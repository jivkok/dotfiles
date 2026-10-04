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
# Change-based selection (COVERS header, see tests/coverage-lib.sh):
#   - --changed [<ref>]: run only tests relevant to files changed vs HEAD (staged,
#     unstaged, untracked) or, with <ref>, vs <ref>... plus the working tree.
#     Combines with the flags above. Exports CHANGED_FILES (newline-separated,
#     existing paths only) to tests. Rules are documented in docs/testing.md.
#   - --list: print the selected tests and their COVERS value; run nothing.
#   - CHANGED_FILES_OVERRIDE (testing only): newline-separated `<status>\t<path>`
#     (or bare `<path>`, status M) used instead of asking git.
#
# Log levels (--log-level <error|info|trace>, default: info):
#   See tests/testlib.sh for the full log-level model.
#
# Execution:
#   - Runs all selected tests in each environment (local first, then Docker images).
#   - Docker containers get the working-tree repo mounted read-only over the
#     image's baked copy, so scripts under test are always current.
#   - Reports pass/fail counts; exits non-zero if any test fails.

# Tests must never be able to reach the invoking shell's real tmux session.
# `tmux` prefers `$TMUX` (a live session reference) over `$TMUX_TMPDIR` when
# already inside a session, so a test that sets TMUX_TMPDIR to sandbox its own
# tmux server is NOT isolated unless TMUX (and TMUX_PANE) is also stripped --
# otherwise, run from inside a real tmux pane, its tmux calls silently target
# the real server instead of its private one.
unset TMUX TMUX_PANE

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${tests_root}/.." && pwd)"
testenv_file="${tests_root}/.testenv"
test_cases_dir="${tests_root}/test-cases"

# ── Argument parsing ───────────────────────────────────────────────────────────

mode="default"   # default | all | filter
filter_cmd=""
log_level_flag=""
changed=0
changed_ref=""
list_only=0

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
    --changed)
      changed=1
      if [[ -n "${2:-}" && "${2:-}" != --* ]]; then
        changed_ref="$2"
        shift
      fi
      shift
      ;;
    --list)
      list_only=1
      shift
      ;;
    --log-level)
      [[ -n "${2:-}" ]] || { echo "ERROR: --log-level requires a value" >&2; exit 1; }
      log_level_flag="${2,,}"
      shift 2
      ;;
    *)
      echo "ERROR: unknown argument: $1" >&2
      echo "Usage: $0 [--all | --filter <cmd>] [--changed [<ref>]] [--list] [--log-level <error|info|trace>]" >&2
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
# shellcheck source=coverage-lib.sh
source "${tests_root}/coverage-lib.sh"

if [[ $_ACTIVE_LOG_LEVEL -eq -1 ]]; then
  echo "ERROR: invalid --log-level value: '${LOG_LEVEL}'. Valid values: error, info, trace." >&2
  echo "Usage: $0 [--all | --filter <cmd>] [--changed [<ref>]] [--list] [--log-level <error|info|trace>]" >&2
  exit 1
fi

export LOG_LEVEL

# ── Test discovery ─────────────────────────────────────────────────────────────

mapfile -t all_test_files < <(find "${test_cases_dir}" -name 'test-*.sh' | sort)

if [[ ${#all_test_files[@]} -eq 0 ]]; then
  log_info "No test files found in ${test_cases_dir}."
  exit 0
fi

# ── Change-based selection (--changed) ─────────────────────────────────────────

# Print `<status>\t<path>` for each changed file. Renames are split into a
# delete of the old path and an add of the new one.
collect_changes() {
  if [[ -n "${CHANGED_FILES_OVERRIDE:-}" ]]; then
    local line
    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      if [[ "$line" == *$'\t'* ]]; then printf '%s\n' "$line"; else printf 'M\t%s\n' "$line"; fi
    done <<< "$CHANGED_FILES_OVERRIDE"
    return 0
  fi

  if ! git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ERROR: --changed requires a git work tree (${repo_root} is not one)" >&2
    return 1
  fi
  if [[ -n "$changed_ref" ]] \
    && ! git -C "$repo_root" rev-parse --verify --quiet "${changed_ref}^{commit}" >/dev/null; then
    echo "ERROR: --changed: unknown git ref '${changed_ref}'" >&2
    return 1
  fi

  {
    git -C "$repo_root" diff --name-status -M HEAD
    if [[ -n "$changed_ref" ]]; then
      git -C "$repo_root" diff --name-status -M "${changed_ref}...HEAD"
    fi
    git -C "$repo_root" ls-files --others --exclude-standard | sed 's/^/A\t/'
  } | awk -F'\t' '
    $1 ~ /^R/ { print "D\t" $2; print "A\t" $3; next }
    $1 ~ /^C/ { print "A\t" $3; next }
    { print substr($1, 1, 1) "\t" $2 }
  ' | sort -u
}

# Header values per test file, parsed once (pure bash; see coverage-lib.sh).
declare -A test_covers=() test_meta=()
for f in "${all_test_files[@]}"; do
  test_covers[$f]="$(cov_get_header "$f" COVERS)"
  cov_is_meta "$f" && test_meta[$f]=1
done

# Narrows candidate_files to the tests selected by the changed-file list,
# applying the selection rules documented in docs/testing.md (rules A–H).
select_changed() {
  local changes
  changes="$(collect_changes)" || exit 1

  local -A picked=() is_setup=()
  local -a exclude_globs=() globs=()
  local f s full=0 status path covered glob _reason
  while IFS= read -r s; do is_setup[$s]=1; done < <(bash "${tests_root}/create-test-envs.sh" --print-setup-files)
  while IFS=$'\t' read -r glob _reason; do exclude_globs+=("$glob"); done < <(cov_exclude_lines "${tests_root}/coverage-exclude")
  local coverage_map_test="${test_cases_dir}/test-coverage-map.sh"

  CHANGED_FILES=""
  while IFS=$'\t' read -r status path; do
    [[ -z "$path" ]] && continue
    [[ "$status" != "D" ]] && CHANGED_FILES+="${path}"$'\n'
    # Rule H: added/deleted/renamed files can invalidate the coverage map.
    [[ "$status" == "A" || "$status" == "D" ]] && picked[$coverage_map_test]=1

    case "$path" in
      tests/testlib.sh | tests/run-tests.sh | tests/create-test-envs.sh | tests/coverage-lib.sh | tests/docker/*)
        full=1 ;;                                                     # Rule B
      tests/test-cases/helpers/*)                                     # Rule C
        for f in "${all_test_files[@]}"; do
          grep -qF "${path#tests/test-cases/}" "$f" && picked[$f]=1
        done
        ;;
      tests/test-cases/test-*.sh)                                     # Rule A
        [[ -f "${repo_root}/${path}" ]] && picked[${repo_root}/${path}]=1 ;;
      *)
        if [[ -n "${is_setup[$path]:-}" ]]; then full=1; continue; fi # Rule D
        covered=0
        for f in "${all_test_files[@]}"; do                           # Rule G
          read -r -a globs <<< "${test_covers[$f]}"
          if cov_path_matches_any "$path" "${globs[@]}"; then
            picked[$f]=1
            [[ -n "${test_meta[$f]:-}" ]] || covered=1
          fi
        done
        if cov_is_script "$path" && (( ! covered )) && ! cov_path_matches_any "$path" "${exclude_globs[@]}"; then
          echo "WARN: unmapped script changed: ${path} (running full suite)" >&2   # Rule E
          full=1
        fi
        ;;                                                            # Rule F: others select nothing
    esac
  done <<< "$changes"
  export CHANGED_FILES

  candidate_files=()
  for f in "${all_test_files[@]}"; do
    if (( full )) || [[ -n "${picked[$f]:-}" ]]; then candidate_files+=("$f"); fi
  done
}

candidate_files=("${all_test_files[@]}")
if (( changed )); then select_changed; fi

# ── REQUIRES helpers ───────────────────────────────────────────────────────────

# The space-separated command list from a test file's # REQUIRES: header.
get_requires() { cov_get_header "$1" REQUIRES; }

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
  local f name requires
  for f in "${candidate_files[@]}"; do
    name="${f##*/}"
    requires=$(get_requires "$f")

    case "$mode" in
      default)
        if (( list_only )) || requires_met "$f"; then
          printf '%s\n' "$f"
        else
          log_info "  SKIPPED: ${name} (requires: ${requires})" >&2
        fi
        ;;
      all)
        printf '%s\n' "$f"
        ;;
      filter)
        if [[ " ${requires} " == *" ${filter_cmd} "* ]]; then printf '%s\n' "$f"; fi
        ;;
    esac
  done
}

mapfile -t test_files < <(select_tests)

if [[ ${#test_files[@]} -eq 0 ]]; then
  echo "No tests selected."
  exit 0
fi

if (( list_only )); then
  for f in "${test_files[@]}"; do
    printf '%s\t%s\n' "${f##*/}" "${test_covers[$f]}"
  done
  exit 0
fi

# ── Test environments ──────────────────────────────────────────────────────────
# Ensure test environments are up to date before running tests.
bash "${tests_root}/create-test-envs.sh"

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
    log_error "  ${FAIL_COLOR}FAILED${RESET}"
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
      log_error "  ERROR: ${name} requires missing commands: ${missing[*]}" >&2
      return 1
    fi
  fi

  if _should_log "$LOG_LEVEL_TRACE"; then
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
  local container_repo="/home/test/dotfiles"
  local container_test_cases="${container_repo}/tests/test-cases"
  # Mount the working tree (read-only) over the image's baked copy so scripts
  # that are not part of the setup hash are tested at their current version.
  local -a mount_args=(-e LOG_LEVEL -v "${repo_root}:${container_repo}:ro")
  # Setup installs vim-plug and plugins into these gitignored dirs inside the
  # repo; anonymous volumes re-expose the image's own copies over the host's
  # (Docker seeds an empty anonymous volume from the image; --rm removes it).
  local setup_dir
  for setup_dir in vim/.vim/autoload vim/.vim/plugins; do
    mount_args+=(-v "${container_repo}/${setup_dir}")
  done
  [[ -n "${CHANGED_FILES:-}" ]] && mount_args+=(-e CHANGED_FILES)

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
      local check_cmd="true" cmd
      for cmd in $requires; do check_cmd+=" && command -v ${cmd}"; done
      if ! docker run --rm "${image}" bash -li -c "$check_cmd" >/dev/null 2>&1; then
        log_info "  SKIPPED (requires: ${requires})"
        continue
      fi
    fi

    local test_exit=0

    if _should_log "$LOG_LEVEL_TRACE"; then
      # Trace: Docker output flows through including preamble.
      docker run --rm "${mount_args[@]}" \
        "${image}" bash -li "${container_test_cases}/${test_name}" || test_exit=$?
    else
      local docker_output
      docker_output=$(docker run --rm "${mount_args[@]}" \
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
  # all candidate tests. In filter/all modes the selection is already correct.
  _docker_files=("${candidate_files[@]}")
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
