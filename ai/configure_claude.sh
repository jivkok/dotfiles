#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'
# Configure Claude (macOS / Linux).
#
# Linux (Debian, Arch, and derivatives): installs the Claude Code CLI only,
# via Anthropic's native installer (no Node/npm dependency, same installer
# used by ai/claude-code/Dockerfile). Skipped if already installed, since
# Claude Code updates itself thereafter.
#
# macOS: installs both Claude Code (CLI, for terminal use) and the Claude
# desktop app (GUI) via their Homebrew casks. The desktop app is what
# provides Claude Cowork — Cowork itself isn't a separate package or
# installable artifact, it's a feature inside the desktop app that you
# enable by signing in and toggling it on (and requires a paid Pro/Max/Team/
# Enterprise plan) — that step can't be scripted.
#
# Fully idempotent — safe to re-run at any time.

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

if $_is_debian || $_is_arch; then
  log_info "Configuring Claude ..."

  if _has claude; then
    log_trace "Claude Code already installed."
  else
    log_trace "Installing Claude Code via the official install script ..."
    curl -fsSL https://claude.ai/install.sh | bash
  fi

  log_info "Configuring Claude done."

elif $_is_osx; then
  log_info "Configuring Claude ..."

  install_or_upgrade_cask_package claude-code
  install_or_upgrade_cask_package claude

  log_trace "Claude desktop app installed. To use Claude Cowork, open Claude.app, sign in, and enable Cowork from within the app (requires a paid plan) — this step can't be scripted."

  log_info "Configuring Claude done."

else
  log_trace "configure_claude.sh: skipping (unsupported OS: ${_OS})."
fi
