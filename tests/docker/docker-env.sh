#!/usr/bin/env bash
# Shared Docker environment helpers for the test harness (sourced, not executed).
#
#   docker_ensure_running      make sure the Docker daemon answers; on macOS start it
#                              if needed. Sets DOCKER_UNAVAILABLE_REASON on failure.
#   docker_platform_for <os>   platform an OS's image must run as (empty = native).
#   docker_env_check <os>      can <os>'s image be built/run here? Sets
#                              DOCKER_ENV_REASON when not.
#
# Environment knobs:
#   DOTFILES_TEST_NO_DOCKER_START=1   never try to start Docker, only report.
#   DOTFILES_TEST_DOCKER_TIMEOUT=<s>  how long to wait for the daemon (default 180).
#   DOTFILES_TEST_ARCH_PLATFORM=<p>   platform for the Arch images (default linux/amd64;
#                                     the official archlinux image has no arm64 build).
#   DOCKER_UNAVAILABLE_REASON         set (exported) by run-tests.sh after a failed
#                                     start so create-test-envs.sh does not retry.

# shellcheck disable=SC2034  # DOCKER_ENV_REASON is read by the sourcing script
DOCKER_UNAVAILABLE_REASON="${DOCKER_UNAVAILABLE_REASON:-}"
DOCKER_ENV_REASON=""
declare -A _DOCKER_PLATFORM_PROBE=()   # platform -> "" (ok) | failure reason

_denv_log() {
  if declare -F log_info >/dev/null 2>&1; then log_info "$*"; else echo "$*" >&2; fi
}

# Start the container runtime on macOS. Prefers whatever is installed:
# Docker Desktop, then OrbStack, then Colima.
_docker_start_macos() {
  if [[ -d /Applications/Docker.app || -d "${HOME}/Applications/Docker.app" ]]; then
    open -ga Docker
  elif [[ -d /Applications/OrbStack.app ]]; then
    open -ga OrbStack
  elif command -v colima >/dev/null 2>&1; then
    colima start >/dev/null 2>&1
  else
    return 1
  fi
}

docker_ensure_running() {
  if ! command -v docker >/dev/null 2>&1; then
    DOCKER_UNAVAILABLE_REASON="docker CLI not found in PATH"
    return 1
  fi
  if [[ -n "${DOCKER_UNAVAILABLE_REASON}" ]]; then return 1; fi
  if docker info >/dev/null 2>&1; then return 0; fi

  if [[ "${DOTFILES_TEST_NO_DOCKER_START:-0}" == "1" ]]; then
    DOCKER_UNAVAILABLE_REASON="Docker daemon is not running (auto-start disabled by DOTFILES_TEST_NO_DOCKER_START)"
    return 1
  fi
  if [[ "$(uname -s)" != "Darwin" ]]; then
    DOCKER_UNAVAILABLE_REASON="Docker daemon is not running (start it, e.g. 'sudo systemctl start docker')"
    return 1
  fi

  _denv_log "Docker daemon is not running; starting it..."
  if ! _docker_start_macos; then
    DOCKER_UNAVAILABLE_REASON="Docker daemon is not running and no runtime (Docker Desktop, OrbStack, Colima) could be started"
    return 1
  fi

  local timeout="${DOTFILES_TEST_DOCKER_TIMEOUT:-180}" waited=0
  while ! docker info >/dev/null 2>&1; do
    if (( waited >= timeout )); then
      DOCKER_UNAVAILABLE_REASON="Docker daemon did not become ready within ${timeout}s after start"
      return 1
    fi
    sleep 2
    waited=$((waited + 2))
  done
  _denv_log "Docker is ready (after ${waited}s)."
  return 0
}

# Platform an OS's image must be built and run as. Empty means the daemon's native one.
docker_platform_for() {
  case "$1" in
    ARCH|ARCH_REMOTE) printf '%s' "${DOTFILES_TEST_ARCH_PLATFORM:-linux/amd64}" ;;
    *) printf '' ;;
  esac
}

# Native platform of the daemon, e.g. linux/arm64.
_docker_native_platform() {
  local arch
  arch="$(docker info --format '{{.Architecture}}' 2>/dev/null)"
  case "$arch" in
    x86_64|amd64)  echo linux/amd64 ;;
    aarch64|arm64) echo linux/arm64 ;;
    *)             echo "linux/${arch}" ;;
  esac
}

# Succeeds if the daemon can run containers of <platform>; otherwise sets
# _DOCKER_PLATFORM_PROBE[<platform>] to the reason. Native platforms need no probe.
_docker_platform_runnable() {
  local platform="$1" arch
  if [[ "$platform" == "$(_docker_native_platform)" ]]; then return 0; fi
  if [[ -z "${_DOCKER_PLATFORM_PROBE[$platform]+x}" ]]; then
    if arch="$(docker run --rm --platform "$platform" alpine uname -m 2>&1)"; then
      _DOCKER_PLATFORM_PROBE[$platform]=""
    else
      _DOCKER_PLATFORM_PROBE[$platform]="cannot run ${platform} containers (emulation unavailable; on Docker Desktop enable Rosetta for x86_64/amd64 emulation): ${arch##*$'\n'}"
    fi
  fi
  [[ -z "${_DOCKER_PLATFORM_PROBE[$platform]}" ]]
}

# Succeeds if <image> exists locally AND is usable as <platform> (empty = native).
# An image built without an explicit --platform from an amd64-pinned base is
# labelled with the build host's platform (arm64) although it holds amd64
# content; `docker run --platform linux/amd64` then cannot find it. Treating such
# an image as missing makes the caller rebuild it with the right label.
docker_image_usable() {
  local image="$1" platform="${2:-}"
  [[ -n "$(docker image ls --quiet --filter reference="${image}")" ]] || return 1
  [[ -z "$platform" ]] || docker image inspect --platform "$platform" "$image" >/dev/null 2>&1
}

# Can <os>'s image be built and run here? Sets DOCKER_ENV_REASON when not.
docker_env_check() {
  local os="$1" platform
  DOCKER_ENV_REASON=""
  if [[ -n "${DOCKER_UNAVAILABLE_REASON}" ]]; then
    DOCKER_ENV_REASON="${DOCKER_UNAVAILABLE_REASON}"
    return 1
  fi
  platform="$(docker_platform_for "$os")"
  if [[ -n "$platform" ]] && ! _docker_platform_runnable "$platform"; then
    DOCKER_ENV_REASON="${_DOCKER_PLATFORM_PROBE[$platform]}"
    return 1
  fi
  return 0
}
