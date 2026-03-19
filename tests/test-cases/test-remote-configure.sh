#!/usr/bin/env bash
# REQUIRES: docker ssh
set -euo pipefail

DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
tests_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../testlib.sh
source "${tests_root}/testlib.sh"

# Runtime guard: docker and ssh must both be available (REQUIRES header is advisory;
# the runner has a known issue with multi-word REQUIRES so we enforce it here too).
# Do NOT use explicit exit 0 here: on Debian login shells, explicit exit with set -e
# active causes ~/.bash_logout to run under set -e, which can exit 1.
# Instead, wrap all test code in the guard block and fall through to finish_test.
_HAVE_DEPS=1
if ! command -v docker >/dev/null 2>&1 || ! command -v ssh >/dev/null 2>&1; then
  log_info "SKIPPED: docker or ssh not available in this environment"
  _HAVE_DEPS=0
elif [[ -f /.dockerenv ]]; then
  log_info "SKIPPED: running inside a Docker container — minimal SSH ports are mapped to host loopback, not container loopback"
  _HAVE_DEPS=0
fi

if [[ "${_HAVE_DEPS}" == "1" ]]; then

# ── Helpers ────────────────────────────────────────────────────────────────────

CONTAINERS=()

cleanup() {
  for cid in "${CONTAINERS[@]}"; do
    docker rm -f "${cid}" >/dev/null 2>&1 || true
  done
}
trap cleanup EXIT

# Start a remote minimal container and return the SSH port via stdout.
start_remote_container() {
  local image="$1"
  local cid port

  cid=$(docker run -d --rm -P "${image}")
  CONTAINERS+=("${cid}")

  # Get the mapped SSH port (container exposes 22)
  port=$(docker inspect --format '{{(index (index .NetworkSettings.Ports "22/tcp") 0).HostPort}}' "${cid}")
  echo "${cid}:${port}"
}

# Run deploy-remote-vm.sh against a running container and return exit code.
deploy_to_container() {
  local port="$1"
  DOT_PULL_DOTFILES=0 DOT_RELOAD_SHELL=0 \
    bash "${DOTDIR}/setup/deploy-remote-vm.sh" \
      -p "${port}" "test@127.0.0.1"
}

# SSH into container and check a command exists.
ssh_check_cmd() {
  local port="$1"
  local cmd="$2"
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p "${port}" test@127.0.0.1 \
    "bash -li -c 'command -v ${cmd} >/dev/null 2>&1'"
}

# SSH into container and check a command does NOT exist.
ssh_check_cmd_absent() {
  local port="$1"
  local cmd="$2"
  ! ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p "${port}" test@127.0.0.1 \
    "bash -li -c 'command -v ${cmd} >/dev/null 2>&1'"
}

# SSH into container and check a file exists.
ssh_check_file() {
  local port="$1"
  local path="$2"
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p "${port}" test@127.0.0.1 \
    "bash -li -c 'test -f ${path}'"
}

# SSH into container and check a symlink target.
ssh_check_symlink() {
  local port="$1"
  local link="$2"
  ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p "${port}" test@127.0.0.1 \
    "bash -li -c 'test -L ${link}'"
}

# Run assertions against a deployed container.
assert_minimal_setup() {
  local label="$1"
  local port="$2"

  log_trace "--- ${label}: bash login shell startup ---"

  startup_errors=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p "${port}" test@127.0.0.1 \
    "bash -l -c true" 2>&1 >/dev/null)
  if [[ -z "${startup_errors}" ]]; then
    ok "${label}: bash login shell starts with no errors"
  else
    fail "${label}: bash login shell produced errors on startup: ${startup_errors}"
  fi

  log_trace "--- ${label}: minimal required packages ---"

  # Core CLI tools
  for cmd in bat curl eza git jq mosh ranger rg tmux vim; do
    if ssh_check_cmd "${port}" "${cmd}"; then
      ok "${label}: command available: ${cmd}"
    else
      fail "${label}: command not found: ${cmd}"
    fi
  done

  # Diagnostics
  for cmd in htop lsof strace; do
    if ssh_check_cmd "${port}" "${cmd}"; then
      ok "${label}: command available: ${cmd}"
    else
      fail "${label}: command not found: ${cmd}"
    fi
  done

  # fd (available as 'fd' on arch, or 'fdfind'/'fd' symlink on debian)
  if ssh_check_cmd "${port}" "fd" || ssh_check_cmd "${port}" "fdfind"; then
    ok "${label}: fd is available"
  else
    fail "${label}: fd / fdfind not found"
  fi

  log_trace "--- ${label}: minimal excluded tools ---"

  # Heavy tools must NOT be present
  for cmd in node pipx zsh; do
    if ssh_check_cmd_absent "${port}" "${cmd}"; then
      ok "${label}: correctly absent: ${cmd}"
    else
      fail "${label}: should not be installed: ${cmd}"
    fi
  done

  # oh-my-zsh must NOT be present
  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p "${port}" test@127.0.0.1 \
      "bash -li -c 'test ! -d ~/.oh-my-zsh'" 2>/dev/null; then
    ok "${label}: oh-my-zsh directory absent"
  else
    fail "${label}: oh-my-zsh should not be installed"
  fi

  log_trace "--- ${label}: shell profiles ---"

  # Tilde paths below are passed as strings to the remote shell, which expands them.
  # shellcheck disable=SC2088
  if ssh_check_file "${port}" "~/.bash_profile"; then
    ok "${label}: ~/.bash_profile exists"
  else
    fail "${label}: ~/.bash_profile missing"
  fi

  # shellcheck disable=SC2088
  if ssh_check_file "${port}" "~/.bashrc"; then
    ok "${label}: ~/.bashrc exists"
  else
    fail "${label}: ~/.bashrc missing"
  fi

  # zshrc must NOT be written by minimal setup
  if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -p "${port}" test@127.0.0.1 \
      "bash -li -c 'test ! -f ~/.zshrc'" 2>/dev/null; then
    ok "${label}: ~/.zshrc absent (minimal profile)"
  else
    fail "${label}: ~/.zshrc should not exist in minimal profile"
  fi

  log_trace "--- ${label}: tmux config symlink ---"

  # shellcheck disable=SC2088
  if ssh_check_symlink "${port}" "~/.tmux.conf"; then
    ok "${label}: ~/.tmux.conf is a symlink"
  else
    fail "${label}: ~/.tmux.conf is not a symlink"
  fi
}

# ── Read remote image names from .testenv ──────────────────────────────────────

testenv_file="${tests_root}/.testenv"
DEBIAN_REMOTE_IMAGE=""
ARCH_REMOTE_IMAGE=""

if [[ -f "${testenv_file}" ]]; then
  while IFS='=' read -r key value; do
    case "${key}" in
      DEBIAN_REMOTE_MINIMAL_IMAGE) DEBIAN_REMOTE_IMAGE="${value}" ;;
      ARCH_REMOTE_MINIMAL_IMAGE)   ARCH_REMOTE_IMAGE="${value}" ;;
    esac
  done < "${testenv_file}"
fi

# ── Debian remote test ─────────────────────────────────────────────────────────

if [[ -n "${DEBIAN_REMOTE_IMAGE}" ]]; then
  log_trace "--- Debian remote: starting container ---"
  result=$(start_remote_container "${DEBIAN_REMOTE_IMAGE}")
  debian_cid="${result%%:*}"
  debian_port="${result##*:}"
  log_trace "Debian container: ${debian_cid} (SSH port ${debian_port})"

  log_trace "--- Debian remote: deploying minimal setup (run 1) ---"
  if deploy_to_container "${debian_port}"; then
    ok "Debian: deploy-remote-vm.sh exited 0 (run 1)"
  else
    fail "Debian: deploy-remote-vm.sh failed (run 1)"
  fi

  assert_minimal_setup "Debian" "${debian_port}"

  log_trace "--- Debian remote: deploying minimal setup (run 2 — idempotency) ---"
  if deploy_to_container "${debian_port}"; then
    ok "Debian: deploy-remote-vm.sh exited 0 (run 2)"
  else
    fail "Debian: deploy-remote-vm.sh failed (run 2 — idempotency)"
  fi
else
  log_info "SKIPPED: Debian remote image not found in .testenv (run create-test-envs.sh first)"
fi

# ── Arch remote test ───────────────────────────────────────────────────────────

if [[ -n "${ARCH_REMOTE_IMAGE}" ]]; then
  log_trace "--- Arch remote: starting container ---"
  result=$(start_remote_container "${ARCH_REMOTE_IMAGE}")
  arch_cid="${result%%:*}"
  arch_port="${result##*:}"
  log_trace "Arch container: ${arch_cid} (SSH port ${arch_port})"

  log_trace "--- Arch remote: deploying minimal setup (run 1) ---"
  if deploy_to_container "${arch_port}"; then
    ok "Arch: deploy-remote-vm.sh exited 0 (run 1)"
  else
    fail "Arch: deploy-remote-vm.sh failed (run 1)"
  fi

  assert_minimal_setup "Arch" "${arch_port}"

  log_trace "--- Arch remote: deploying minimal setup (run 2 — idempotency) ---"
  if deploy_to_container "${arch_port}"; then
    ok "Arch: deploy-remote-vm.sh exited 0 (run 2)"
  else
    fail "Arch: deploy-remote-vm.sh failed (run 2 — idempotency)"
  fi
else
  log_info "SKIPPED: Arch remote image not found in .testenv (run create-test-envs.sh first)"
fi

fi # end _HAVE_DEPS guard

# ── Summary ────────────────────────────────────────────────────────────────────
finish_test
