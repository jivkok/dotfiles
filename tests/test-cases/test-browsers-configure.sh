#!/usr/bin/env bash
set -euo pipefail

HELPERS="$(cd "$(dirname "$0")/helpers" && pwd)"

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

# shellcheck source=helpers/browsers-functions.sh
source "${HELPERS}/browsers-functions.sh"

# ── Temp workspace ────────────────────────────────────────────────────────────
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

# ── create_firefox_profile_if_absent — static profile paths ──────────────────
log_trace "--- create_firefox_profile_if_absent ---"

app_support="${tmpdir}/FirefoxTest"

# First call: creates profile dir at static path and profiles.ini
create_firefox_profile_if_absent "$app_support" "jk-default" 1
assert_dir "${app_support}/Profiles/jk-default"
assert_file_exists "${app_support}/profiles.ini"
assert_file_content "${app_support}/profiles.ini" "Name=jk-default"
assert_file_content "${app_support}/profiles.ini" "IsRelative=1"
assert_file_content "${app_support}/profiles.ini" "Path=Profiles/jk-default"
assert_file_content "${app_support}/profiles.ini" "Default=1"

# Second call with same name: idempotent, no duplicate entry
create_firefox_profile_if_absent "$app_support" "jk-default" 1
count="$(grep -c "Name=jk-default" "${app_support}/profiles.ini")"
assert_eq "idempotent: no duplicate profile entry" "1" "$count"

# Second distinct profile: appended to existing ini, both entries present
create_firefox_profile_if_absent "$app_support" "jk-research-trusted"
assert_dir "${app_support}/Profiles/jk-research-trusted"
assert_file_content "${app_support}/profiles.ini" "Name=jk-research-trusted"
assert_file_content "${app_support}/profiles.ini" "Name=jk-default"

# Third profile
create_firefox_profile_if_absent "$app_support" "jk-research-private"
assert_dir "${app_support}/Profiles/jk-research-private"
assert_file_content "${app_support}/profiles.ini" "Name=jk-research-private"

# No hashed directory names anywhere
hash_dirs="$(find "${app_support}/Profiles" -maxdepth 1 -type d -name "*.*" 2>/dev/null | wc -l | tr -d ' ')"
assert_eq "no hashed directory names" "0" "$hash_dirs"

# ── ensure_firefox_profiles_ini — idempotency on pre-existing file ────────────
log_trace "--- ensure_firefox_profiles_ini: pre-existing file ---"

ini_test="${tmpdir}/IniTest"
mkdir -p "$ini_test"
# Simulate a profiles.ini that Firefox already wrote with jk-default
printf '[General]\nStartWithLastProfile=0\n\n[Profile0]\nName=jk-default\nIsRelative=1\nPath=Profiles/jk-default\nDefault=1\n' \
  > "${ini_test}/profiles.ini"

# Calling ensure for existing entry must not duplicate it
ensure_firefox_profiles_ini "$ini_test" "jk-default" 1
count="$(grep -c "Name=jk-default" "${ini_test}/profiles.ini")"
assert_eq "ensure_ini: no duplicate when entry already present" "1" "$count"

# Calling ensure for missing entry must append it using next available index
ensure_firefox_profiles_ini "$ini_test" "jk-research-trusted"
assert_file_content "${ini_test}/profiles.ini" "Name=jk-research-trusted"
# Original entry still present
assert_file_content "${ini_test}/profiles.ini" "Name=jk-default"
# Index must not collide — both [Profile0] and [Profile1] should be present
assert_file_content "${ini_test}/profiles.ini" "Profile0"
assert_file_content "${ini_test}/profiles.ini" "Profile1"

# ── write_firefox_prefs_js ─────────────────────────────────────────────────────
log_trace "--- write_firefox_prefs_js ---"

userjs_dir="${tmpdir}/UserJsTest"
mkdir -p "$userjs_dir"

write_firefox_prefs_js "$userjs_dir" 'user_pref("network.cookie.lifetimePolicy", 2);'
assert_file_exists "${userjs_dir}/prefs.js"
assert_file_content "${userjs_dir}/prefs.js" '"network.cookie.lifetimePolicy"'

# No-op when directory does not exist: no prefs.js created
nonexistent="${tmpdir}/does-not-exist"
write_firefox_prefs_js "$nonexistent" 'user_pref("dom.security.https_only_mode", false);'
assert_file_absent "${nonexistent}/prefs.js"

# ── install_firefox_extension — using stub XPI file ──────────────────────────
log_trace "--- install_firefox_extension ---"

xpi_serve_dir="${tmpdir}/xpi_serve"
mkdir -p "${xpi_serve_dir}/ublock-origin" "${xpi_serve_dir}/vimium-ff"
printf 'PK\x03\x04fake-xpi-content' > "${xpi_serve_dir}/ublock-origin/latest.xpi"
printf 'PK\x03\x04fake-xpi-content' > "${xpi_serve_dir}/vimium-ff/latest.xpi"

export AMO_BASE_URL="file://${xpi_serve_dir}"

ext_profile="${tmpdir}/ext-test-profile"
mkdir -p "$ext_profile"

install_firefox_extension "$ext_profile" "uBlock0@raymondhill.net" "ublock-origin"
assert_file_exists "${ext_profile}/extensions/uBlock0@raymondhill.net.xpi"

install_firefox_extension "$ext_profile" "{d07ccf11-c0cd-4938-a265-2a4d6ad01189}" "vimium-ff"
assert_file_exists "${ext_profile}/extensions/{d07ccf11-c0cd-4938-a265-2a4d6ad01189}.xpi"

# Idempotent: calling again does not error and file still present
install_firefox_extension "$ext_profile" "uBlock0@raymondhill.net" "ublock-origin"
assert_file_exists "${ext_profile}/extensions/uBlock0@raymondhill.net.xpi"

# Verify extensions dir created automatically
ext_profile2="${tmpdir}/ext-test-profile2"
install_firefox_extension "$ext_profile2" "uBlock0@raymondhill.net" "ublock-origin"
assert_dir "${ext_profile2}/extensions"
assert_file_exists "${ext_profile2}/extensions/uBlock0@raymondhill.net.xpi"

# ── install_firefox_extension — failure: slug not found ──────────────────────
log_trace "--- install_firefox_extension: failure on missing slug ---"

ext_profile3="${tmpdir}/ext-test-profile3"
mkdir -p "$ext_profile3"
if install_firefox_extension "$ext_profile3" "test@example.com" "nonexistent-slug" 2>/dev/null; then
  fail "install_firefox_extension: should fail on missing slug"
else
  ok "install_firefox_extension: returns non-zero for missing slug"
fi
assert_file_absent "${ext_profile3}/extensions/test@example.com.xpi"

unset AMO_BASE_URL

# ── Summary ───────────────────────────────────────────────────────────────────
finish_test
