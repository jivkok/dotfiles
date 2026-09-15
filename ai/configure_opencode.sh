#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'
# Configure OpenCode (macOS / Linux).
#
# Installs the OpenCode CLI (https://opencode.ai) and points it at the local
# Ollama server's "-code" Qwen3.8 27B model over its OpenAI-compatible API.
# Fully idempotent — safe to re-run at any time.

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

OLLAMA_HOST_NAME="jmac1"
OLLAMA_BASE_URL="http://${OLLAMA_HOST_NAME}:11434/v1"
OPENCODE_MODEL="qwen3.8-27b-code"
OPENCODE_CONFIG_DIR="${HOME}/.config/opencode"
OPENCODE_CONFIG="${OPENCODE_CONFIG_DIR}/opencode.json"

if ! $_is_osx && ! $_is_linux; then
  log_trace "configure_opencode.sh: skipping (unsupported OS: ${_OS})."
  exit 0
fi

log_info "Configuring OpenCode ..."

if $_is_osx; then
  install_or_upgrade_brew_package opencode
elif _has opencode; then
  log_trace "OpenCode already installed."
else
  log_trace "Installing OpenCode via the official install script ..."
  curl -fsSL https://opencode.ai/install | bash
fi

if ! _has jq; then
  log_error "configure_opencode.sh: 'jq' is required to update ${OPENCODE_CONFIG}."
  exit 1
fi

mkdir -p "$OPENCODE_CONFIG_DIR"
if [ ! -f "$OPENCODE_CONFIG" ]; then
  echo '{}' >"$OPENCODE_CONFIG"
fi

_provider_json=$(
  cat <<EOF
{
  "npm": "@ai-sdk/openai-compatible",
  "name": "Ollama (${OLLAMA_HOST_NAME})",
  "options": { "baseURL": "${OLLAMA_BASE_URL}" },
  "models": {
    "${OPENCODE_MODEL}": {
      "name": "Qwen3.8 27B (code)",
      "limit": { "context": 65536, "output": 65536 }
    }
  }
}
EOF
)

_tmp="$(mktemp)"
jq --argjson provider "$_provider_json" \
  '.["$schema"] = "https://opencode.ai/config.json" | .provider.ollama = $provider' \
  "$OPENCODE_CONFIG" >"$_tmp"

if diff -q "$_tmp" "$OPENCODE_CONFIG" >/dev/null 2>&1; then
  log_trace "OpenCode config already up to date."
  rm -f "$_tmp"
else
  mv -f "$_tmp" "$OPENCODE_CONFIG"
  log_trace "Updated OpenCode config at ${OPENCODE_CONFIG}."
fi

log_info "Configuring OpenCode done."
