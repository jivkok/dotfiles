#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'
# Configure browsers (macOS only).
#
# Installs Firefox-family browsers via Homebrew cask and applies
# privacy-oriented configuration: user.js preferences, XPI extensions
# (dropped into profile extensions/ directories), and Safari defaults.
#
# Firefox profiles are created fully by this script using Firefox's own
# internal format: profiles.ini entry, profile directory, and Profile Group
# SQLite database (required by Firefox 128+ for profiles to appear in the
# profile chooser).  Fully idempotent — safe to re-run at any time.
#
# Manual post-install steps (not automatable):
#   Safari:
#     1. Safari → Settings → Privacy → "Prevent cross-site tracking": enable
#     2. Safari → Settings → Privacy → "Hide IP Address" → "Trackers and Websites"
#   Firefox:
#     3. Multi-Account Containers → create: Family, Finances, Homelab, Personal,
#        Sandbox, Sandbox2, Shopping, Social, Work

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

# macOS only
if ! $_is_osx; then
  log_trace "configure_browsers.sh: skipping (not macOS)."
  exit 0
fi

# ─── Helper functions ────────────────────────────────────────────────────────

# create_firefox_profile <app_support_dir> <profile_name> [is_default=0|1]
# Creates a Firefox profile with all components required by Firefox 128+:
#   - profiles.ini entry with StoreID and ShowSelector=1
#   - Profile directory at Profiles/{storeId}.{profile_name}
#   - Profile Group SQLite database (makes the profile visible in the card chooser)
# Idempotent: if the profile is already in profiles.ini the existing directory
# is returned; the SQLite database is created/repaired if missing.
# Prints the full profile directory path to stdout.
create_firefox_profile() {
  local app_support_dir="$1"
  local profile_name="$2"
  local is_default="${3:-0}"
  local ini="${app_support_dir}/profiles.ini"
  local groups_dir="${app_support_dir}/Profile Groups"

  mkdir -p "${app_support_dir}/Profiles" "$groups_dir"

  # Initialise profiles.ini if it does not yet exist.
  # StartWithLastProfile=0 causes Firefox to show the profile chooser on first
  # launch so the user can verify and select the desired default profile.
  if [[ ! -f "$ini" ]]; then
    printf '[General]\nStartWithLastProfile=0\nVersion=2\n' > "$ini"
    log_trace "Created profiles.ini" >&2
  fi

  # Read existing StoreID and Path for this profile name in one awk pass.
  # Outputs "<storeId> <relativePath>" if registered, or "-  <relativePath>"
  # when the profile exists but has no StoreID (e.g. created via about:profiles).
  local existing
  existing=$(awk -v name="$profile_name" '
    BEGIN { in_target=0 }
    /^\[/                    { if (in_target) exit; in_target=0 }
    $0 == "Name=" name       { in_target=1 }
    in_target && /^Path=/    { path=substr($0,6) }
    in_target && /^StoreID=/ { store=substr($0,9) }
    END                      { if (path) print (store != "" ? store : "-") " " path }
  ' "$ini" 2>/dev/null)

  local store_id rel_path profile_dir

  if [[ -n "$existing" ]]; then
    store_id="${existing%% *}"
    rel_path="${existing#* }"
    profile_dir="${app_support_dir}/${rel_path}"

    if [[ "$store_id" == "-" ]]; then
      # Profile exists in profiles.ini without StoreID — assign one now so the
      # profile appears in the Firefox 128+ card chooser.
      store_id=$(openssl rand -hex 4)
      local tmp; tmp=$(mktemp)
      awk -v name="$profile_name" -v sid="$store_id" '
        !inserted && $0 == "Name=" name {
          print
          printf "StoreID=%s\nShowSelector=1\n", sid
          inserted=1; next
        }
        { print }
      ' "$ini" > "$tmp" && mv -f "$tmp" "$ini"
      log_trace "Assigned StoreID ${store_id} to: ${profile_name}" >&2
    else
      log_trace "Profile already registered: ${profile_name} (${store_id})" >&2
    fi

    mkdir -p "$profile_dir"
  else
    # First time: generate IDs, create directory, append profiles.ini entry.
    store_id=$(openssl rand -hex 4)
    rel_path="Profiles/${store_id}.${profile_name}"
    profile_dir="${app_support_dir}/${rel_path}"
    mkdir -p "$profile_dir"

    local idx
    idx=$(awk '
      BEGIN { max=-1 }
      /^\[Profile/ { sub(/^\[Profile/,""); sub(/\].*/,""); if ($0+0 > max) max=$0+0 }
      END { print max+1 }
    ' "$ini" 2>/dev/null)
    : "${idx:=0}"

    {
      printf '\n[Profile%d]\n' "$idx"
      printf 'Name=%s\n'       "$profile_name"
      printf 'IsRelative=1\n'
      printf 'Path=%s\n'       "$rel_path"
      printf 'StoreID=%s\n'    "$store_id"
      printf 'ShowSelector=1\n'
      [[ "$is_default" == "1" ]] && printf 'Default=1\n'
    } >> "$ini"

    log_trace "Created profile: ${profile_name} (${store_id})" >&2
  fi

  # Ensure the Profile Group SQLite database exists and contains this profile.
  # CREATE TABLE IF NOT EXISTS and INSERT OR IGNORE make this fully idempotent.
  local db="${groups_dir}/${store_id}.sqlite"
  sqlite3 "$db" <<SQL
CREATE TABLE IF NOT EXISTS "Profiles" (
  id INTEGER NOT NULL, path TEXT NOT NULL UNIQUE, name TEXT NOT NULL,
  avatar TEXT NOT NULL, themeId TEXT NOT NULL, themeFg TEXT NOT NULL,
  themeBg TEXT NOT NULL, PRIMARY KEY(id));
CREATE TABLE IF NOT EXISTS "SharedPrefs" (
  id INTEGER NOT NULL, name TEXT NOT NULL UNIQUE, value BLOB,
  isBoolean INTEGER, PRIMARY KEY(id));
CREATE TABLE IF NOT EXISTS "NimbusEnrollments" (
  id INTEGER NOT NULL, profileId INTEGER NOT NULL, slug TEXT NOT NULL,
  branchSlug TEXT NOT NULL, recipe JSONB, active BOOLEAN NOT NULL,
  unenrollReason TEXT, lastSeen TEXT NOT NULL, setPrefs JSONB,
  prefFlips JSONB, source TEXT NOT NULL, PRIMARY KEY(id),
  UNIQUE (profileId, slug) ON CONFLICT FAIL);
CREATE TABLE IF NOT EXISTS "Heartbeats" (
  id INTEGER NOT NULL, recipeId TEXT NOT NULL UNIQUE,
  lastShown INTEGER, lastInteraction INTEGER, PRIMARY KEY(id));
CREATE TABLE IF NOT EXISTS "MessagingSystemMessageImpressions" (
  id INTEGER PRIMARY KEY, messageId TEXT UNIQUE NOT NULL, impressions JSONB);
CREATE TABLE IF NOT EXISTS "MessagingSystemMessageBlocklist" (
  id INTEGER PRIMARY KEY, messageId TEXT UNIQUE NOT NULL);
CREATE TABLE IF NOT EXISTS "NimbusSyncTimestamps" (
  id INTEGER NOT NULL, profileId TEXT NOT NULL, collection TEXT NOT NULL,
  lastModified INTEGER NOT NULL, PRIMARY KEY(id),
  UNIQUE (profileId, collection) ON CONFLICT FAIL);
INSERT OR IGNORE INTO Profiles (id, path, name, avatar, themeId, themeFg, themeBg)
VALUES (1, '${rel_path}', '${profile_name}', 'book',
        'default-theme@mozilla.org', 'rgb(255,255,255)', 'rgb(28,27,34)');
SQL

  printf '%s' "$profile_dir"
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

# write_firefox_user_js <profile_dir> <content>
# Writes user.js into the given profile directory.
#
# Why user.js and not prefs.js:
#   Firefox owns prefs.js — it writes runtime state there and would conflict
#   with direct edits. user.js is the designated override mechanism: Firefox
#   reads it at every startup and re-applies its values on top of prefs.js.
#   This means the script's privacy settings are always enforced, while
#   prefs.js (and any user changes stored there) is left untouched.
#
# Trade-off: preferences listed here are effectively "locked" — a user
#   changing them in the UI will have the change reverted at next Firefox
#   restart. That is intentional for privacy hardening settings.
write_firefox_user_js() {
  local profile_dir="$1"
  local content="$2"
  log_trace "Writing user.js → $profile_dir"
  printf '%s\n' "$content" > "${profile_dir}/user.js"
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

# ─── Firefox — profiles, user.js and extensions ──────────────────────────────

FF_APP_SUPPORT="${HOME}/Library/Application Support/Firefox"

log_info "Configuring Firefox profiles ..."

ff_default_dir=$(create_firefox_profile "$FF_APP_SUPPORT" "jk-default"          1)
ff_trusted_dir=$(create_firefox_profile "$FF_APP_SUPPORT" "jk-research-trusted"  )
ff_private_dir=$(create_firefox_profile "$FF_APP_SUPPORT" "jk-research-private"  )
ff_home_net_dir=$(create_firefox_profile "$FF_APP_SUPPORT" "jk-home-network"     )

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

# Prefs for local-service profiles — excludes ETP, tracking protection, and DoH
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

write_firefox_user_js "$ff_default_dir" \
  "// Profile: jk-default — cookies and session restore

${FF_COMMON_PREFS}

${FF_DEFAULT_PREFS}"

write_firefox_user_js "$ff_trusted_dir" \
  "// Profile: jk-research-trusted — cookies and session restore

${FF_COMMON_PREFS}

${FF_RESEARCH_TRUSTED_PREFS}"

write_firefox_user_js "$ff_private_dir" \
  "// Profile: jk-research-private — fingerprinting resistance, cookies, stateless session

${FF_COMMON_PREFS}

${FF_RESEARCH_PRIVATE_PREFS}"

write_firefox_user_js "$ff_home_net_dir" \
  "// Profile: jk-home-network — local services, no HTTPS enforcement

${FFDX_COMMON_PREFS}

${FFDX_HOME_NETWORK_PREFS}"

# ─── Firefox — extensions via XPI drop-in ────────────────────────────────────
# Extension table (profile → extensions):
#   jk-default:          ublock, containers, vimium, stylus, sidebery
#   jk-research-trusted: ublock, containers, vimium, joplin, stylus, sidebery
#   jk-research-private: ublock, vimium, joplin, stylus, noscript, sidebery
#   jk-home-network:     vimium

log_info "Installing Firefox extensions via XPI ..."

install_extensions_into_profile "$ff_default_dir" \
  "uBlock0@raymondhill.net"                    "ublock-origin" \
  "@testpilot-containers"                       "multi-account-containers" \
  "{d07ccf11-c0cd-4938-a265-2a4d6ad01189}"      "vimium-ff" \
  "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}"      "styl-us" \
  "{3c078156-979c-498b-8990-85f7987dd929}"       "sidebery"

install_extensions_into_profile "$ff_trusted_dir" \
  "uBlock0@raymondhill.net"                    "ublock-origin" \
  "@testpilot-containers"                       "multi-account-containers" \
  "{d07ccf11-c0cd-4938-a265-2a4d6ad01189}"      "vimium-ff" \
  "joplin-web-clipper@joplin.cloud"             "joplin-web-clipper" \
  "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}"      "styl-us" \
  "{3c078156-979c-498b-8990-85f7987dd929}"       "sidebery"

install_extensions_into_profile "$ff_private_dir" \
  "uBlock0@raymondhill.net"                    "ublock-origin" \
  "{d07ccf11-c0cd-4938-a265-2a4d6ad01189}"      "vimium-ff" \
  "joplin-web-clipper@joplin.cloud"             "joplin-web-clipper" \
  "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}"      "styl-us" \
  "{73a6fe31-595d-460b-a920-fcc0f8843232}"       "noscript" \
  "{3c078156-979c-498b-8990-85f7987dd929}"       "sidebery"

install_extensions_into_profile "$ff_home_net_dir" \
  "{d07ccf11-c0cd-4938-a265-2a4d6ad01189}"  "vimium-ff"

# ─── Firefox Developer Edition — profiles, user.js and extensions ─────────────
# Firefox Developer Edition uses its own app support directory on macOS,
# separate from Firefox stable.

FFDX_APP_SUPPORT="${HOME}/Library/Application Support/Firefox Developer Edition"

log_info "Configuring Firefox Developer Edition profiles ..."

ffdx_dev_local_dir=$(create_firefox_profile "$FFDX_APP_SUPPORT" "jk-dev-local")

write_firefox_user_js "$ffdx_dev_local_dir" \
  "// Profile: jk-dev-local

${FFDX_COMMON_PREFS}"

# ─── Firefox Developer Edition — extensions via XPI drop-in ──────────────────
# jk-dev-local: vimium-ff

log_info "Installing Firefox Developer Edition extensions via XPI ..."

install_extensions_into_profile "$ffdx_dev_local_dir" \
  "{d07ccf11-c0cd-4938-a265-2a4d6ad01189}"  "vimium-ff"

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
