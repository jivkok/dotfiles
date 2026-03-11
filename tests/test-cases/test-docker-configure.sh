#!/usr/bin/env bash
# REQUIRES: docker
set -euo pipefail

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

# ── Runtime ────────────────────────────────────────────────────────────────────
log_trace "--- configure_docker.sh: runtime ---"

assert_cmd docker

# ── Docker version ─────────────────────────────────────────────────────────────
log_trace "--- configure_docker.sh: docker version ---"

docker_version=$(docker --version 2>/dev/null | sed 's/Docker version //' | cut -d',' -f1)
docker_major=$(echo "$docker_version" | cut -d. -f1)
if [[ "$docker_major" -ge 20 ]]; then
  ok "docker version is acceptable: ${docker_version}"
else
  fail "docker version is too old (expected >= 20): ${docker_version}"
fi

# ── Docker Compose plugin ──────────────────────────────────────────────────────
log_trace "--- configure_docker.sh: docker compose plugin ---"

if docker compose version >/dev/null 2>&1; then
  ok "docker compose plugin available"
else
  fail "docker compose plugin not available"
fi

# ── Linux post-install ─────────────────────────────────────────────────────────
if [[ "$(uname -s)" = "Linux" ]]; then
  log_trace "--- configure_docker.sh: linux post-install ---"

  if getent group docker >/dev/null 2>&1; then
    ok "docker group exists"
  else
    fail "docker group not found"
  fi

  if id -nG "${USER:-$(id -un)}" | grep -qw docker; then
    ok "user is in docker group"
  else
    fail "user is not in docker group"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
finish_test
