#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'
# Configure Ollama models (macOS only).
#
# Pulls the Qwen3.8 27B base model and creates two custom aliases with
# different context-length profiles:
#   qwen3.8-27b-claw -> OpenClaw / general orchestration (32k context)
#   qwen3.8-27b-code -> OpenCode / coding agents (64k context)
# Also pulls a smaller base model as-is, with no custom alias:
#   qwen3:30b-a3b-instruct-2507-q4_K_M -> transcription/summarization (non-thinking instruct model)
#
# Requires ai/configure_ollama.sh to have been run first (Ollama installed
# and its API reachable). Fully idempotent — safe to re-run at any time.

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

BASE_MODEL="qwen3.8:27b"
MODEL_CLAW="qwen3.8-27b-claw"
MODEL_CODE="qwen3.8-27b-code"
TRANSCRIBE_MODEL="qwen3:30b-a3b-instruct-2507-q4_K_M"

# macOS only
if ! $_is_osx; then
  log_trace "configure_ollama_models.sh: skipping (not macOS)."
  exit 0
fi

log_info "Configuring Ollama models ..."

if ! _has ollama; then
  log_error "configure_ollama_models.sh: 'ollama' command not found. Run ai/configure_ollama.sh first."
  exit 1
fi

if ! curl -fsS "http://127.0.0.1:11434/api/version" >/dev/null 2>&1; then
  log_error "configure_ollama_models.sh: Ollama API is not reachable at http://127.0.0.1:11434. Run ai/configure_ollama.sh first."
  exit 1
fi

# Returns 0 if a model (bare name or name:tag) is present in `ollama list`.
_ollama_model_exists() {
  local name="$1"
  ollama list | awk 'NR>1 {print $1}' | grep -qE "^${name}(:|\$)"
}

# Pulls a base model via `ollama pull` if not already present.
pull_model_if_missing() {
  local model="$1"

  if _ollama_model_exists "$model"; then
    log_trace "Base model ${model} already present."
  else
    log_trace "Pulling ${model} ..."
    ollama pull "$model"
  fi
}

pull_model_if_missing "$BASE_MODEL"
pull_model_if_missing "$TRANSCRIBE_MODEL"

# Creates a model alias from BASE_MODEL with a custom context length.
# Arguments:
#   $1 - alias name
#   $2 - num_ctx value
create_model_alias() {
  local alias_name="$1"
  local num_ctx="$2"

  if _ollama_model_exists "$alias_name"; then
    log_trace "Model alias ${alias_name} already exists."
    return
  fi

  log_trace "Creating ${alias_name} (num_ctx=${num_ctx}) ..."
  local modelfile
  modelfile="$(mktemp)"
  cat >"$modelfile" <<EOF
FROM ${BASE_MODEL}
PARAMETER num_ctx ${num_ctx}
EOF
  ollama create "$alias_name" -f "$modelfile"
  rm -f "$modelfile"
}

create_model_alias "$MODEL_CLAW" 32768
create_model_alias "$MODEL_CODE" 65536

log_trace "Verifying installed models ..."
_missing=0
for m in "$MODEL_CLAW" "$MODEL_CODE"; do
  if ! _ollama_model_exists "$m"; then
    log_error "configure_ollama_models.sh: expected model ${m} not found in 'ollama list'."
    _missing=1
  fi
done

if [ "$_missing" -eq 1 ]; then
  exit 1
fi

log_trace "Installed models:"
ollama list

log_info "Configuring Ollama models done."
