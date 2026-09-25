#!/usr/bin/env bash
# COVERS: osx/configure_browsers.sh
# Unit tests for the helper functions in osx/configure_browsers.sh, sourced
# directly (sourcing only defines functions; main runs only when executed).
# Runs on every OS: the helpers operate on plain directories.
set -euo pipefail

DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

# ── Temp workspace ────────────────────────────────────────────────────────────
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# create_firefox_profile writes a Profile Group database with sqlite3; stub it
# when absent so the profiles.ini logic is still exercised.
if ! command -v sqlite3 >/dev/null 2>&1; then
  mkdir -p "${tmpdir}/stubs"
  write_stub "${tmpdir}/stubs/sqlite3" 'cat >/dev/null'
  PATH="${tmpdir}/stubs:${PATH}"
  have_sqlite=0
else
  have_sqlite=1
fi

# shellcheck source=../../osx/configure_browsers.sh
source "${DOTDIR}/osx/configure_browsers.sh"

# ── create_firefox_profile ────────────────────────────────────────────────────
log_trace "--- create_firefox_profile ---"

app_support="${tmpdir}/Firefox"
ini="${app_support}/profiles.ini"

default_dir="$(create_firefox_profile "$app_support" "jk-default" 1)"
assert_dir "$default_dir"
assert_file_exists "$ini"
assert_file_content "$ini" "[General]"
assert_file_content "$ini" "Name=jk-default"
assert_file_content "$ini" "IsRelative=1"
assert_file_content "$ini" "Default=1"
assert_file_content "$ini" "ShowSelector=1"
case "$default_dir" in
  "${app_support}/Profiles/"*.jk-default) ok "profile dir is Profiles/<storeId>.jk-default" ;;
  *) fail "unexpected profile dir: $default_dir" ;;
esac
store_id="$(awk -F= '/^StoreID=/{print $2; exit}' "$ini")"
check "StoreID is 8 hex chars ($store_id)" grep -qxE '[0-9a-f]{8}' <<< "$store_id"
if (( have_sqlite )); then
  db="${app_support}/Profile Groups/${store_id}.sqlite"
  assert_eq "Profile Group db has the profile" "jk-default" "$(sqlite3 "$db" 'SELECT name FROM Profiles WHERE id=1;')"
fi

# Idempotent: same name returns the same directory, no duplicate entry.
again_dir="$(create_firefox_profile "$app_support" "jk-default" 1)"
assert_eq "idempotent: same directory returned" "$default_dir" "$again_dir"
assert_eq "idempotent: one profiles.ini entry" "1" "$(grep -c '^Name=jk-default$' "$ini")"

# Second profile is appended under the next [ProfileN] index.
trusted_dir="$(create_firefox_profile "$app_support" "jk-research-trusted")"
assert_dir "$trusted_dir"
assert_file_content "$ini" "[Profile0]"
assert_file_content "$ini" "[Profile1]"
assert_file_content "$ini" "Name=jk-research-trusted"

# A profile registered without a StoreID (e.g. created via about:profiles) gets one.
legacy="${tmpdir}/Legacy"
mkdir -p "$legacy"
printf '[General]\nStartWithLastProfile=1\n\n[Profile0]\nName=old\nIsRelative=1\nPath=Profiles/abc.old\n' > "${legacy}/profiles.ini"
legacy_dir="$(create_firefox_profile "$legacy" "old")"
assert_eq "legacy profile keeps its path" "${legacy}/Profiles/abc.old" "$legacy_dir"
assert_dir "$legacy_dir"
assert_file_content "${legacy}/profiles.ini" "StoreID="

# ── write_firefox_user_js ─────────────────────────────────────────────────────
log_trace "--- write_firefox_user_js ---"

write_firefox_user_js "$default_dir" 'user_pref("network.cookie.cookieBehavior", 1);'
assert_file_content "${default_dir}/user.js" 'user_pref("network.cookie.cookieBehavior", 1);'
write_firefox_user_js "$default_dir" 'user_pref("browser.shell.checkDefaultBrowser", false);'
assert_eq "user.js is overwritten, not appended" "1" "$(wc -l < "${default_dir}/user.js" | tr -d ' ')"
assert_file_content "${default_dir}/user.js" '"browser.shell.checkDefaultBrowser"'

# ── install_firefox_extension ─────────────────────────────────────────────────
log_trace "--- install_firefox_extension ---"

serve="${tmpdir}/amo"
mkdir -p "${serve}/ublock-origin" "${serve}/vimium-ff" "${serve}/html-page" "${serve}/empty"
printf 'PK\x03\x04fake-xpi-content' > "${serve}/ublock-origin/latest.xpi"
printf 'PK\x03\x04fake-xpi-content' > "${serve}/vimium-ff/latest.xpi"
printf '<!DOCTYPE html><html><body>Not found</body></html>\n' > "${serve}/html-page/latest.xpi"
: > "${serve}/empty/latest.xpi"
export AMO_BASE_URL="file://${serve}"

profile="${tmpdir}/ext-profile"
install_firefox_extension "$profile" "uBlock0@raymondhill.net" "ublock-origin"
assert_dir "${profile}/extensions"
assert_file_exists "${profile}/extensions/uBlock0@raymondhill.net.xpi"

# Idempotent: already-present XPI is not re-downloaded.
printf 'marker' > "${profile}/extensions/uBlock0@raymondhill.net.xpi"
install_firefox_extension "$profile" "uBlock0@raymondhill.net" "ublock-origin"
assert_eq "existing XPI left untouched" "marker" "$(cat "${profile}/extensions/uBlock0@raymondhill.net.xpi")"

if install_firefox_extension "$profile" "missing@example.com" "no-such-slug" 2>/dev/null; then
  fail "install_firefox_extension should fail for a missing slug"
else
  ok "install_firefox_extension fails for a missing slug"
fi
assert_file_absent "${profile}/extensions/missing@example.com.xpi"

if install_firefox_extension "$profile" "html@example.com" "html-page" 2>/dev/null; then
  fail "install_firefox_extension should reject an HTML response"
else
  ok "install_firefox_extension rejects an HTML response"
fi
assert_file_absent "${profile}/extensions/html@example.com.xpi"

if install_firefox_extension "$profile" "empty@example.com" "empty" 2>/dev/null; then
  fail "install_firefox_extension should reject an empty download"
else
  ok "install_firefox_extension rejects an empty download"
fi
assert_file_absent "${profile}/extensions/empty@example.com.xpi"

# ── install_extensions_into_profile ───────────────────────────────────────────
log_trace "--- install_extensions_into_profile ---"

profile2="${tmpdir}/ext-profile2"
install_extensions_into_profile "$profile2" \
  "uBlock0@raymondhill.net" "ublock-origin" \
  "{d07ccf11-c0cd-4938-a265-2a4d6ad01189}" "vimium-ff"
assert_file_exists "${profile2}/extensions/uBlock0@raymondhill.net.xpi"
assert_file_exists "${profile2}/extensions/{d07ccf11-c0cd-4938-a265-2a4d6ad01189}.xpi"
assert_eq "exactly the listed extensions installed" "2" "$(find "${profile2}/extensions" -name '*.xpi' | wc -l | tr -d ' ')"

unset AMO_BASE_URL

# ── main: early exits ──────────────────────────────────────────────────────────
log_trace "--- main: guards ---"

# Any install reaching main's body is recorded; guarded runs must record nothing.
main_guard() {  # main_guard <is_osx> <skip_gui>  — run main in a subshell, print install calls
  (
    # shellcheck disable=SC2317,SC2329  # called indirectly by main
    install_or_upgrade_cask_package() { echo "cask $1"; }
    _is_osx=$1 _skip_gui=$2
    HOME="${tmpdir}/main-home" main
  )
}
assert_eq "main on non-macOS: no installs" "" "$(main_guard false false)"
assert_eq "main in headless mode: no installs" "" "$(main_guard true true)"

finish_test
