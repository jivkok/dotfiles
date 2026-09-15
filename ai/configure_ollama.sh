#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'
# Configure Ollama (macOS only).
#
# Installs Ollama via Homebrew, runs it as a Homebrew service, and configures
# its runtime environment (remote access, memory/parallelism tuning) via
# PlistBuddy on the Homebrew-managed launchd plist. Fully idempotent — safe
# to re-run at any time.
#
# Logging out/in (or rebooting) is safe: launchd reloads the plist straight
# off disk at login, so the customizations below persist with no help from
# Homebrew. `brew update` is also safe — it only refreshes formula metadata.
#
# `brew upgrade ollama` is the one case that silently undoes this script:
# upgrading does not itself restart the service, but ollama's own Caveats
# tell you to run `brew services restart ollama` afterward — and that
# command regenerates the plist from the formula's `service do` block,
# wiping OLLAMA_HOST and the other overrides back to just the formula's 2
# defaults (see the PLIST/LABEL comment below). After any `brew upgrade
# ollama`, re-run this script instead of that caveat's suggested command.

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

# macOS only
if ! $_is_osx; then
  log_trace "configure_ollama.sh: skipping (not macOS)."
  exit 0
fi

log_info "Configuring Ollama ..."

install_or_upgrade_brew_package ollama

log_trace "Starting Ollama Homebrew service ..."
brew services start ollama >/dev/null 2>&1 || true

BREW_PREFIX="$(brew --prefix)"
OLLAMA_BIN="${BREW_PREFIX}/opt/ollama/bin/ollama"

if [ ! -x "$OLLAMA_BIN" ]; then
  log_error "configure_ollama.sh: Ollama executable not found at ${OLLAMA_BIN}"
  exit 1
fi

if ! _has jq; then
  log_error "configure_ollama.sh: 'jq' is required to locate the Ollama launchd plist."
  exit 1
fi

# The ollama formula defines its service via Homebrew's `service do` DSL
# rather than shipping a static plist. That means the file under
# "$(brew --prefix)/opt/ollama" is only a template: every `brew services
# start`/`restart` regenerates the *actual* loaded plist under
# ~/Library/LaunchAgents fresh from the formula definition, silently
# discarding any manual PlistBuddy edits made to the template. We must edit
# the real loaded plist instead, and reload it via launchctl directly
# (never `brew services restart`, which would regenerate and wipe our edits
# again). `brew services info --json` reports the real path/label
# name-agnostically (handles the legacy "homebrew.mxcl.*" vs. current
# "sh.brew.*" naming schemes).
_svc_info="$(brew services info ollama --json)"
PLIST="$(echo "$_svc_info" | jq -r '.[0].file // empty')"
LABEL="$(echo "$_svc_info" | jq -r '.[0].service_name // empty')"

if [ -z "$PLIST" ] || [ ! -f "$PLIST" ] || [ -z "$LABEL" ]; then
  log_error "configure_ollama.sh: could not resolve the Homebrew Ollama launchd plist/label via 'brew services info'."
  exit 1
fi

log_trace "Ollama binary : ${OLLAMA_BIN}"
log_trace "Ollama plist  : ${PLIST}"
log_trace "Ollama label  : ${LABEL}"

# Set an EnvironmentVariables value in the Homebrew plist.
# Delete + Add is intentional so the script is idempotent and we don't have
# to care whether the plist already contains the key.
plist_env_set() {
  local key="$1"
  local value="$2"

  /usr/libexec/PlistBuddy -c "Delete :EnvironmentVariables:${key}" "$PLIST" >/dev/null 2>&1 || true
  /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:${key} string ${value}" "$PLIST"
}

# Ensure EnvironmentVariables exists. Ignore failure — it normally already
# exists after the first run.
/usr/libexec/PlistBuddy -c "Add :EnvironmentVariables dict" "$PLIST" >/dev/null 2>&1 || true

log_trace "Configuring Ollama environment variables ..."

# Remote API access.
plist_env_set "OLLAMA_HOST" "0.0.0.0:11434"

# Keep the model resident indefinitely — this machine is a dedicated
# inference host, so unloading after idle periods isn't useful.
plist_env_set "OLLAMA_KEEP_ALIVE" "-1"

# Default/maximum practical context for clients which don't explicitly
# provide num_ctx. Individual model aliases (see configure_ollama_models.sh)
# override this per-model.
plist_env_set "OLLAMA_CONTEXT_LENGTH" "65536"

# Important for large-context inference and quantized KV cache.
plist_env_set "OLLAMA_FLASH_ATTENTION" "1"

# Roughly halves KV-cache memory compared with f16.
plist_env_set "OLLAMA_KV_CACHE_TYPE" "q8_0"

# Do not allow two simultaneous large-model generations to multiply
# KV-cache requirements. Remote callers queue instead.
plist_env_set "OLLAMA_NUM_PARALLEL" "1"

# Only one large model should be resident at once.
plist_env_set "OLLAMA_MAX_LOADED_MODELS" "1"

log_trace "Reloading Ollama service to pick up plist changes ..."
UID_NUM="$(id -u)"
# Deliberately not `brew services restart` — see the comment above PLIST/LABEL
# resolution: that would regenerate the plist from the formula and discard
# the EnvironmentVariables we just set. Reload the edited file directly.
launchctl bootout "gui/${UID_NUM}/${LABEL}" >/dev/null 2>&1 || true

# launchd needs a moment to fully release the label after bootout — an
# immediate bootstrap can fail transiently ("Input/output error") while the
# old registration is still tearing down, so retry briefly.
for _i in {1..10}; do
  if launchctl bootstrap "gui/${UID_NUM}" "$PLIST" 2>/dev/null; then
    break
  fi
  sleep 0.5
done

launchctl kickstart -k "gui/${UID_NUM}/${LABEL}"

log_trace "Waiting for Ollama API ..."
_ollama_ready=false
for i in {1..30}; do
  if curl -fsS "http://127.0.0.1:11434/api/version" >/dev/null 2>&1; then
    _ollama_ready=true
    break
  fi
  if [ "$i" -eq 30 ]; then
    break
  fi
  sleep 1
done

if ! $_ollama_ready; then
  log_error "configure_ollama.sh: Ollama did not become available within 30s."
  brew services info ollama || true
  exit 1
fi

log_info "Configuring Ollama done."
