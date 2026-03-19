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
REMOTE_OSES=(DEBIAN_REMOTE ARCH_REMOTE)

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

# Remote (minimal) image setup files and hashes
declare -A REMOTE_SETUP_EXTRA_FILES=(
  [DEBIAN_REMOTE]="${repo_root}/linux/configure_packages_minimal_debian.sh"
  [ARCH_REMOTE]="${repo_root}/linux/configure_packages_minimal_arch.sh"
)

declare -A REMOTE_DOCKERFILE=(
  [DEBIAN_REMOTE]="docker/Dockerfile.ubuntu-remote"
  [ARCH_REMOTE]="docker/Dockerfile.arch-remote"
)

declare -A REMOTE_SETUP_HASHES=(
  [DEBIAN_REMOTE]=""
  [ARCH_REMOTE]=""
)
declare -A LAST_REMOTE_SETUP_HASHES=(
  [DEBIAN_REMOTE]=""
  [ARCH_REMOTE]=""
)

declare -A LATEST_REMOTE_DOCKER_IMAGES=(
  [DEBIAN_REMOTE]=""
  [ARCH_REMOTE]=""
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

# Setup files shared across all full OSes: setup/*.sh excluding minimal-only scripts,
# plus the per-tool configure scripts that setup/setup.sh invokes outside that directory.
mapfile -t COMMON_SETUP_FILES < <(
  find "${repo_root}/setup" -name '*.sh' \
    ! -name 'setup-remote-vm.sh' \
    ! -name 'deploy-remote-vm.sh' \
  | sort
)
COMMON_SETUP_FILES+=(
  "${repo_root}/git/configure_git.sh"
  "${repo_root}/python/configure_python.sh"
  "${repo_root}/nodejs/configure_nodejs.sh"
  "${repo_root}/vim/configure_vim.sh"
  "${repo_root}/zsh/configure_zsh.sh"
  "${repo_root}/tmux/configure_tmux.sh"
  "${repo_root}/fzf/configure_fzf.sh"
)

# Remote (minimal) setup files common to all remote OSes
REMOTE_COMMON_SETUP_FILES=(
  "${repo_root}/setup/setup-remote-vm.sh"
  "${repo_root}/setup/setup_functions.sh"
  "${repo_root}/setup/configure_home_symlinks.sh"
  "${repo_root}/setup/configure_locale.sh"
)

# Compute current setup hashes for each OS
for os in "${TARGET_OSES[@]}"; do
  files=("${COMMON_SETUP_FILES[@]}" "${OS_SETUP_EXTRA_FILES[$os]}")
  hash=$(hash_files "${files[@]}")
  OS_SETUP_HASHES[$os]="$hash"
done

# Compute current setup hashes for each remote OS
for remote_os in "${REMOTE_OSES[@]}"; do
  files=("${REMOTE_COMMON_SETUP_FILES[@]}" "${REMOTE_SETUP_EXTRA_FILES[$remote_os]}" "${tests_root}/${REMOTE_DOCKERFILE[$remote_os]}")
  hash=$(hash_files "${files[@]}")
  REMOTE_SETUP_HASHES[$remote_os]="$hash"
done

# Read last known setup hashes from tests/.testenv if it exists
testenv_path="${tests_root}/.testenv"
if [[ -f "${testenv_path}" ]]; then
  echo "Reading ${testenv_path}"
  while IFS='=' read -r key value; do
    # Expect lines like: OSX_SETUP_HASH=abc123 or DEBIAN_REMOTE_SETUP_HASH=abc123
    if [[ "$key" =~ ^([A-Z]+)_SETUP_HASH$ ]]; then
      os="${BASH_REMATCH[1]}"
      LAST_OS_SETUP_HASHES[$os]="$value"
      echo "Last setup hash for ${os}: ${value}"
    elif [[ "$key" =~ ^([A-Z]+_REMOTE)_SETUP_HASH$ ]]; then
      remote_os="${BASH_REMATCH[1]}"
      LAST_REMOTE_SETUP_HASHES[$remote_os]="$value"
      echo "Last setup hash for ${remote_os}: ${value}"
    fi
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
    image_prefix="dotfiles-test-${os,,}-"
    image_name="${image_prefix}${OS_SETUP_HASHES[$os]}"
    if [[ -n "$(docker image ls --quiet --filter reference="${image_name}")" ]]; then
      echo "  Docker image already exists: ${image_name}"
    else
      # Match only full images (hex hash suffix); exclude minimal images (which contain "-remote-")
      old_images=$(docker image ls --format '{{.ID}} {{.Repository}}' \
        | awk -v p="${image_prefix}" '$2 ~ "^" p "[0-9a-f]+$" {print $1}')
      if [[ -n "${old_images}" ]]; then
        echo "  Removing stale images for ${os}..."
        echo "${old_images}" | xargs docker rmi --force 2>/dev/null || true
      fi
      echo "  Building Docker image: ${image_name}..."
      IMAGE_NAME="${image_name}" DOCKERFILE_PATH="${tests_root}/${OS_DOCKERFILE[$os]}" \
        bash "${tests_root}/docker/build-image.sh"
    fi
  fi
done

# Build remote (minimal) Docker images if their setup has changed
# Remote images require the host SSH public key baked in at build time.
_host_pubkey=""
for _keyfile in "${HOME}/.ssh/id_ed25519.pub" "${HOME}/.ssh/id_rsa.pub" "${HOME}/.ssh/id_ecdsa.pub"; do
  if [[ -f "${_keyfile}" ]]; then
    _host_pubkey="$(cat "${_keyfile}")"
    break
  fi
done

for remote_os in "${REMOTE_OSES[@]}"; do
  if [[ "${REMOTE_SETUP_HASHES[$remote_os]}" == "${LAST_REMOTE_SETUP_HASHES[$remote_os]}" ]]; then
    echo "${remote_os} setup is up-to-date."
    continue
  fi

  echo "Setup has changed for: ${remote_os} (${LAST_REMOTE_SETUP_HASHES[$remote_os]:-none} -> ${REMOTE_SETUP_HASHES[$remote_os]})"

  # Normalise: DEBIAN_REMOTE -> debian-remote, ARCH_REMOTE -> arch-remote
  image_prefix="dotfiles-test-${remote_os//_REMOTE/-remote}"
  image_prefix="${image_prefix,,}-"
  image_name="${image_prefix}${REMOTE_SETUP_HASHES[$remote_os]}"

  if [[ -n "$(docker image ls --quiet --filter reference="${image_name}")" ]]; then
    echo "  Docker image already exists: ${image_name}"
  elif [[ -z "${_host_pubkey}" ]]; then
    echo "  WARNING: no SSH public key found; skipping remote image build for ${remote_os}."
  else
    old_images=$(docker image ls --quiet --filter reference="${image_prefix}*")
    if [[ -n "${old_images}" ]]; then
      echo "  Removing stale images for ${remote_os}..."
      echo "${old_images}" | xargs docker rmi --force 2>/dev/null || true
    fi
    echo "  Building Docker image: ${image_name}..."
    IMAGE_NAME="${image_name}" \
    DOCKERFILE_PATH="${tests_root}/${REMOTE_DOCKERFILE[$remote_os]}" \
    DOCKER_RUN_ARGS="--build-arg HOST_PUBLIC_KEY=${_host_pubkey}" \
      bash "${tests_root}/docker/build-image-remote.sh"
  fi
done

# Resolve current Docker image names from existing images (image name is deterministic from hash)
for os in "${TARGET_OSES[@]}"; do
  [[ "${os}" == "OSX" ]] && continue
  image_name="dotfiles-test-${os,,}-${OS_SETUP_HASHES[$os]}"
  if [[ -n "$(docker image ls --quiet --filter reference="${image_name}")" ]]; then
    LATEST_DOCKER_IMAGES[$os]="${image_name}"
    echo "${os}_DOCKER_IMAGE=${LATEST_DOCKER_IMAGES[$os]}"
  fi
done

# Resolve current remote Docker image names
for remote_os in "${REMOTE_OSES[@]}"; do
  image_name="dotfiles-test-${remote_os//_REMOTE/-remote}"
  image_name="${image_name,,}-${REMOTE_SETUP_HASHES[$remote_os]}"
  if [[ -n "$(docker image ls --quiet --filter reference="${image_name}")" ]]; then
    LATEST_REMOTE_DOCKER_IMAGES[$remote_os]="${image_name}"
    echo "${remote_os}_MINIMAL_IMAGE=${LATEST_REMOTE_DOCKER_IMAGES[$remote_os]}"
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
  for remote_os in "${REMOTE_OSES[@]}"; do
    echo "${remote_os}_SETUP_HASH=${REMOTE_SETUP_HASHES[$remote_os]}"
  done
  for os in "${TARGET_OSES[@]}"; do
    [[ "${os}" == "OSX" ]] && continue
    echo "${os}_DOCKER_IMAGE=${LATEST_DOCKER_IMAGES[$os]}"
  done
  # Remote minimal images use a distinct key suffix (_MINIMAL_IMAGE, not _DOCKER_IMAGE)
  # so the standard test runner does not attempt to run doctests inside them.
  # test-remote-configure.sh reads these keys directly.
  for remote_os in "${REMOTE_OSES[@]}"; do
    echo "${remote_os}_MINIMAL_IMAGE=${LATEST_REMOTE_DOCKER_IMAGES[$remote_os]}"
  done
} > "${tests_root}/.testenv"
