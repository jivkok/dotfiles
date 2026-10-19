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

# ssh aborts for a uid with no passwd entry ("No user exists for uid") and reads
# its config from the passwd home, not $HOME - both wrong here, since the
# container runs as the host's uid (which may even collide with an image user,
# e.g. "ubuntu" at 1000). So when the launcher mounted an ssh config (ssh: in
# .aiproj), put our entry first in a copy of the real passwd/group via
# nss_wrapper; root and system users still resolve. Skipped otherwise, to keep
# LD_PRELOAD out of everyone else's way.
if [ -f "$HOME/.ssh/config" ] &&
  [ "$(getent passwd "$(id -u)" | cut -d: -f6)" != "$HOME" ]; then
  for _nss_lib in /usr/lib/*/libnss_wrapper.so; do :; done
  if [ -e "$_nss_lib" ]; then
    { echo "claude:x:$(id -u):$(id -g):claude:${HOME}:/bin/bash"; cat /etc/passwd; } >/tmp/nss-passwd
    cp /etc/group /tmp/nss-group
    getent group "$(id -g)" >/dev/null || echo "claude:x:$(id -g):" >>/tmp/nss-group
    export NSS_WRAPPER_PASSWD=/tmp/nss-passwd NSS_WRAPPER_GROUP=/tmp/nss-group
    export LD_PRELOAD="${_nss_lib}${LD_PRELOAD:+:$LD_PRELOAD}"
  fi
fi

exec "$@"
