#!/usr/bin/env bash
# shellcheck disable=SC2016,SC2088  # single-quoted snippets expand in the child shell; literal ~ is passed to the script under test
# COVERS: docker/docker.sh ai/claude-code/claude-code-docker.sh
# Tests for the docker shell helpers (docker/docker.sh) and the Claude Code
# container launcher (ai/claude-code/claude-code-docker.sh). `docker` and
# `curl` are stubbed on PATH, so no daemon or network is needed; `jq` is real.
set -euo pipefail

DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
LAUNCHER="${DOTDIR}/ai/claude-code/claude-code-docker.sh"

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

stubs="${tmpdir}/stubs"
mkdir -p "$stubs"
curl_log="${tmpdir}/curl.log"
run_log="${tmpdir}/docker-run.log"
build_log="${tmpdir}/docker-build.log"

# curl stub: logs the URL (last argument), prints $STUB_CURL_OUT.
write_stub "${stubs}/curl" "$(cat <<EOF
echo "\${!#}" >> "$curl_log"
printf '%s\n' "\${STUB_CURL_OUT:-}"
EOF
)"
# docker stub: `images` prints $STUB_DOCKER_IMAGES; `run`/`build` log one arg per line.
write_stub "${stubs}/docker" "$(cat <<EOF
case "\$1" in
  images) [[ -n "\${STUB_DOCKER_IMAGES:-}" ]] && printf '%s\n' "\$STUB_DOCKER_IMAGES" ;;
  run)    shift; printf '%s\n' "\$@" > "$run_log" ;;
  build)  shift; printf '%s\n' "\$@" > "$build_log" ;;
esac
exit 0
EOF
)"

# PATH without yq: the launcher's fallback .aiproj parser is under test.
STUB_PATH="${stubs}:$(path_without yq "$tmpdir")"

# ── docker/docker.sh: docker_tags ──────────────────────────────────────────────
log_trace "--- docker_tags ---"
tags_json='{"results":[{"name":"22.04","last_updated":"2024-01-01"},{"name":"24.04","last_updated":"2025-01-01"}]}'

# docker_sh <snippet>  — run snippet after sourcing docker.sh with stubs on PATH.
docker_sh() {
  PATH="$STUB_PATH" STUB_CURL_OUT="$tags_json" dotdir="$DOTDIR" \
    bash -c "source \"\$dotdir/docker/docker.sh\"; $1" 2>&1
}

run_capture docker_sh 'docker_tags'
assert_eq "docker_tags without args: exit code" "1" "$rc"
assert_contains "docker_tags without args: Usage" "Usage:" "$out"

: > "$curl_log"
docker_sh 'docker_tags ubuntu "" 1' >/dev/null
assert_file_content "$curl_log" "repositories/library/ubuntu/tags"
: > "$curl_log"
docker_sh 'docker_tags me/img "" 1' >/dev/null
assert_file_content "$curl_log" "repositories/me/img/tags"

: > "$curl_log"
out="$(docker_sh 'docker_tags ubuntu 22 1')"
assert_eq "docker_tags max pages 1: one request" "1" "$(wc -l < "$curl_log" | tr -d ' ')"
assert_eq "docker_tags filter keeps matching lines only" "22.04" "$out"

# ── docker/docker.sh: aliases/functions depend on docker being installed ──────
log_trace "--- docker.sh with/without docker ---"
out="$(docker_sh 'alias dps >/dev/null && type dexbash >/dev/null && echo defined')"
assert_eq "docker present: dps alias and dexbash defined" "defined" "$out"
no_docker_bin="${tmpdir}/no-docker-bin"
mkdir -p "$no_docker_bin"
out="$(PATH="$no_docker_bin" dotdir="$DOTDIR" "$BASH" -c \
  'source "$dotdir/docker/docker.sh"; alias dps >/dev/null 2>&1 || type dexbash >/dev/null 2>&1 || echo absent')"
assert_eq "docker absent: neither dps nor dexbash defined" "absent" "$out"

# ── claude-code-docker.sh ──────────────────────────────────────────────────────
build_n="$(cat "${DOTDIR}/ai/claude-code/BUILD")"
work="${tmpdir}/work"
fake_home="${tmpdir}/home"
state="${tmpdir}/state"
launcher_tmp="${tmpdir}/launcher-tmp"
mkdir -p "$work" "$fake_home" "$state" "$launcher_tmp"
stamp="${launcher_tmp}/ai-claude-code-version-check-$(id -u)"

# launch [args...]  — run the launcher from $work with stubs; env tweaks via caller.
launch() {
  (cd "$work" && env -u TMUX -u ANTHROPIC_API_KEY \
    PATH="$STUB_PATH" HOME="$fake_home" XDG_STATE_HOME="$state" TMPDIR="$launcher_tmp" \
    STUB_DOCKER_IMAGES="${STUB_DOCKER_IMAGES-ai-claude-code:1.2.3.${build_n}}" \
    STUB_CURL_OUT="${STUB_CURL_OUT:-}" \
    ${API_KEY:+ANTHROPIC_API_KEY="$API_KEY"} \
    bash "$LAUNCHER" "$@" 2>&1)
}
run_args() { cat "$run_log" 2>/dev/null; }
# has_arg_pair <a> <b>  — true if run args contain <a> immediately followed by <b>.
has_arg_pair() { run_args | grep -xF -A1 -- "$1" | grep -qxF -- "$2"; }

log_trace "--- claude-code-docker.sh: default run ---"
date +%Y-%m-%d > "$stamp"
rm -f "$run_log"
launch >/dev/null
check "mounts cwd at /workspace" has_arg_pair -v "${work}:/workspace"
check "uses the tagged image" grep -qxF "ai-claude-code:1.2.3.${build_n}" "$run_log"
if run_args | tr '\n' ' ' | grep -qF "ai-claude-code:1.2.3.${build_n} claude --permission-mode auto"; then
  ok "runs claude --permission-mode auto"
else
  fail "claude --permission-mode auto missing in: $(run_args | tr '\n' ' ')"
fi
check "state kept under XDG_STATE_HOME" test -n "$(ls -A "$state")"

log_trace "--- claude-code-docker.sh: CLI mount ---"
rm -f "$run_log"
launch '~/x:/x' >/dev/null
check "CLI mount expands ~" has_arg_pair -v "${fake_home}/x:/x"
check "CLI mount adds --add-dir /x" has_arg_pair --add-dir /x

log_trace "--- claude-code-docker.sh: .aiproj volumes (no yq) ---"
printf 'volumes:\n  - /a:/b\n' > "${work}/.aiproj"
rm -f "$run_log"
launch >/dev/null
check ".aiproj volume mounted" has_arg_pair -v /a:/b
check ".aiproj volume adds --add-dir /b" has_arg_pair --add-dir /b
rm -f "${work}/.aiproj"

log_trace "--- claude-code-docker.sh: ANTHROPIC_API_KEY ---"
rm -f "$run_log"
launch >/dev/null
check_not "API key not forwarded when unset" grep -q '^ANTHROPIC_API_KEY=' "$run_log"
rm -f "$run_log"
API_KEY=sk-test launch >/dev/null
check "API key forwarded when set" grep -qxF 'ANTHROPIC_API_KEY=sk-test' "$run_log"

log_trace "--- claude-code-docker.sh: unresolvable version, no image ---"
rm -f "$stamp" "$run_log"
STUB_DOCKER_IMAGES="" STUB_CURL_OUT="garbage" run_capture launch
assert_eq "no image + bad version: exit code" "1" "$rc"
assert_contains "no image + bad version: error message" "couldn't resolve" "$out"
assert_file_absent "$run_log"

log_trace "--- claude-code-docker.sh: newer version triggers a build ---"
rm -f "$stamp" "$build_log"
STUB_CURL_OUT="9.9.9" launch >/dev/null
check "docker build with CLAUDE_CODE_VERSION=9.9.9" grep -qxF "CLAUDE_CODE_VERSION=9.9.9" "$build_log"

finish_test
