#!/usr/bin/env bash
# COVERS: bin/tmux-status-cpu.sh bin/tmux-status-ip.sh
# Tests for the tmux status-bar helpers. Network lookups are replaced by stubs
# on PATH; caches live in a temporary TMPDIR.
set -euo pipefail

DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CPU_SCRIPT="${DOTDIR}/bin/tmux-status-cpu.sh"
IP_SCRIPT="${DOTDIR}/bin/tmux-status-ip.sh"

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# ── color_for thresholds ───────────────────────────────────────────────────────
log_trace "--- color_for ---"
for pair in 0:green 49:green 50:yellow 79:yellow 80:red 100:red; do
  pct="${pair%%:*}" expected="${pair#*:}"
  actual="$(bash -c "source '$CPU_SCRIPT'; color_for $pct")"
  assert_eq "color_for $pct" "$expected" "$actual"
done

# ── tmux-status-cpu.sh output (Linux: /proc based) ─────────────────────────────
if [[ "$(uname -s)" == "Linux" ]]; then
  log_trace "--- tmux-status-cpu.sh ---"
  for mode in cpu ram; do
    TMPDIR="$tmpdir" run_capture bash "$CPU_SCRIPT" "$mode"
    assert_eq "$mode: exit code" "0" "$rc"
    if [[ "$out" =~ ^#\[fg=(green|yellow|red)\][A-Z]+:([0-9]+)%#\[default\]$ ]] \
      && (( BASH_REMATCH[2] >= 0 && BASH_REMATCH[2] <= 100 )); then
      ok "$mode: integer percentage in 0-100 ($out)"
    else
      fail "$mode: unexpected output '$out'"
    fi
  done
  TMPDIR="$tmpdir" run_capture bash "$CPU_SCRIPT" all
  assert_eq "all: exit code" "0" "$rc"
  if [[ "$out" =~ CPU:([0-9]+)%.*RAM:([0-9]+)% ]] \
    && (( BASH_REMATCH[1] <= 100 && BASH_REMATCH[2] <= 100 )); then
    ok "all: CPU and RAM percentages ($out)"
  else
    fail "all: unexpected output '$out'"
  fi
fi

# ── Usage errors ───────────────────────────────────────────────────────────────
log_trace "--- usage ---"
for script in "$CPU_SCRIPT" "$IP_SCRIPT"; do
  rc=0; err="$(bash "$script" bogus 2>&1 >/dev/null)" || rc=$?
  assert_eq "${script##*/} bogus: exit code" "1" "$rc"
  assert_eq "${script##*/} bogus: Usage on stderr" "Usage:" "${err:0:6}"
done

# ── get_external_ip caching ────────────────────────────────────────────────────
stubs="${tmpdir}/stubs"
mkdir -p "$stubs"
curl_log="${tmpdir}/curl.log"
# curl stub: records each call; prints $STUB_CURL_OUT (may be empty).
write_stub "${stubs}/curl" "echo \"\$*\" >> '$curl_log'; printf '%s' \"\${STUB_CURL_OUT:-}\""
write_stub "${stubs}/dig" 'exit 0'

ext_ip() {  # ext_ip <cache-dir>  — run get_external_ip with stubs first on PATH
  PATH="${stubs}:${PATH}" TMPDIR="$1" bash -c "source '$IP_SCRIPT'; get_external_ip"
}

log_trace "--- get_external_ip: fresh cache ---"
fresh="${tmpdir}/fresh"; mkdir -p "$fresh"
echo "203.0.113.7" > "${fresh}/tmux_external_ip"
: > "$curl_log"
assert_eq "fresh cache value returned" "203.0.113.7" "$(STUB_CURL_OUT=198.51.100.1 ext_ip "$fresh")"
assert_eq "fresh cache: curl not invoked" "0" "$(wc -l < "$curl_log" | tr -d ' ')"

log_trace "--- get_external_ip: stale cache ---"
stale="${tmpdir}/stale"; mkdir -p "$stale"
echo "203.0.113.7" > "${stale}/tmux_external_ip"
touch -t 200001010000 "${stale}/tmux_external_ip"
: > "$curl_log"
assert_eq "stale cache: fetched value returned" "198.51.100.1" "$(STUB_CURL_OUT=198.51.100.1 ext_ip "$stale")"
check "stale cache: curl invoked" test -s "$curl_log"
assert_eq "stale cache: cache rewritten" "198.51.100.1" "$(cat "${stale}/tmux_external_ip")"

log_trace "--- get_external_ip: all services empty ---"
empty="${tmpdir}/empty"; mkdir -p "$empty"
STUB_CURL_OUT='' run_capture ext_ip "$empty"
assert_eq "all empty: exit code" "0" "$rc"
assert_eq "all empty: no output" "" "$out"
assert_file_absent "${empty}/tmux_external_ip"

finish_test
