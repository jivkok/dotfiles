#!/usr/bin/env bash
# Standalone definitions of the testable functions from osx/configure_browsers.sh.
# Kept in sync with configure_browsers.sh.  Source this file in tests instead of
# sourcing configure_browsers.sh directly (the main script is not bind-mounted in
# Docker test environments).

# ensure_firefox_profiles_ini <app_support_dir> <profile_name> [default=0|1]
# Ensures the named profile entry exists in profiles.ini.
# If the file does not yet exist, writes the [General] header first.
# Appends the profile entry if not already present, using the next available
# [ProfileN] index computed from the file — avoids collisions with entries
# written by Firefox itself before this script ran.
# Never overwrites the whole file.
ensure_firefox_profiles_ini() {
  local app_support_dir="$1"
  local profile_name="$2"
  local is_default="${3:-0}"
  local ini="${app_support_dir}/profiles.ini"

  mkdir -p "$app_support_dir"

  if [[ ! -f "$ini" ]]; then
    printf '[General]\nStartWithLastProfile=0\n' > "$ini"
  fi

  if ! grep -q "^Name=${profile_name}$" "$ini" 2>/dev/null; then
    # Next available index — avoids collisions if Firefox already wrote its own entries
    local idx
    idx=$(grep -c '^\[Profile[0-9]' "$ini" 2>/dev/null || true)
    : "${idx:=0}"
    printf '\n[Profile%d]\nName=%s\nIsRelative=1\nPath=Profiles/%s\n' \
      "$idx" "$profile_name" "$profile_name" >> "$ini"
    if [[ "$is_default" == "1" ]]; then
      printf 'Default=1\n' >> "$ini"
    fi
  fi
}

# create_firefox_profile_if_absent <app_support_dir> <profile_name> [default=0|1]
# Creates the profile directory at a fixed path (no hash) and registers it in profiles.ini.
# Idempotent: no-op if directory already exists.
create_firefox_profile_if_absent() {
  local app_support_dir="$1"
  local profile_name="$2"
  local is_default="${3:-0}"
  local profiles_root="${app_support_dir}/Profiles"
  local profile_dir="${profiles_root}/${profile_name}"

  mkdir -p "$profile_dir"

  ensure_firefox_profiles_ini "$app_support_dir" "$profile_name" "$is_default"
}

# write_firefox_prefs_js <profile_dir> <content>
# Writes prefs.js directly into the given profile directory.
# No-op (silently) if the directory does not exist.
write_firefox_prefs_js() {
  local profile_dir="$1"
  local content="$2"
  if [[ -d "$profile_dir" ]]; then
    printf '%s\n' "$content" > "${profile_dir}/prefs.js"
  fi
}

# install_firefox_extension <profile_dir> <extension_id> <amo_slug>
# Downloads the XPI from AMO and places it in <profile_dir>/extensions/.
# Validates the downloaded file is not zero-byte or an HTML error page.
# Idempotent: skips if the .xpi file is already present.
# In tests, AMO_BASE_URL can be overridden to use a local server.
install_firefox_extension() {
  local profile_dir="$1"
  local ext_id="$2"
  local amo_slug="$3"
  local ext_dir="${profile_dir}/extensions"
  local xpi_path="${ext_dir}/${ext_id}.xpi"
  local base_url="${AMO_BASE_URL:-https://addons.mozilla.org/firefox/downloads/latest}"
  local url="${base_url}/${amo_slug}/latest.xpi"

  mkdir -p "$ext_dir"

  if [[ -f "$xpi_path" ]]; then
    return 0
  fi

  local tmp
  tmp="$(mktemp)"
  local http_status
  http_status="$(curl -sS -L -w "%{http_code}" -o "$tmp" "$url" 2>/dev/null)"
  local curl_exit=$?
  # file:// URIs return status "000"; treat as success for local test stubs.
  local expected_status="200"
  if [[ "$url" == file://* ]]; then expected_status="000"; fi
  if [[ $curl_exit -ne 0 || "$http_status" != "$expected_status" ]]; then
    rm -f "$tmp"
    return 1
  fi
  if file "$tmp" 2>/dev/null | grep -qi "HTML"; then
    rm -f "$tmp"
    return 1
  fi
  if [[ ! -s "$tmp" ]]; then
    rm -f "$tmp"
    return 1
  fi
  mv "$tmp" "$xpi_path"
}
