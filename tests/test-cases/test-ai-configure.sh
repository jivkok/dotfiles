#!/usr/bin/env bash
# COVERS: ai/configure_claude.sh
# Tests for ai/configure_claude.sh on Linux: the Claude Code CLI is installed via
# the official install script only when `claude` is not already on PATH.
# `curl` is stubbed, so nothing is downloaded or installed.
set -euo pipefail

DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="${DOTDIR}/ai/configure_claude.sh"

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

if [[ "$(uname -s)" != "Linux" ]]; then
  log_trace "Linux-only branch; skipping on $(uname -s)"
  finish_test
  exit 0
fi

stubs="${tmpdir}/stubs"
mkdir -p "$stubs" "${tmpdir}/home"
curl_log="${tmpdir}/curl.log"
marker="${tmpdir}/installer-ran"
# curl stub: logs its URL and emits an "installer" that only drops a marker file.
write_stub "${stubs}/curl" "echo \"\${!#}\" >> '$curl_log'; echo 'touch $marker'"
base_path="$(path_without claude "$tmpdir")"

# run_script [extra PATH dir]  — run configure_claude.sh with the curl stub first on PATH.
run_script() {
  PATH="${stubs}${1:+:$1}:${base_path}" HOME="${tmpdir}/home" run_capture bash "$SCRIPT"
}

log_trace "--- claude not installed ---"
run_script
assert_eq "not installed: exit code" "0" "$rc"
assert_file_content "$curl_log" "https://claude.ai/install.sh"
assert_file_exists "$marker"

log_trace "--- claude already installed ---"
rm -f "$curl_log" "$marker"
mkdir -p "${tmpdir}/fake-claude"
write_stub "${tmpdir}/fake-claude/claude" 'exit 0'
run_script "${tmpdir}/fake-claude"
assert_eq "installed: exit code" "0" "$rc"
assert_file_absent "$curl_log"
assert_file_absent "$marker"

finish_test
