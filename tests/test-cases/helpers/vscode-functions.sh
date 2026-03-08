#!/usr/bin/env bash
# Standalone definitions of the testable functions from vscode/configure_vscode.sh.
# Kept in sync with configure_vscode.sh.  Source this file in tests instead of
# sourcing configure_vscode.sh directly (the main script is not bind-mounted in
# Docker test environments).

dot_trace() { :; }
dot_error() { echo "  [dot_error] $*" >&2; }

prepare_and_copy_vscode_config_files () {
  local settingsdir="${1}"
  local config_filename="${2}.json"
  local osspecific_config_filename="${2}.${3}.json"
  local vscode_user_dir="${4}"

  # Skip if vscode_user_dir is empty (e.g., VSCodium on Linux)
  if [ -z "${vscode_user_dir}" ]; then
    return 0
  fi

  if [ ! -f "${settingsdir}/${config_filename}" ]; then
    return 0
  fi

  # Create directory if it doesn't exist
  mkdir -p "${vscode_user_dir}"

  if [ -f "${vscode_user_dir}/${config_filename}" ]; then
    local backup_file="${vscode_user_dir}/${config_filename}.$(date +"%Y%m%d%H%M%S")"
    if ! mv "${vscode_user_dir}/${config_filename}" "${backup_file}" 2>/dev/null; then
      dot_error "Failed to backup existing config file: ${vscode_user_dir}/${config_filename}"
      return 1
    fi
  fi

  if [ -f "${settingsdir}/${osspecific_config_filename}" ]; then
    if ! jq -s '.[0] * .[1]' "${settingsdir}/${config_filename}" "${settingsdir}/${osspecific_config_filename}" > "${vscode_user_dir}/${config_filename}" 2>/dev/null; then
      dot_error "Failed to merge JSON config files. Check for JSON syntax errors or comments."
      return 1
    fi
  else
    if ! cp "${settingsdir}/${config_filename}" "${vscode_user_dir}/${config_filename}" 2>/dev/null; then
      dot_error "Failed to copy config file: ${settingsdir}/${config_filename}"
      return 1
    fi
  fi
}

install_extension () {
  local vsc="${1}"         # code or codium
  local extension="${2}"   # publisher.extension
  local settingsdir="${3}" # location with python helper

  local out rc
  out="$("${vsc}" --install-extension "${extension}" 2>&1)"
  rc=$?

  if [[ $rc -eq 0 ]]; then
    printf '%s\n' "$out"
    return 0
  fi

  # Only handle the Open VSX miss case for VSCodium
  if [[ "$vsc" == "codium" ]] && grep -qE "Extension '.*' not found" <<<"$out"; then
    printf '%s\n' "$out" >&2
    printf "Open VSX miss for %s. Using VS Code local cache via helper...\n" "$extension" >&2

    python3 "$settingsdir/install-vscode-local-extension-to-vscodium.py" \
      --extension "$extension" \
      --code-bin code \
      --vscode-dir "$HOME/.vscode" \
      --vscodium-dir "$HOME/.vscode-oss" \
      || return $?
  else
    printf '%s\n' "$out" >&2
    return "$rc"
  fi
}

install_extensions () {
  local vsc="${1}" # code or codium
  local extensions_file="${2}"
  local settingsdir="${3}"

  if [ ! -f "$extensions_file" ]; then
    return 1
  fi

  while IFS= read -r line; do
    extension=$(echo "${line}" | sed 's/#.*//' | xargs) # remove comments, trim spaces

    if [[ -n "$extension" ]]; then
      install_extension "$vsc" "$extension" "$settingsdir"
    fi
  done < "${extensions_file}"
}
