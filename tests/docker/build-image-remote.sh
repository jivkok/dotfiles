#!/usr/bin/env bash
set -euo pipefail

# -------- config --------
IMAGE_NAME="${IMAGE_NAME:-}"
DOCKERFILE_PATH="${DOCKERFILE_PATH:-}"
# Pass extra --build-arg flags via DOCKER_RUN_ARGS (despite the name, used for build args here).
DOCKER_RUN_ARGS="${DOCKER_RUN_ARGS:-}"
# ------------------------

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker not found in PATH" >&2
  exit 1
fi

if [[ ! -f "${DOCKERFILE_PATH}" ]]; then
  echo "ERROR: Dockerfile not found at ${DOCKERFILE_PATH}" >&2
  exit 1
fi

if [[ -z "${IMAGE_NAME}" ]]; then
  echo "ERROR: IMAGE_NAME is not set" >&2
  exit 1
fi

echo "==> Building image: ${IMAGE_NAME}"

# Extract HOST_PUBLIC_KEY from DOCKER_RUN_ARGS for --build-arg passing
host_pubkey=""
if [[ "${DOCKER_RUN_ARGS}" =~ --build-arg[[:space:]]+HOST_PUBLIC_KEY=(.+)$ ]]; then
  host_pubkey="${BASH_REMATCH[1]}"
fi

if [[ -n "${host_pubkey}" ]]; then
  docker build \
    -t "${IMAGE_NAME}" \
    -f "${DOCKERFILE_PATH}" \
    --build-arg "HOST_PUBLIC_KEY=${host_pubkey}" \
    "${repo_root}"
else
  docker build \
    -t "${IMAGE_NAME}" \
    -f "${DOCKERFILE_PATH}" \
    "${repo_root}"
fi
