#!/usr/bin/env bash
# COVERS: tests/docker/docker-env.sh
# Docker environment helpers: auto-start, failure reasons, and platform handling,
# exercised against stub docker/open/colima/uname binaries (no real Docker needed).
# shellcheck disable=SC2016  # snippets passed to `bash -c` / stubs are single-quoted on purpose
set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../testlib.sh
source "${tests_root}/testlib.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
stubs="${tmpdir}/bin"
state="${tmpdir}/state"
mkdir -p "$stubs" "$state"

# docker stub: `info` succeeds iff $state/up exists; `info --format` reports
# $state/arch; `run --platform <p> ...` fails iff $state/no-emulation exists.
write_stub "${stubs}/docker" '
state="'"$state"'"
case "$1" in
  info)
    [[ -f "$state/up" ]] || { echo "Cannot connect to the Docker daemon" >&2; exit 1; }
    [[ "${2:-}" == "--format" ]] && cat "$state/arch"
    exit 0 ;;
  run)
    if [[ -f "$state/no-emulation" ]]; then echo "exec format error" >&2; exit 1; fi
    echo x86_64 ;;
esac'
# open / colima stubs: "start" the runtime.
write_stub "${stubs}/open" 'touch "'"$state"'/up"; touch "'"$state"'/started"'
write_stub "${stubs}/colima" 'touch "'"$state"'/up"; touch "'"$state"'/started"'
write_stub "${stubs}/uname" '[[ "${1:-}" == "-s" ]] && echo "${FAKE_UNAME:-Linux}" || PATH=/usr/bin:/bin uname "$@"'
echo aarch64 > "${state}/arch"

# lib_run <env assignments...> -- <shell snippet>
# Runs the snippet in a fresh bash that has sourced the lib, with stubs first in PATH.
lib_run() {
  local -a envs=()
  while [[ "$1" != "--" ]]; do envs+=("$1"); shift; done
  shift
  env "${envs[@]}" PATH="${stubs}:${PATH}" bash -c "
    source '${tests_root}/docker/docker-env.sh'
    $1" 2>/dev/null
}
reset() { rm -f "${state}/up" "${state}/started" "${state}/no-emulation"; }

log_trace "--- docker_ensure_running ---"
reset; touch "${state}/up"
assert_eq "running daemon: ok, nothing started" "0 no" \
  "$(lib_run -- 'docker_ensure_running; echo -n "$? "; [[ -f '"$state"'/started ]] && echo yes || echo no')"

reset
assert_eq "auto-start disabled: fails with reason" "1|Docker daemon is not running (auto-start disabled by DOTFILES_TEST_NO_DOCKER_START)" \
  "$(lib_run DOTFILES_TEST_NO_DOCKER_START=1 -- 'docker_ensure_running; echo -n "$?|"; echo "$DOCKER_UNAVAILABLE_REASON"')"

reset
out="$(lib_run FAKE_UNAME=Linux -- 'docker_ensure_running; echo -n "$?|"; echo "$DOCKER_UNAVAILABLE_REASON"')"
assert_contains "linux: never auto-starts, reports reason" "1|Docker daemon is not running" "$out"
assert_eq "linux: nothing was started" "no" "$([[ -f "${state}/started" ]] && echo yes || echo no)"

reset
assert_eq "macOS: starts the runtime and waits for the daemon" "0 yes" \
  "$(lib_run FAKE_UNAME=Darwin -- 'docker_ensure_running; echo -n "$? "; [[ -f '"$state"'/started ]] && echo yes || echo no')"

# A runtime that never comes up: open succeeds but the daemon stays down.
write_stub "${stubs}/open" 'exit 0'
write_stub "${stubs}/colima" 'exit 0'
reset
out="$(lib_run FAKE_UNAME=Darwin DOTFILES_TEST_DOCKER_TIMEOUT=2 -- 'docker_ensure_running; echo -n "$?|"; echo "$DOCKER_UNAVAILABLE_REASON"')"
assert_eq "macOS: daemon never ready -> recorded failure" "1|Docker daemon did not become ready within 2s after start" "$out"

reset
assert_eq "an earlier recorded failure is not retried" "1" \
  "$(lib_run FAKE_UNAME=Darwin DOCKER_UNAVAILABLE_REASON=boom -- 'docker_ensure_running; echo $?')"

log_trace "--- docker_platform_for ---"
assert_eq "ARCH defaults to linux/amd64"      "linux/amd64" "$(lib_run -- 'docker_platform_for ARCH')"
assert_eq "ARCH_REMOTE defaults to linux/amd64" "linux/amd64" "$(lib_run -- 'docker_platform_for ARCH_REMOTE')"
assert_eq "DEBIAN is native (empty)"          "" "$(lib_run -- 'docker_platform_for DEBIAN')"
assert_eq "ARCH platform is overridable"      "linux/arm64" \
  "$(lib_run DOTFILES_TEST_ARCH_PLATFORM=linux/arm64 -- 'docker_platform_for ARCH')"

log_trace "--- docker_env_check ---"
reset; touch "${state}/up"
assert_eq "arm64 daemon + emulation: ARCH usable" "0" "$(lib_run -- 'docker_env_check ARCH; echo $?')"
assert_eq "DEBIAN usable" "0" "$(lib_run -- 'docker_env_check DEBIAN; echo $?')"

touch "${state}/no-emulation"
out="$(lib_run -- 'docker_env_check ARCH; echo -n "$?|"; echo "$DOCKER_ENV_REASON"')"
assert_contains "no emulation: ARCH blocked" "1|cannot run linux/amd64 containers" "$out"
assert_eq "no emulation: DEBIAN (native) unaffected" "0" "$(lib_run -- 'docker_env_check DEBIAN; echo $?')"

echo x86_64 > "${state}/arch"
assert_eq "amd64 daemon: ARCH is native, no probe needed" "0" "$(lib_run -- 'docker_env_check ARCH; echo $?')"
echo aarch64 > "${state}/arch"

out="$(lib_run DOCKER_UNAVAILABLE_REASON=daemon-down -- 'docker_env_check DEBIAN; echo -n "$?|"; echo "$DOCKER_ENV_REASON"')"
assert_eq "daemon failure blocks every environment" "1|daemon-down" "$out"

finish_test
