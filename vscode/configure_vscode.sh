#!/usr/bin/env bash

# Goal
# Install and configure VS Code and VS Codium consistently across macOS and
# Linux, including: application install, shared config file deployment, and
# extension installation with a fallback for Marketplace-only extensions.
#
# Supported Platforms
# - macOS        (via Homebrew)
# - Linux/Debian (apt + Microsoft and VSCodium community repos)
# - Linux/Arch   (yay AUR helper)
#
# Supported Applications
# - VS Code   (CLI: `code`)
# - VS Codium (CLI: `codium`)
#
# Dependencies
# - jq    : required for deep-merging base + OS-specific JSON config files
#
# Config File Deployment  (settings.json, keybindings.json)
# Source files (this directory):
#   <config>.json            base config, applied to all platforms
#   <config>.<os>.json       OS-specific overrides  (os = "osx" | "linux")
#
# Destination directories:
#   Linux  — VS Code  : ~/.config/Code/User
#   Linux  — VSCodium : ~/.config/VSCodium/User
#   macOS  — VS Code  : ~/Library/Application Support/Code/User
#   macOS  — VSCodium : ~/Library/Application Support/VSCodium/User
#
# Deployment rules (applied per editor, per config file):
#   1. Skip if source base file is absent.
#   2. Skip if destination directory is empty/unset (e.g., VSCodium on Linux).
#   3. Back up any existing destination file with a timestamp suffix before
#      overwriting.
#   4. If an OS-specific override file exists, deep-merge base + override via
#      `jq -s '.[0] * .[1]'` and write the result to the destination.
#   5. Otherwise copy the base file directly to the destination.
#
# Limitation: JSON-with-comments (JSONC) is not supported by jq; config files must be valid JSON.
#
# Extension Installation
# Extensions are read from three files in this directory:
#   extensions.txt        installed into both `code` and `codium`
#   extensions.code.txt   installed into `code` only
#   extensions.codium.txt installed into `codium` only
#
# File format: one extension ID per line ("publisher.name").
#   - Text after `#` is treated as a comment and ignored.
#   - Blank / whitespace-only lines are skipped.
#
# VSCodium fallback (Open VSX miss):
#   If `codium --install-extension` fails with "Extension '…' not found",
#   the script falls back to install-vscode-local-extension-to-vscodium.py,
#   which mirrors the extension from the local VS Code cache into VSCodium.
#   All other errors are propagated unchanged.
#
# Error Handling
# - Fail fast on unsupported OS.
# - Report and abort on failed backup, copy, or JSON merge operations.
# - Bubble non-recoverable extension install errors to the caller.
#
# Non-Goals
# - No Windows support.
# - No JSONC (JSON-with-comments) parsing.
# - No rollback on partial failure.

install_vscode_and_dependencies () {
  if $_is_linux; then

    if $_is_debian; then
      if ! apt list --installed 2>/dev/null | grep -q "^code/"; then
        log_trace 'Installing VSCode'
        curl -sSL https://packages.microsoft.com/keys/microsoft.asc \
          | gpg --dearmor \
          | sudo tee /usr/share/keyrings/microsoft-archive-keyring.gpg > /dev/null
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/code stable main" \
          | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
        sudo apt-get update -qq
        install_or_upgrade_apt_package code
      fi
      if ! apt list --installed 2>/dev/null | grep -q "^codium/"; then
        log_trace 'Installing VSCodium'
        curl -sSL https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg \
          | gpg --dearmor \
          | sudo tee /usr/share/keyrings/vscodium-archive-keyring.gpg > /dev/null
        echo "deb [signed-by=/usr/share/keyrings/vscodium-archive-keyring.gpg] https://download.vscodium.com/debs vscodium main" \
          | sudo tee /etc/apt/sources.list.d/vscodium.list > /dev/null
        sudo apt-get update -qq
        install_or_upgrade_apt_package codium
      fi
      # Dependencies
      install_or_upgrade_apt_package jq

    elif $_is_arch; then
      if ! _has yay; then
        log_error "yay AUR helper not found. Install yay before running this script on Arch."
        return 1
      fi
      if ! ( pacman -Q code >/dev/null 2>&1 || pacman -Q visual-studio-code-bin >/dev/null 2>&1 ); then
        log_trace 'Installing VSCode'
        install_or_upgrade_yay_package visual-studio-code-bin
      fi
      if ! ( pacman -Q vscodium-bin >/dev/null 2>&1 || pacman -Q vscodium >/dev/null 2>&1 ); then
        log_trace 'Installing VSCodium'
        install_or_upgrade_yay_package vscodium-bin
      fi
      # Dependencies
      install_or_upgrade_pacman_package jq

    else
      log_error "Unsupported Linux distribution (no apt-get or pacman found)."
      return 1
    fi

  elif $_is_osx; then

    install_or_upgrade_cask_package visual-studio-code
    install_or_upgrade_cask_package vscodium
    # JSON processor
    install_or_upgrade_brew_package jq

  else
    log_error "Unsupported OS: ${_OS}"
    return 1
  fi
}

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

  backup_file_if_exists "${vscode_user_dir}/${config_filename}"

  if [ -f "${settingsdir}/${osspecific_config_filename}" ]; then
    # TODO: account for cases where the json files contain comments - jq doesn't support JSON with comments by default - consider using jsonc parser
    if ! jq -s '.[0] * .[1]' "${settingsdir}/${config_filename}" "${settingsdir}/${osspecific_config_filename}" > "${vscode_user_dir}/${config_filename}" 2>/dev/null; then
      log_error "Failed to merge JSON config files. Check for JSON syntax errors or comments."
      return 1
    fi
  else
    if ! cp "${settingsdir}/${config_filename}" "${vscode_user_dir}/${config_filename}" 2>/dev/null; then
      log_error "Failed to copy config file: ${settingsdir}/${config_filename}"
      return 1
    fi
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

install_extension () {
  local vsc="${1}"         # code or codium
  local extension="${2}"   # publisher.extension
  local settingsdir="${3}" # location with python helper

  local out rc
  # Quote extension to prevent word splitting and glob expansion
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
    # Bubble up other errors unchanged
    printf '%s\n' "$out" >&2
    return "$rc"
  fi
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  dotdir="$(cd "$(dirname "$0")/.." && pwd)"
  # shellcheck source=../setup/setup_functions.sh
  source "${dotdir}/setup/setup_functions.sh"
  settingsdir="$(cd "$(dirname "$0")" && pwd)"

  log_info 'Configuring VS Code & VS Codium ...'
  install_vscode_and_dependencies

  os_name_token=
  vscode_user_dir=
  vscodium_user_dir=

  if $_is_linux; then
    os_name_token="linux"
    vscode_user_dir="${HOME}/.config/Code/User"
    vscodium_user_dir="${HOME}/.config/VSCodium/User"

  elif $_is_osx; then
    os_name_token="osx"
    vscode_user_dir="${HOME}/Library/Application Support/Code/User"
    vscodium_user_dir="${HOME}/Library/Application Support/VSCodium/User"

  else
    log_error "Unsupported OS: ${_OS}"
    exit 1
  fi

  prepare_and_copy_vscode_config_files "${settingsdir}" "settings" "${os_name_token}" "${vscode_user_dir}"
  prepare_and_copy_vscode_config_files "${settingsdir}" "keybindings" "${os_name_token}" "${vscode_user_dir}"
  prepare_and_copy_vscode_config_files "${settingsdir}" "settings" "${os_name_token}" "${vscodium_user_dir}"
  prepare_and_copy_vscode_config_files "${settingsdir}" "keybindings" "${os_name_token}" "${vscodium_user_dir}"

  install_extensions "code" "${settingsdir}/extensions.txt" "${settingsdir}"
  install_extensions "codium" "${settingsdir}/extensions.txt" "${settingsdir}"
  install_extensions "code" "${settingsdir}/extensions.code.txt" "${settingsdir}"
  install_extensions "codium" "${settingsdir}/extensions.codium.txt" "${settingsdir}"

  log_info 'Configuring VS Code & VS Codium done.'
fi
