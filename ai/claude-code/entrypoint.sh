#!/usr/bin/env bash
set -uo pipefail
# Seeds a freshly (or empty) persisted ~/.claude/ — bind-mounted from the
# host by claude-code-docker.sh, so it starts out empty on a new host —
# with this image's build-time defaults (notably rtk's global hook
# registration from `rtk init -g`), snapshotted at build time into
# /opt/claude-defaults. Without this, mounting an empty host directory
# straight onto ~/.claude would silently shadow that hook config away.
# Runs only once per host (skipped once settings.json exists there).
if [ -d /opt/claude-defaults ] && [ ! -e "$HOME/.claude/settings.json" ]; then
  mkdir -p "$HOME/.claude"
  cp -a /opt/claude-defaults/. "$HOME/.claude/"
fi

exec "$@"
