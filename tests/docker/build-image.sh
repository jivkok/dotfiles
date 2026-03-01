#!/usr/bin/env bash
set -euo pipefail

# -------- config --------
IMAGE_NAME="${IMAGE_NAME:-}"
DOCKERFILE_PATH="${DOCKERFILE_PATH:-}"
# Pass extra args to docker run via DOCKER_RUN_ARGS env var if needed.
DOCKER_RUN_ARGS="${DOCKER_RUN_ARGS:-}"
# ------------------------

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker not found in PATH" >&2
  exit 1
fi

if [[ ! -f "${DOCKERFILE_PATH}" ]]; then
  echo "ERROR: Dockerfile not found at ${DOCKERFILE_PATH}" >&2
  exit 1
fi

if [[ ! -f "${repo_root}/setup/setup.sh" ]]; then
  echo "ERROR: setup script not found at ${repo_root}/setup/setup.sh" >&2
  exit 1
fi

echo "==> Building image: ${IMAGE_NAME}"
docker build \
  -t "${IMAGE_NAME}" \
  -f "${DOCKERFILE_PATH}" \
  "${repo_root}"
