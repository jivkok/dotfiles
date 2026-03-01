#!/usr/bin/env bash
set -euo pipefail

tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Compute a sha256 hash of a list of files (combined content).
hash_files() {
  local files=("$@")
  if command -v sha256sum >/dev/null 2>&1; then
    cat "${files[@]}" | sha256sum | cut -c1-12
  else
    cat "${files[@]}" | shasum -a 256 | cut -c1-12
  fi
}

TARGET_OSES=(OSX DEBIAN ARCH)

# Per-OS setup files
declare -A OS_SETUP_EXTRA_FILES=(
  [OSX]="${repo_root}/osx/configure_osx.sh"
  [DEBIAN]="${repo_root}/linux/configure_packages_debian.sh"
  [ARCH]="${repo_root}/linux/configure_packages_arch.sh"
)

# OS Setup hashes
declare -A OS_SETUP_HASHES=(
  [OSX]=""
  [DEBIAN]=""
  [ARCH]=""
)
declare -A LAST_OS_SETUP_HASHES=(
  [OSX]=""
  [DEBIAN]=""
  [ARCH]=""
)

declare -A OS_DOCKERFILE=(
  [DEBIAN]="docker/Dockerfile.ubuntu"
  [ARCH]="docker/Dockerfile.arch"
)

declare -A LATEST_DOCKER_IMAGES=(
  [DEBIAN]=""
  [ARCH]=""
)

# Detect host OS
case "$(uname -s)" in
  Darwin) HOST_OS="OSX" ;;
  Linux)
    if [[ -f /etc/arch-release ]]; then
      HOST_OS="ARCH"
    elif grep -qiE '^ID(_LIKE)?=.*debian' /etc/os-release 2>/dev/null; then
      HOST_OS="DEBIAN"
    else
      echo "ERROR: unsupported Linux distro" >&2; exit 1
    fi
    ;;
  *) echo "ERROR: unsupported OS: $(uname -s)" >&2; exit 1 ;;
esac

# Setup files shared across all OSes
mapfile -t COMMON_SETUP_FILES < <(find "${repo_root}/setup" -name '*.sh' | sort)

# Compute current setup hashes for each OS
for os in "${TARGET_OSES[@]}"; do
  files=("${COMMON_SETUP_FILES[@]}" "${OS_SETUP_EXTRA_FILES[$os]}")
  hash=$(hash_files "${files[@]}")
  OS_SETUP_HASHES[$os]="$hash"
done

# Read last known setup hashes from tests/.testenv if it exists
testenv_path="${tests_root}/.testenv"
if [[ -f "${testenv_path}" ]]; then
  echo "Reading ${testenv_path}"
  while IFS='=' read -r key value; do
    # Expect lines like: OSX_SETUP_HASH=abc123
    [[ "$key" =~ ^([A-Z]+)_SETUP_HASH$ ]] || continue
    os="${BASH_REMATCH[1]}"
    LAST_OS_SETUP_HASHES[$os]="$value"
    echo "Last setup hash for ${os}: ${value}"
  done < "${testenv_path}"
else
  echo "No existing ${testenv_path} found. Assuming all setups are new."
fi

# Identify OSes whose setup files have changed. Update their env.
# If that OS matches the local OS, then just run /setup/setup.sh to update the test environment.
# If that OS does not match the local OS, need to set up a test env via Docker.
# Supported Docker envs: DEBIAN, ARCH. OSX is not supported as a Docker target.
# Steps for creating Docker test env:
# 1. Generate Docker image name based on OS and its setup hash (e.g. dotfiles-test-debian-abc123). If such image exists, skip rest of steps.
# 2. Pick a Dockerfile: DEBIAN -> Dockerfile.ubuntu; ARCH -> Dockerfile.arch.
# 3. Build the image - using build-docker-image.sh, passing IMAGE_NAME and DOCKERFILE_PATH as env vars.
#    The Dockerfile should copy the repo into the image, then execute the setup script inside the image to set up the test environment.
#    Preserve the name of the latest generated image for each OS in LATEST_DOCKER_IMAGES. This will be serialized to tests/.testenv by test runs to pick up environments to run in.

for os in "${TARGET_OSES[@]}"; do
  if [[ "${OS_SETUP_HASHES[$os]}" == "${LAST_OS_SETUP_HASHES[$os]}" ]]; then
    echo "${os} setup is up-to-date."
    continue
  fi

  echo "Setup has changed for: ${os} (${LAST_OS_SETUP_HASHES[$os]:-none} -> ${OS_SETUP_HASHES[$os]})"

  if [[ "${os}" == "${HOST_OS}" ]]; then
    echo "  Running setup locally for ${os}..."
    DOT_PULL_DOTFILES=0 DOT_RELOAD_SHELL=0 bash "${repo_root}/setup/setup.sh" \
      || { echo "ERROR: local setup failed (exit code $?)" >&2; exit 1; }
  elif [[ "${os}" == "OSX" ]]; then
    echo "  Skipping ${os}: Docker target not supported."
  else
    image_name="dotfiles-test-${os,,}-${OS_SETUP_HASHES[$os]}"
    if docker image inspect "${image_name}" >/dev/null 2>&1; then
      echo "  Docker image already exists: ${image_name}"
    else
      echo "  Building Docker image: ${image_name}..."
      IMAGE_NAME="${image_name}" DOCKERFILE_PATH="${tests_root}/${OS_DOCKERFILE[$os]}" \
        bash "${tests_root}/docker/build-image.sh"
    fi
  fi
done

# Resolve current Docker image names from existing images (image name is deterministic from hash)
for os in "${TARGET_OSES[@]}"; do
  [[ "${os}" == "OSX" ]] && continue
  image_name="dotfiles-test-${os,,}-${OS_SETUP_HASHES[$os]}"
  if docker image inspect "${image_name}" >/dev/null 2>&1; then
    LATEST_DOCKER_IMAGES[$os]="${image_name}"
    echo "${os}_DOCKER_IMAGE=${LATEST_DOCKER_IMAGES[$os]}"
  fi
done

# Write updated setup state back to tests/.testenv. Include:
# - HOST_OS
# - Hashes of setup files for each OS
# - Current Docker images
{
  echo "HOST_OS=${HOST_OS}"
  for os in "${TARGET_OSES[@]}"; do
    echo "${os}_SETUP_HASH=${OS_SETUP_HASHES[$os]}"
  done
  for os in "${TARGET_OSES[@]}"; do
    [[ "${os}" == "OSX" ]] && continue
    echo "${os}_DOCKER_IMAGE=${LATEST_DOCKER_IMAGES[$os]}"
  done
} > "${tests_root}/.testenv"
