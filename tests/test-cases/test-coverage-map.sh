#!/usr/bin/env bash
# COVERS: tests/coverage-exclude tests/coverage-lib.sh
# COVERAGE: meta
# Enforces the script → test coverage map:
#   - every tracked script (see cov_is_script) matches a COVERS entry of a
#     non-meta test, or an entry in tests/coverage-exclude;
#   - every COVERS and coverage-exclude entry matches at least one tracked file;
#   - every coverage-exclude entry states a reason;
#   - every test file has exactly one `# COVERS:` header in its first lines.
#
# Env overrides (used by test-run-tests-selection.sh to exercise failures):
#   COVERAGE_MAP_ROOT  repo root to check (default: this repo)
set -euo pipefail

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"
# shellcheck source=../coverage-lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../coverage-lib.sh"

repo_root="${COVERAGE_MAP_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
exclude_file="${repo_root}/tests/coverage-exclude"

mapfile -t tracked < <(cov_tracked_files "$repo_root")
mapfile -t test_files < <(find "${repo_root}/tests/test-cases" -maxdepth 1 -name 'test-*.sh' | sort)

# ── One COVERS header per test ────────────────────────────────────────────────
log_trace "--- COVERS headers ---"
for f in "${test_files[@]}"; do
  count="$(head -n "$COV_HEADER_LINES" "$f" | grep -c '^# COVERS:' || true)"
  assert_eq "${f##*/}: exactly one '# COVERS:' header" "1" "$count"
done

# ── Collect globs ─────────────────────────────────────────────────────────────
covering_globs=()   # from non-meta tests: count as coverage
declare -A glob_owner=()
for f in "${test_files[@]}"; do
  read -r -a globs <<< "$(cov_get_header "$f" COVERS)"
  for g in "${globs[@]}"; do glob_owner[$g]+="${f##*/} "; done
  cov_is_meta "$f" || covering_globs+=("${globs[@]}")
done

exclude_globs=()
while IFS=$'\t' read -r glob reason; do
  exclude_globs+=("$glob")
  if [[ -n "$reason" ]]; then
    ok "coverage-exclude reason: $glob"
  else
    fail "coverage-exclude entry without a '# reason': $glob"
  fi
done < <(cov_exclude_lines "$exclude_file")

# ── Stale entries ─────────────────────────────────────────────────────────────
log_trace "--- stale entries ---"
for g in "${!glob_owner[@]}"; do
  if cov_glob_matches_any "$g" "${tracked[@]}"; then
    ok "COVERS entry matches a file: $g"
  else
    fail "stale COVERS entry '$g' (in ${glob_owner[$g]% }) matches no tracked file"
  fi
done
for g in "${exclude_globs[@]}"; do
  if cov_glob_matches_any "$g" "${tracked[@]}"; then
    ok "coverage-exclude entry matches a file: $g"
  else
    fail "stale coverage-exclude entry '$g' matches no tracked file"
  fi
done

# ── Uncovered scripts ─────────────────────────────────────────────────────────
log_trace "--- uncovered scripts ---"
for t in "${tracked[@]}"; do
  cov_is_script "$t" || continue
  [[ -e "${repo_root}/${t}" ]] || continue
  if cov_path_matches_any "$t" "${covering_globs[@]}" "${exclude_globs[@]}"; then
    ok "mapped: $t"
  else
    fail "uncovered script: $t (add it to a test's '# COVERS:' or to tests/coverage-exclude)"
  fi
done

finish_test
