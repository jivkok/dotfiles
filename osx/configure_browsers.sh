#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'
# Configure browsers (macOS only).
#
# Installs Firefox-family browsers via Homebrew cask and applies
# privacy-oriented configuration: XPI extensions (dropped into profile
# extensions/ directories), prefs.js (preferences), Firefox profiles,
# and Safari defaults.
#
# Manual post-install steps (not automatable):
#   1. Safari → Settings → Privacy → "Prevent cross-site tracking": enable
#   2. Safari → Settings → Privacy → "Hide IP Address" → "Trackers and Websites"
#   3. Firefox → Multi-Account Containers → create: Personal, Work, Shopping, Social

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

# macOS only
if ! $_is_osx; then
  log_trace "configure_browsers.sh: skipping (not macOS)."
  exit 0
fi

# ─── Helper functions ────────────────────────────────────────────────────────

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
# Creates the profile directory at a fixed static path (no hash) and registers
# it in profiles.ini.  Idempotent: no-op if directory already exists.
create_firefox_profile_if_absent() {
  local app_support_dir="$1"
  local profile_name="$2"
  local is_default="${3:-0}"
  local profiles_root="${app_support_dir}/Profiles"
  local profile_dir="${profiles_root}/${profile_name}"

  log_trace "Ensuring profile: $profile_name"
  mkdir -p "$profile_dir"

  ensure_firefox_profiles_ini "$app_support_dir" "$profile_name" "$is_default"
}

# install_firefox_extension <profile_dir> <extension_id> <amo_slug>
# Downloads the XPI from AMO and places it in <profile_dir>/extensions/.
# Validates the downloaded file is not zero-byte or an HTML error page.
# Idempotent: skips if the .xpi file is already present.
install_firefox_extension() {
  local profile_dir="$1"
  local ext_id="$2"
  local amo_slug="$3"
  local ext_dir="${profile_dir}/extensions"
  local xpi_path="${ext_dir}/${ext_id}.xpi"
  local url="${AMO_BASE_URL:-https://addons.mozilla.org/firefox/downloads/latest}/${amo_slug}/latest.xpi"

  mkdir -p "$ext_dir"

  if [[ -f "$xpi_path" ]]; then
    log_trace "extension already present: ${ext_id}"
    return 0
  fi

  log_trace "downloading extension: ${ext_id} (${amo_slug})"
  if ! download_file "$url" "$xpi_path"; then
    log_error "failed to download extension ${ext_id}"
    return 1
  fi
  if file "$xpi_path" 2>/dev/null | grep -qi "HTML"; then
    rm -f "$xpi_path"
    log_error "extension download returned HTML page for ${ext_id}"
    return 1
  fi
  if [[ ! -s "$xpi_path" ]]; then
    rm -f "$xpi_path"
    log_error "extension download returned empty file for ${ext_id}"
    return 1
  fi
  log_trace "installed extension: ${ext_id}"
}

# write_firefox_prefs_js <profile_dir> <content>
# Writes prefs.js directly into the given profile directory.
# No-op (silently) if the directory does not exist.
write_firefox_prefs_js() {
  local profile_dir="$1"
  local content="$2"
  if [[ -d "$profile_dir" ]]; then
    log_trace "Writing prefs.js → $profile_dir"
    printf '%s\n' "$content" > "${profile_dir}/prefs.js"
  else
    log_trace "Profile dir not found, skipping prefs.js: $profile_dir"
  fi
}

# install_extensions_into_profile <profile_dir> <ext_id_1> <amo_slug_1> [...]
# Installs extensions into a single profile directory.
install_extensions_into_profile() {
  local profile_dir="$1"
  shift
  local args=("$@")
  local i=0
  while [[ $i -lt ${#args[@]} ]]; do
    install_firefox_extension "$profile_dir" "${args[$i]}" "${args[$((i + 1))]}"
    i=$((i + 2))
  done
}

# ─── Install browsers ────────────────────────────────────────────────────────

log_info "Installing browsers ..."

install_or_upgrade_cask_package firefox
install_or_upgrade_cask_package firefox@developer-edition
install_or_upgrade_cask_package mullvad-browser
install_or_upgrade_cask_package duckduckgo
install_or_upgrade_cask_package tor-browser
install_or_upgrade_cask_package microsoft-edge
install_or_upgrade_cask_package google-chrome
install_or_upgrade_cask_package opera

# ─── Firefox — profiles and prefs.js ─────────────────────────────────────────

FF_APP_SUPPORT="${HOME}/Library/Application Support/Firefox"
FF_PROFILES="${FF_APP_SUPPORT}/Profiles"

log_info "Configuring Firefox profiles ..."
create_firefox_profile_if_absent "$FF_APP_SUPPORT" "jk-default"          1
create_firefox_profile_if_absent "$FF_APP_SUPPORT" "jk-research-trusted"
create_firefox_profile_if_absent "$FF_APP_SUPPORT" "jk-research-private"

# Common prefs applied to all three Firefox stable profiles.
# Note: category="strict" causes Firefox to manage ETP sub-prefs internally;
# the individual sub-prefs below are set explicitly so they hold regardless of
# Firefox's internal processing order at startup.
FF_COMMON_PREFS='// Telemetry / health reporting
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.enabled", false);

// Enhanced Tracking Protection: Strict
user_pref("browser.contentblocking.category", "strict");
user_pref("browser.contentblocking.trackingprotection.enabled", true);

// Crash reports
user_pref("breakpad.reportURL", "");
user_pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);

// Various suggestions / autocomplete
user_pref("browser.urlbar.suggest.searches", false);
user_pref("browser.search.suggest.enabled", false);
user_pref("browser.urlbar.suggest.quicksuggest", false);
user_pref("browser.urlbar.quicksuggest.dataCollection.enabled", false);

// Disable default-browser nag
user_pref("browser.shell.checkDefaultBrowser", false);

// Network-state / cache partitioning (anti-tracking)
user_pref("privacy.partition.network_state", true);

// New-Tab page de-bloat
user_pref("browser.newtabpage.activity-stream.enabled", false);
user_pref("browser.newtabpage.activity-stream.showSearch", false);
user_pref("browser.newtabpage.activity-stream.showTopSites", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.showWeather", false);
user_pref("browser.newtabpage.activity-stream.system.showWeather", false);
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);

// Tracking protection
user_pref("privacy.trackingprotection.enabled", true);
user_pref("privacy.trackingprotection.socialtracking.enabled", true);
user_pref("privacy.trackingprotection.cryptomining.enabled", true);
user_pref("privacy.trackingprotection.fingerprinting.enabled", true);

// DNS over HTTPS: Cloudflare — strict mode (no OS DNS fallback)
user_pref("network.trr.mode", 3);
user_pref("network.trr.uri", "https://mozilla.cloudflare-dns.com/dns-query");
user_pref("network.trr.disable-ECS", true);'

FF_DEFAULT_PREFS='user_pref("network.cookie.cookieBehavior", 1);
user_pref("browser.sessionstore.privacy_level", 0);
user_pref("browser.sessionstore.restore_on_demand", false);'

FF_RESEARCH_TRUSTED_PREFS='user_pref("network.cookie.cookieBehavior", 2);
user_pref("browser.sessionstore.privacy_level", 0);
user_pref("browser.sessionstore.restore_on_demand", false);'

FF_RESEARCH_PRIVATE_PREFS='// privacy.resistFingerprinting: timezone→UTC, canvas randomised, screen/UA spoofed
user_pref("privacy.resistFingerprinting", true);
user_pref("network.cookie.cookieBehavior", 2);
user_pref("browser.sessionstore.privacy_level", 2);
user_pref("browser.sessionstore.restore_on_demand", true);'

write_firefox_prefs_js "${FF_PROFILES}/jk-default" \
  "// Profile: jk-default — cookies and session restore

${FF_COMMON_PREFS}

${FF_DEFAULT_PREFS}"

write_firefox_prefs_js "${FF_PROFILES}/jk-research-trusted" \
  "// Profile: jk-research-trusted — cookies and session restore

${FF_COMMON_PREFS}

${FF_RESEARCH_TRUSTED_PREFS}"

write_firefox_prefs_js "${FF_PROFILES}/jk-research-private" \
  "// Profile: jk-research-private — fingerprinting resistance, cookies, stateless session

${FF_COMMON_PREFS}

${FF_RESEARCH_PRIVATE_PREFS}"

# ─── Firefox — extensions via XPI drop-in ────────────────────────────────────
# Extension table (profile → extensions):
#   jk-default:          ublock, new-tab-override, containers, vimium, stylus, sidebery
#   jk-research-trusted: ublock, new-tab-override, containers, vimium, joplin, stylus, sidebery
#   jk-research-private: ublock, new-tab-override, vimium, joplin, stylus, noscript, sidebery

log_info "Installing Firefox extensions via XPI ..."

install_extensions_into_profile "${FF_PROFILES}/jk-default" \
  "uBlock0@raymondhill.net"                    "ublock-origin" \
  "{ab5d7449-f2be-4db7-91d9-aaab5e59ddcc}"     "new-tab-override" \
  "@testpilot-containers"                       "multi-account-containers" \
  "{d07ccf11-c0cd-4938-a265-2a4d6ad01189}"      "vimium-ff" \
  "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}"      "styl-us" \
  "{3c078156-979c-498b-8990-85f7987dd929}"       "sidebery"

install_extensions_into_profile "${FF_PROFILES}/jk-research-trusted" \
  "uBlock0@raymondhill.net"                    "ublock-origin" \
  "{ab5d7449-f2be-4db7-91d9-aaab5e59ddcc}"     "new-tab-override" \
  "@testpilot-containers"                       "multi-account-containers" \
  "{d07ccf11-c0cd-4938-a265-2a4d6ad01189}"      "vimium-ff" \
  "joplin-web-clipper@joplin.cloud"             "joplin-web-clipper" \
  "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}"      "styl-us" \
  "{3c078156-979c-498b-8990-85f7987dd929}"       "sidebery"

install_extensions_into_profile "${FF_PROFILES}/jk-research-private" \
  "uBlock0@raymondhill.net"                    "ublock-origin" \
  "{ab5d7449-f2be-4db7-91d9-aaab5e59ddcc}"     "new-tab-override" \
  "{d07ccf11-c0cd-4938-a265-2a4d6ad01189}"      "vimium-ff" \
  "joplin-web-clipper@joplin.cloud"             "joplin-web-clipper" \
  "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}"      "styl-us" \
  "{73a6fe31-595d-460b-a920-fcc0f8843232}"       "noscript" \
  "{3c078156-979c-498b-8990-85f7987dd929}"       "sidebery"

# ─── Firefox Developer Edition — profiles and prefs.js ───────────────────────
# Firefox Developer Edition shares the same app support directory and profiles.ini
# as Firefox stable. Dev Edition profiles are distinguished by name only.

log_info "Configuring Firefox Developer Edition profiles ..."
create_firefox_profile_if_absent "$FF_APP_SUPPORT" "jk-dev-local"
create_firefox_profile_if_absent "$FF_APP_SUPPORT" "jk-home-network"

# Common prefs for both Dev Edition profiles.
# Subset of FF_COMMON_PREFS — excludes ETP, tracking protection, and DoH
# which would interfere with local dev and homelab work.
FFDX_COMMON_PREFS='// Telemetry / health reporting
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.enabled", false);

// Crash reports
user_pref("breakpad.reportURL", "");
user_pref("browser.crashReports.unsubmittedCheck.autoSubmit2", false);

// Various suggestions / autocomplete
user_pref("browser.urlbar.suggest.searches", false);
user_pref("browser.search.suggest.enabled", false);
user_pref("browser.urlbar.suggest.quicksuggest", false);
user_pref("browser.urlbar.quicksuggest.dataCollection.enabled", false);

// Disable default-browser nag
user_pref("browser.shell.checkDefaultBrowser", false);

// New-Tab page de-bloat
user_pref("browser.newtabpage.activity-stream.enabled", false);
user_pref("browser.newtabpage.activity-stream.showSearch", false);
user_pref("browser.newtabpage.activity-stream.showTopSites", false);
user_pref("browser.newtabpage.activity-stream.showSponsored", false);
user_pref("browser.newtabpage.activity-stream.showSponsoredTopSites", false);
user_pref("browser.newtabpage.activity-stream.showWeather", false);
user_pref("browser.newtabpage.activity-stream.system.showWeather", false);
user_pref("browser.newtabpage.activity-stream.feeds.topsites", false);
user_pref("browser.newtabpage.activity-stream.feeds.telemetry", false);
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);'

FFDX_HOME_NETWORK_PREFS='// Disable HTTPS-only mode for local services
user_pref("dom.security.https_only_mode", false);

// Disable tracking protection for local network
user_pref("privacy.trackingprotection.enabled", false);
user_pref("network.trr.mode", 0);'

write_firefox_prefs_js "${FF_PROFILES}/jk-dev-local" \
  "// Profile: jk-dev-local

${FFDX_COMMON_PREFS}"

write_firefox_prefs_js "${FF_PROFILES}/jk-home-network" \
  "// Profile: jk-home-network — local services, no HTTPS enforcement

${FFDX_COMMON_PREFS}

${FFDX_HOME_NETWORK_PREFS}"

# ─── Firefox Developer Edition — extensions via XPI drop-in ──────────────────
# Both profiles get: vimium-ff, new-tab-override

log_info "Installing Firefox Developer Edition extensions via XPI ..."

install_extensions_into_profile "${FF_PROFILES}/jk-dev-local" \
  "{d07ccf11-c0cd-4938-a265-2a4d6ad01189}"  "vimium-ff" \
  "{ab5d7449-f2be-4db7-91d9-aaab5e59ddcc}"  "new-tab-override"

install_extensions_into_profile "${FF_PROFILES}/jk-home-network" \
  "{d07ccf11-c0cd-4938-a265-2a4d6ad01189}"  "vimium-ff" \
  "{ab5d7449-f2be-4db7-91d9-aaab5e59ddcc}"  "new-tab-override"

# ─── Safari — scriptable defaults ────────────────────────────────────────────
# macOS 15+ (Sequoia) gates the Safari container behind Full Disk Access (TCC).
# Probe the Preferences directory: if ls fails with EPERM, FDA is not granted.

log_info "Configuring Safari ..."

SAFARI_CONTAINER="${HOME}/Library/Containers/com.apple.Safari"
SAFARI_PREFS_DIR="${SAFARI_CONTAINER}/Data/Library/Preferences"
SAFARI_PREFS="${SAFARI_PREFS_DIR}/com.apple.Safari"

if ! ls "$SAFARI_PREFS_DIR" &>/dev/null; then
  log_trace "Safari: Full Disk Access not granted — apply these settings manually in Safari → Settings:"
  log_trace "  General  → \"Open 'safe' files after downloading\": uncheck"
  log_trace "  Search   → \"Include Safari Suggestions\": uncheck"
  log_trace "  Search   → \"Enable Quick Website Search\": uncheck"
  log_trace "  Privacy  → \"Prevent cross-site tracking\": check"
  log_trace "  Privacy  → \"Hide IP Address\": Trackers and Websites"
  log_trace "  Advanced → \"Warn when visiting a fraudulent website\": check"
  log_trace "  Advanced → (Websites tab) \"Block pop-up windows\": check"
else
  defaults write "$SAFARI_PREFS" AutoOpenSafeDownloads -bool false
  defaults write "$SAFARI_PREFS" SuppressSearchSuggestions -bool true
  defaults write "$SAFARI_PREFS" UniversalSearchEnabled -bool false
  defaults write "$SAFARI_PREFS" SendDoNotTrackHTTPHeader -bool true
  defaults write "$SAFARI_PREFS" WarnAboutFraudulentWebsites -bool true
  defaults write "$SAFARI_PREFS" WebKitJavaScriptCanOpenWindowsAutomatically -bool false
  defaults write "$SAFARI_PREFS" \
    "com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptCanOpenWindowsAutomatically" \
    -bool false
fi

log_trace "Manual steps required — see script header."
log_info "Installing browsers done."
