# Task: Configure Browsers

**Status**: done
**Priority**: medium
**Created**: 2026-03-22
**Platform**: macOS only

## Description

Install and configure browsers for personal use across distinct purposes. Each browser serves a specific role; configuration enforces that role. See `browsers.md` for the full strategy and rationale.

Browsers to install and configure:

| Browser | Purpose | Install method |
|---|---|---|
| Firefox | Daily driver + research profiles | `brew install --cask firefox` |
| Firefox Developer Edition | Software dev & home network | `brew install --cask firefox@developer-edition` |
| Mullvad Browser | Casual / sandbox | `brew install --cask mullvad-browser` |
| DuckDuckGo | Media streaming | `brew install --cask duckduckgo` |
| Safari | Privacy-sensitive accounts | Pre-installed (no action) |
| Tor Browser | Private / anonymized | `brew install --cask tor-browser` |
| Microsoft Edge | Work / employment | `brew install --cask microsoft-edge` |
| Google Chrome | General availability | `brew install --cask google-chrome` |
| Opera | General availability | `brew install --cask opera` |

---

## Implementation

### Firefox: Daily driver + research profiles

#### Shared configuration

**Profile names and `profiles.ini`:**

All three Firefox (stable) profiles use static, hash-free names. The script writes `profiles.ini` directly — no browser binary needed.

`~/Library/Application Support/Firefox/profiles.ini`:

```ini
[General]
StartWithLastProfile=0

[Profile0]
Name=jk-default
IsRelative=1
Path=Profiles/jk-default
Default=1

[Profile1]
Name=jk-research-trusted
IsRelative=1
Path=Profiles/jk-research-trusted

[Profile2]
Name=jk-research-private
IsRelative=1
Path=Profiles/jk-research-private
```

Idempotency: if `profiles.ini` already exists, check for each profile entry by name and append any that are missing. Never overwrite the whole file. Always create the corresponding `Profiles/jk-*` directory if absent.

**Extensions via XPI drop-in:**

Extensions are installed by downloading each `.xpi` from AMO and placing it in the `extensions/` subdirectory of every target profile. Firefox picks up new `.xpi` files on next launch without any app-bundle modification.

File naming: `<extension-id>.xpi` — Firefox uses the extension ID as the filename to identify the add-on.

Download URL pattern: `https://addons.mozilla.org/firefox/downloads/latest/<slug>/latest.xpi`

| Extension | ID | AMO slug | `jk-default` | `jk-research-trusted` | `jk-research-private` |
|---|---|---|---|---|---|
| uBlock Origin | `uBlock0@raymondhill.net` | `ublock-origin` | + | + | + |
| New Tab Override | `{ab5d7449-f2be-4db7-91d9-aaab5e59ddcc}` | `new-tab-override` | + | + | + |
| Multi-Account Containers | `@testpilot-containers` | `multi-account-containers` | + | + | - |
| Vimium FF | `{d07ccf11-c0cd-4938-a265-2a4d6ad01189}` | `vimium-ff` | + | + | + |
| Joplin Web Clipper | `joplin-web-clipper@joplin.cloud` | `joplin-web-clipper` | - | + | + |
| Stylus | `{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}` | `styl-us` | + | + | + |
| NoScript | `{73a6fe31-595d-460b-a920-fcc0f8843232}` | `noscript` | - | - | + |
| Sidebery | `{3c078156-979c-498b-8990-85f7987dd929}` | `sidebery` | + | + | + |

**Common `prefs.js` prefs** (written to all three profiles):

```js
// Telemetry / health reporting
user_pref("datareporting.policy.dataSubmissionEnabled", false);
user_pref("datareporting.healthreport.uploadEnabled", false);
user_pref("toolkit.telemetry.enabled", false);

// Enhanced Tracking Protection: Strict
// Note: category="strict" causes Firefox to manage ETP sub-prefs internally;
// individual sub-prefs are set explicitly so they hold regardless of processing order.
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

// Disable "check if Firefox is default browser" nag
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
user_pref("network.trr.disable-ECS", true);
```

#### Default profile (jk-default)

Location: `~/Library/Application Support/Firefox/Profiles/jk-default/prefs.js`

```js
// Cookies: first-party only — block all third-party cookies
user_pref("network.cookie.cookieBehavior", 1);

// Session restore: full restore on restart
user_pref("browser.sessionstore.privacy_level", 0);
user_pref("browser.sessionstore.restore_on_demand", false);
```

#### Trusted research (jk-research-trusted)

Location: `~/Library/Application Support/Firefox/Profiles/jk-research-trusted/prefs.js`

```js
// Cookies: block all cookies (first- and third-party)
user_pref("network.cookie.cookieBehavior", 2);

// Session restore: full restore on restart
user_pref("browser.sessionstore.privacy_level", 0);
user_pref("browser.sessionstore.restore_on_demand", false);
```

#### Private research (jk-research-private)

Location: `~/Library/Application Support/Firefox/Profiles/jk-research-private/prefs.js`

```js
// Aggressive anti-tracking: fingerprinting resistance
// Effects: timezone → UTC, canvas API randomised, screen metrics normalised,
// user-agent and locale spoofed. Breaks sites that depend on local time or canvas.
user_pref("privacy.resistFingerprinting", true);

// Cookies: block all cookies (first- and third-party)
user_pref("network.cookie.cookieBehavior", 2);

// Session: privacy level 2 — session data never written to disk; tabs on demand only
user_pref("browser.sessionstore.privacy_level", 2);
user_pref("browser.sessionstore.restore_on_demand", true);
```

---

### Safari — privacy-sensitive accounts

No extensions installed.

**Scriptable settings (via `defaults write`):**

```bash
# Disable auto-open of downloaded files
defaults write com.apple.Safari AutoOpenSafeDownloads -bool false

# Disable search engine suggestions
defaults write com.apple.Safari SuppressSearchSuggestions -bool true
defaults write com.apple.Safari UniversalSearchEnabled -bool false

# Hardening: Do Not Track header
defaults write com.apple.Safari SendDoNotTrackHTTPHeader -bool true

# Hardening: fraudulent website warning
defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true

# Hardening: block pop-up windows
defaults write com.apple.Safari WebKitJavaScriptCanOpenWindowsAutomatically -bool false
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2JavaScriptCanOpenWindowsAutomatically -bool false
```

Verify with `defaults read com.apple.Safari <key>`. Restart Safari after applying.

**Full Disk Access not granted — fallback behaviour:**

macOS 15+ (Sequoia) gates the Safari container behind Full Disk Access (TCC). If the script cannot reach the container (FDA not granted), it must skip the `defaults write` calls and instead print concise manual instructions covering every setting that would have been written, plus the two settings that are never scriptable. Output should be compact — one line per setting — so the user can act on it immediately in Safari Settings.

Required output when FDA is blocked:

```
Safari: Full Disk Access not granted — apply these settings manually in Safari → Settings:
  General  → "Open 'safe' files after downloading": uncheck
  Search   → "Include Safari Suggestions": uncheck
  Search   → "Enable Quick Website Search": uncheck
  Privacy  → "Prevent cross-site tracking": check
  Privacy  → "Hide IP Address": Trackers and Websites
  Advanced → "Warn when visiting a fraudulent website": check
  Advanced → (Websites tab) "Block pop-up windows": check
  (No scriptable equivalent for Do Not Track — omit or note separately)
```

The message must be printed via `dot_trace` (or equivalent) so it appears in the script output. Do not exit non-zero — FDA absence is an expected condition, not an error.

**Manual verification required (Safari UI):**

These two settings are not reliably scriptable via `defaults write` regardless of FDA and must always be confirmed after launch:

- Settings → Privacy → "Prevent cross-site tracking": enable
- Settings → Privacy → "Hide IP Address" → set to "Trackers" or "Trackers and Websites"

---

### Firefox Developer Edition: dev & home network

#### Shared configuration

**Profile names and `profiles.ini`:**

Firefox Developer Edition shares `~/Library/Application Support/Firefox/` with Firefox stable — the same `profiles.ini` and the same `Profiles/` directory. Dev Edition profiles are distinguished by name only.

The script appends `jk-dev-local` and `jk-home-network` to the shared `profiles.ini` using the same idempotent logic as the stable profiles. After all five profiles are registered, the file looks like:

```ini
[General]
StartWithLastProfile=0

[Profile0]
Name=jk-default
IsRelative=1
Path=Profiles/jk-default
Default=1

[Profile1]
Name=jk-research-trusted
IsRelative=1
Path=Profiles/jk-research-trusted

[Profile2]
Name=jk-research-private
IsRelative=1
Path=Profiles/jk-research-private

[Profile3]
Name=jk-dev-local
IsRelative=1
Path=Profiles/jk-dev-local

[Profile4]
Name=jk-home-network
IsRelative=1
Path=Profiles/jk-home-network
```

`jk-default` remains the sole `Default=1` profile. Firefox Developer Edition selects its profile via Automator launcher (`-P jk-home-network`) or `about:profiles`.

**Extensions via XPI drop-in:**

Same drop-in approach as Firefox stable.

| Extension | ID | AMO slug | `jk-dev-local` | `jk-home-network` |
|---|---|---|---|---|
| Vimium FF | `{d07ccf11-c0cd-4938-a265-2a4d6ad01189}` | `vimium-ff` | + | + |
| New Tab Override | `{ab5d7449-f2be-4db7-91d9-aaab5e59ddcc}` | `new-tab-override` | + | + |

**Common `prefs.js` prefs** (written to both Dev Edition profiles):

Subset of the Firefox stable common prefs — excludes ETP, tracking protection, and DoH, which would interfere with local dev and homelab work.

```js
// Telemetry / health reporting
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
user_pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
```

#### Dev local (jk-dev-local)

Location: `~/Library/Application Support/Firefox/Profiles/jk-dev-local/prefs.js`

Common prefs only — no profile-specific overrides.

#### Home network (jk-home-network)

Location: `~/Library/Application Support/Firefox/Profiles/jk-home-network/prefs.js`

```js
// Disable HTTPS-only mode for local services
user_pref("dom.security.https_only_mode", false);

// Disable tracking protection for local network
user_pref("privacy.trackingprotection.enabled", false);
user_pref("network.trr.mode", 0);
```

---

### Other browsers

Install only — no configuration. These browsers are either self-configuring by design (Mullvad, Tor, DuckDuckGo) or managed post-install by the user or employer (Edge, Chrome, Opera).

---

### Manual post-install steps

Steps that cannot be automated (require a running browser or manual UI interaction):

1. **Firefox — create containers**: Open Firefox → Multi-Account Containers → create containers: Personal, Work, Shopping, Social. Container creation writes to the extension's IndexedDB and cannot be scripted without running the browser.
2. **Firefox — Sidebery panels**: Open each profile and create Sidebery tab panels per project manually.

---

## Acceptance Criteria

- [x] All browsers in the table above are installed and present in `/Applications/`
- [x] `~/Library/Application Support/Firefox/profiles.ini` exists and contains entries for `jk-default`, `jk-research-trusted`, and `jk-research-private`; corresponding `Profiles/jk-*` directories exist
- [x] Firefox `jk-default` profile `extensions/` directory contains an `.xpi` file for each declared extension (named `<extension-id>.xpi`)
- [x] Firefox `jk-research-private` and `jk-research-trusted` profiles each have an `extensions/` directory with the declared `.xpi` files
- [x] Firefox `jk-default` profile `prefs.js` exists with the expected preference keys present
- [x] Firefox `jk-research-private` and `jk-research-trusted` profiles each have a `prefs.js` with the expected per-profile preference keys
- [x] Safari scriptable settings are applied; spot-check with `defaults read com.apple.Safari <key>`; manual settings confirmed in Safari UI
- [x] `~/Library/Application Support/Firefox/profiles.ini` contains entries for `jk-dev-local` and `jk-home-network`; corresponding `Profiles/jk-*` directories exist under the shared Firefox profiles directory
- [x] Firefox Developer Edition `jk-dev-local` and `jk-home-network` profiles each have an `extensions/` directory with the declared `.xpi` files
- [x] Firefox Developer Edition `jk-dev-local` and `jk-home-network` profiles each have a `prefs.js` with the expected preference keys
- [x] A dock launcher `.app` exists in `~/Applications/` for each of the five Firefox profiles (`ff-jk-default.app`, `ff-jk-research-trusted.app`, `ff-jk-research-private.app`, `ff-jk-dev-local.app`, `ff-jk-home-network.app`) and each is present in the Dock
- [x] Mullvad, DuckDuckGo, Tor, Edge, Chrome, and Opera are installed with no configuration applied
- [x] No `policies.json` is written to any browser's app bundle (the `distribution/` directory is left untouched)
- [x] Installation and configuration tests validate file presence and configured preferences; tests pass

---

## Out of Scope

- Browser sign-ins and account sync (cannot be automated safely)
- Multi-Account Container creation in Firefox (requires running browser; document as manual step)
- Extension-level configuration (e.g. uBlock Origin filter lists, Stylus themes, Vimium keybindings) — handled separately
- Windows or Linux support
- Browser default assignment (which browser opens links from other apps)

---

## Edge Cases

- **Static profile paths**: Profiles use fixed names (`jk-default`, `jk-research-trusted`, etc.) and are referenced directly — no hash lookup required. Profile directories sit at `Profiles/<name>` relative to the app support directory.
- **`profiles.ini` idempotency**: If `profiles.ini` already exists (e.g. Firefox was launched before the script ran and created its own default profile), the script must preserve existing entries and only append the ones it manages. Do not clobber user-created profiles.
- **Firefox Developer Edition app name**: The `.app` contains a space (`Firefox Developer Edition.app`), requiring escaping in shell commands.
- **Extension IDs**: The `.xpi` file must be named exactly `<extension-id>.xpi`. IDs should be verified against the extension's AMO page before deployment. After installation, confirm via `about:support` → Extensions in the browser.
- **XPI download failures**: `curl -L` follows redirects; check HTTP status before placing the file. A zero-byte or HTML error page must not be written as the `.xpi`.
- **Do not modify the app bundle**: The `distribution/` folder inside `Firefox.app` and `Firefox Developer Edition.app` must not be created or written to. Writing `policies.json` there causes Firefox to report a corrupted installation.
- **Mullvad / Tor**: If already installed via direct download rather than Homebrew, skip cask install and note the discrepancy.

---

## Assumptions

- Homebrew is installed and up to date.
- The executing agent has permission to write to `~/Library/Application Support/`.
- Browsers are not currently running when `prefs.js` files are written.

---

## Implementation Notes

Prior implementation used `policies.json` in the app bundle's `distribution/` directory to push extensions. This caused Firefox to report a corrupted installation and is **not viable** — do not use that approach.

The replacement approach drops `.xpi` files directly into each profile's `extensions/` directory. This requires no app-bundle modification.

Rewritten to use static profile names (`jk-*` prefix, no hash). `find_firefox_profile_dir` and `openssl rand` removed entirely. `create_firefox_profile_if_absent` writes `profiles.ini` via `ensure_firefox_profiles_ini`, which computes the next available `[ProfileN]` index from the file to avoid collisions. `write_firefox_prefs_js` takes a direct profile directory path. All callers use `${FF_PROFILES}/jk-<name>` paths directly.

Implementation files:
- `osx/configure_browsers.sh` — rewritten: static paths throughout, no hash generation, `profiles.ini` written idempotently via `ensure_firefox_profiles_ini`
- `tests/test-cases/helpers/browsers-functions.sh` — rewritten: `find_firefox_profile_dir` and hash-based helpers removed; `ensure_firefox_profiles_ini` and updated `create_firefox_profile_if_absent`/`write_firefox_prefs_js` added
- `tests/test-cases/test-browsers-configure.sh` — rewritten: all hash-based test setup removed; static path assertions added; `ensure_firefox_profiles_ini` idempotency tests added
