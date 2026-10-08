#!/usr/bin/env bash
# REQUIRES: git
# COVERS: tests/run-tests.sh tests/test-cases/test-coverage-map.sh
# Self-tests for the runner's change-based selection (run-tests.sh --changed /
# --list, rules A–H in docs/testing.md) and for test-coverage-map.sh failure
# modes.
#
# Rule checks use CHANGED_FILES_OVERRIDE against this repo (read-only).
# Git-mode, CHANGED_FILES and coverage-map checks run in a throwaway copy of
# the tracked tree with its own git repo and a stubbed create-test-envs.sh, so
# no environment is ever built.
set -euo pipefail

DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUNNER="${DOTDIR}/tests/run-tests.sh"

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

all_tests="$(find "${DOTDIR}/tests/test-cases" -maxdepth 1 -name 'test-*.sh' -exec basename {} \; | sort | paste -s -d' ' -)"

# names <runner-output>  — selected test names (first --list column), sorted, space-joined.
names() { { grep -E '^test-[^[:space:]]+\.sh'$'\t' <<< "$1" || true; } | cut -f1 | sort | paste -s -d' ' -; }

# list_override <changes> [runner-args...]  — `--list --changed` output for the given changes.
list_override() {
  local changes="$1"
  shift
  CHANGED_FILES_OVERRIDE="$changes" bash "$RUNNER" --list --changed "$@" 2>&1
}

# expect_selection <label> <changes> <expected-names>
expect_selection() {
  assert_eq "$1" "$3" "$(names "$(list_override "$2")")"
}

# ── Rules (CHANGED_FILES_OVERRIDE) ─────────────────────────────────────────────
log_trace "--- Rule A: changed test file ---"
expect_selection "A: test file selects itself" "tests/test-cases/test-git-env.sh" "test-git-env.sh"

log_trace "--- Rule B: runner infrastructure ---"
for f in tests/testlib.sh tests/run-tests.sh tests/create-test-envs.sh; do
  expect_selection "B: $f selects every test" "$f" "$all_tests"
done

log_trace "--- Rule C: helper ---"
helper="startup-checks.sh"   # built dynamically so this file does not reference it
expect_selection "C: helper selects the tests that reference it" \
  "tests/test-cases/helpers/${helper}" "test-startup-bash.sh test-startup-zsh.sh"

log_trace "--- Rule D: setup-hash file ---"
expect_selection "D: setup/setup.sh selects every test" "setup/setup.sh" "$all_tests"
expect_selection "D: python/configure_python.sh selects every test" "python/configure_python.sh" "$all_tests"

log_trace "--- Rule E: unmapped script ---"
out="$(list_override "newdir/unmapped-script.sh")"
assert_eq "E: unmapped script selects every test" "$all_tests" "$(names "$out")"
assert_contains "E: WARN: unmapped line" "WARN: unmapped script changed: newdir/unmapped-script.sh" "$out"

log_trace "--- Rule F: non-script files ---"
run_capture list_override $'README.md\ndocs/testing.md\ntasks/done/x.md'
assert_eq "F: exit code" "0" "$rc"
assert_eq "F: prints No tests selected." "No tests selected." "$out"

log_trace "--- Rule G: covered script ---"
expect_selection "G: bin/tmux-status-cpu.sh" "bin/tmux-status-cpu.sh" "test-lint.sh test-tmux-status.sh"
expect_selection "G: sh/utils.sh" "sh/utils.sh" "test-lint.sh test-sh-libs.sh test-startup-bash.sh test-startup-zsh.sh"

log_trace "--- Rule H: added / deleted files ---"
expect_selection "H: added script also selects the coverage map" $'A\tbin/tmux-status-cpu.sh' \
  "test-coverage-map.sh test-lint.sh test-tmux-status.sh"
expect_selection "H: deleted covered script selects its tests + coverage map" $'D\tgit/git.sh' \
  "test-coverage-map.sh test-git-env.sh test-lint.sh"

# ── --list output and flag combinations ────────────────────────────────────────
log_trace "--- --list ---"
out="$(list_override "git/git.sh")"
assert_contains "--list prints name<TAB>COVERS" "test-git-env.sh"$'\t'"git/git.sh" "$out"
assert_eq "--list alone lists every test" "$all_tests" "$(names "$(bash "$RUNNER" --list 2>&1)")"
assert_eq "--list --all lists every test" "$all_tests" "$(names "$(bash "$RUNNER" --list --all 2>&1)")"
# shellcheck source=../coverage-lib.sh
source "${DOTDIR}/tests/coverage-lib.sh"
# Reuses the real header reader (15-line window, exact "# REQUIRES:" prefix)
# instead of a second, differently-implemented matcher that could diverge
# from tests/run-tests.sh's own selection logic for reasons unrelated to an
# actual regression in it.
tmux_tests=""
for _f in "${DOTDIR}"/tests/test-cases/test-*.sh; do
  _requires=" $(cov_get_header "$_f" REQUIRES) "
  [[ "$_requires" == *" tmux "* ]] && tmux_tests+="$(basename "$_f")"$'\n'
done
tmux_tests="$(printf '%s' "$tmux_tests" | sort | paste -s -d' ' -)"
assert_eq "--list --filter tmux selects by REQUIRES" "$tmux_tests" "$(names "$(bash "$RUNNER" --list --filter tmux 2>&1)")"
assert_eq "--changed combines with --filter" "test-git-env.sh" \
  "$(names "$(list_override $'git/git.sh\nbin/tmux-status-cpu.sh' --filter git)")"

# ── Throwaway repo copy ────────────────────────────────────────────────────────
pristine="${tmpdir}/pristine"
mkdir -p "$pristine"
# shellcheck source=../coverage-lib.sh
source "${DOTDIR}/tests/coverage-lib.sh"
(
  cd "$DOTDIR"
  cov_tracked_files . | while IFS= read -r f; do [[ -e "$f" ]] && printf '%s\0' "$f"; done \
    | tar --null -T - -cf -
) | tar -C "$pristine" -xf -
# Stub create-test-envs.sh: report one setup file; record any real (build) invocation.
cat > "${pristine}/tests/create-test-envs.sh" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "--print-setup-files" ]]; then echo "setup/setup.sh"; exit 0; fi
touch "$(dirname "$0")/.envs-built"
EOF
git_q() { git -c user.name=t -c user.email=t@example.com -c init.defaultBranch=main "$@" >/dev/null 2>&1; }
(cd "$pristine" && git_q init && git_q add -A && git_q commit -m base)

fresh_copy() {  # fresh_copy <name>  — print the path of a new copy of the pristine repo
  cp -a "$pristine" "${tmpdir}/$1"
  printf '%s' "${tmpdir}/$1"
}

log_trace "--- --list does not build environments ---"
repo="$(fresh_copy list-only)"
bash "${repo}/tests/run-tests.sh" --list >/dev/null 2>&1
assert_file_absent "${repo}/tests/.envs-built"

log_trace "--- git mode: HEAD, staged, unstaged, untracked, renames ---"
repo="$(fresh_copy gitmode)"
echo "# unstaged" >> "${repo}/bin/tmux-status-cpu.sh"
echo "# staged" >> "${repo}/git/git.sh" && (cd "$repo" && git_q add git/git.sh)
touch "${repo}/sh/newlib.sh"
out="$(cd "$repo" && bash tests/run-tests.sh --list --changed 2>&1)"
sel="$(names "$out")"
for t in test-tmux-status.sh test-git-env.sh test-sh-libs.sh test-coverage-map.sh; do
  assert_contains "git mode selects $t" " $t " " $sel "
done

repo="$(fresh_copy rename)"
(cd "$repo" && git_q mv git/git.sh git/git-renamed.sh)
sel="$(names "$(cd "$repo" && bash tests/run-tests.sh --list --changed 2>&1)")"
assert_contains "rename selects the coverage map" " test-coverage-map.sh " " $sel "
assert_contains "rename selects tests of the old path" " test-git-env.sh " " $sel "

log_trace "--- git mode: <ref> ---"
repo="$(fresh_copy ref)"
(cd "$repo" && echo "# committed" >> git/git.sh && git_q commit -am second)
sel="$(names "$(cd "$repo" && bash tests/run-tests.sh --list --changed HEAD~1 2>&1)")"
assert_eq "--changed HEAD~1 selects committed changes" "test-git-env.sh test-lint.sh" "$sel"
out="$(cd "$repo" && bash tests/run-tests.sh --list --changed 2>&1)"
assert_eq "--changed (HEAD) ignores committed changes" "No tests selected." "$out"

log_trace "--- errors ---"
run_capture bash "${repo}/tests/run-tests.sh" --list --changed no-such-ref
check_not "bad ref: non-zero exit" test "$rc" -eq 0
assert_contains "bad ref: ERROR" "ERROR:" "$out"
nogit="${tmpdir}/nogit"
cp -a "$pristine" "$nogit" && rm -rf "${nogit}/.git"
run_capture bash "${nogit}/tests/run-tests.sh" --changed
check_not "outside a work tree: non-zero exit" test "$rc" -eq 0
assert_contains "outside a work tree: ERROR" "ERROR:" "$out"
assert_file_absent "${nogit}/tests/.envs-built"

log_trace "--- CHANGED_FILES export ---"
repo="$(fresh_copy envdump)"
mkdir -p "${repo}/foo"
cat > "${repo}/tests/test-cases/test-zz-envdump.sh" <<EOF
#!/usr/bin/env bash
# COVERS: foo/*.sh
printf '%s' "\${CHANGED_FILES:-<unset>}" > "${tmpdir}/changed-files.out"
EOF
CHANGED_FILES_OVERRIDE=$'foo/a.sh\nD\tfoo/b.sh' bash "${repo}/tests/run-tests.sh" --changed >/dev/null 2>&1 || true
dump="$(cat "${tmpdir}/changed-files.out" 2>/dev/null || echo '<missing>')"
assert_contains "CHANGED_FILES contains changed paths" "foo/a.sh" "$dump"
check_not "CHANGED_FILES excludes deleted paths ($dump)" grep -qF foo/b.sh <<< "$dump"
rm -f "${tmpdir}/changed-files.out"
bash "${repo}/tests/run-tests.sh" --filter no-such-cmd >/dev/null 2>&1 || true
# Without --changed the variable must not be exported (the test is not selected
# here, so run it directly under the runner's environment instead).
env -u CHANGED_FILES bash "${repo}/tests/test-cases/test-zz-envdump.sh"
assert_eq "CHANGED_FILES unset outside --changed" "<unset>" "$(cat "${tmpdir}/changed-files.out")"

# ── test-coverage-map.sh failure modes ─────────────────────────────────────────
log_trace "--- coverage map failures ---"
covmap() {  # covmap <repo>  — run the real coverage-map test against <repo>
  COVERAGE_MAP_ROOT="$1" bash "${DOTDIR}/tests/test-cases/test-coverage-map.sh" 2>&1
}

# expect_covmap_failure <label> <repo> <expected-message>
expect_covmap_failure() {
  run_capture covmap "$2"
  check_not "coverage map: $1 (non-zero exit)" test "$rc" -eq 0
  assert_contains "coverage map: $1 (message)" "$3" "$out"
}

repo="$(fresh_copy cov-uncovered)"
mkdir -p "${repo}/newdir" && echo 'echo hi' > "${repo}/newdir/x.sh"
expect_covmap_failure "uncovered script" "$repo" "uncovered script: newdir/x.sh"

repo="$(fresh_copy cov-stale-covers)"
printf '#!/usr/bin/env bash\n# COVERS: nothing/here.sh\n' > "${repo}/tests/test-cases/test-zz-stale.sh"
expect_covmap_failure "stale COVERS" "$repo" "stale COVERS entry 'nothing/here.sh'"

repo="$(fresh_copy cov-stale-exclude)"
echo "gone/*.sh  # removed long ago" >> "${repo}/tests/coverage-exclude"
expect_covmap_failure "stale exclude" "$repo" "stale coverage-exclude entry 'gone/*.sh'"

repo="$(fresh_copy cov-no-reason)"
echo "bin/tmux-status-ip.sh" >> "${repo}/tests/coverage-exclude"
expect_covmap_failure "missing reason" "$repo" "without a '# reason': bin/tmux-status-ip.sh"

repo="$(fresh_copy cov-ok)"
check "coverage map passes on an unmodified copy" covmap "$repo"

finish_test
