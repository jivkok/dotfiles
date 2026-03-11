#!/usr/bin/env bash
# Augments an existing Docker test image by running a configure_*.sh script on
# top of it, then retags the result with the same image name.
#
# Usage:
#   augment-image.sh <image> <tool>
#
#   <image>  Full image name OR OS shorthand resolved from tests/.testenv:
#              debian  ->  DEBIAN_DOCKER_IMAGE
#              arch    ->  ARCH_DOCKER_IMAGE
#
#   <tool>   Tool name (go, dotnet, docker, nodejs, python) which is expanded to
#            <tool>/configure_<tool>.sh, OR a path relative to the repo root
#            (e.g. go/configure_go.sh).
#
# Examples:
#   augment-image.sh debian go
#   augment-image.sh arch dotnet
#   augment-image.sh dotfiles-test-debian-5f0235439e97 go/configure_go.sh
set -euo pipefail

# ── Paths ──────────────────────────────────────────────────────────────────────

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tests_root="$(cd "${script_dir}/.." && pwd)"
repo_root="$(cd "${tests_root}/.." && pwd)"
testenv_file="${tests_root}/.testenv"

# ── Args ───────────────────────────────────────────────────────────────────────

if [[ $# -ne 2 ]]; then
  echo "Usage: $(basename "$0") <image|debian|arch> <tool|configure-script>" >&2
  exit 1
fi

image_arg="$1"
tool_arg="$2"

# ── Resolve image name ─────────────────────────────────────────────────────────

resolve_image() {
  local shorthand="$1"
  local key="${shorthand^^}_DOCKER_IMAGE"   # debian -> DEBIAN_DOCKER_IMAGE

  if [[ ! -f "$testenv_file" ]]; then
    echo "ERROR: ${testenv_file} not found; run tests/create-test-envs.sh first" >&2
    exit 1
  fi

  local value
  value=$(grep "^${key}=" "$testenv_file" | cut -d= -f2-)
  if [[ -z "$value" ]]; then
    echo "ERROR: '${key}' not found in ${testenv_file}" >&2
    exit 1
  fi
  echo "$value"
}

case "$image_arg" in
  debian|arch)
    image=$(resolve_image "$image_arg")
    ;;
  *)
    image="$image_arg"
    ;;
esac

# ── Resolve configure script path ─────────────────────────────────────────────

# Accept either a tool name (go) or a relative path (go/configure_go.sh).
if [[ "$tool_arg" == */* ]]; then
  configure_script="$tool_arg"
else
  configure_script="${tool_arg}/configure_${tool_arg}.sh"
fi

if [[ ! -f "${repo_root}/${configure_script}" ]]; then
  echo "ERROR: configure script not found: ${repo_root}/${configure_script}" >&2
  exit 1
fi

# ── Verify image exists ────────────────────────────────────────────────────────

if ! docker image inspect "$image" >/dev/null 2>&1; then
  echo "ERROR: Docker image not found: ${image}" >&2
  exit 1
fi

# ── Build ──────────────────────────────────────────────────────────────────────

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat > "${tmpdir}/Dockerfile" <<EOF
FROM ${image}
USER root
COPY --chown=test:test . /home/test/dotfiles
USER test
WORKDIR /home/test
RUN bash /home/test/dotfiles/${configure_script}
EOF

echo "==> Augmenting image: ${image}"
echo "    configure script: ${configure_script}"

docker build \
  --no-cache \
  -t "${image}" \
  -f "${tmpdir}/Dockerfile" \
  "${repo_root}"

echo "==> Done: ${image}"
