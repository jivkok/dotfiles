#!/usr/bin/env bash
# Configuring Python

dotdir="$(cd "$(dirname "$0")/.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

install_pipx_package() {
  if [ -z "$1" ]; then
    log_error "install_pipx_package: package name is required."
    return
  fi

  local package="$1"
  local installed
  installed=$(pipx list | grep "package $package")

  if [ -z "$installed" ]; then
    pipx install --quiet "$package"
  fi
}

log_info "Configuring Python3 ..."

if $_is_debian; then
  # sudo add-apt-repository universe
  sudo apt-get update -qq
  install_or_upgrade_apt_package python3
  install_or_upgrade_apt_package python3-pip
  install_or_upgrade_apt_package pipx

  # If the system python3 was upgraded the old venvs reference a missing interpreter.
  # Detect the mismatch and rebuild before attempting any upgrades.
  # Check both the shared venv and individual package venvs — the shared lib may have been
  # updated already while individual venvs still reference the old interpreter.
  _sys_python_minor=$(python3 -c "import sys; print(sys.version_info.minor)" 2>/dev/null)
  _shared_python=$(ls ~/.local/pipx/shared/lib/ 2>/dev/null | grep '^python' | head -1 | sed 's/python//')
  _stale_venv=$(ls ~/.local/pipx/venvs/*/lib/ 2>/dev/null | grep '^python' | grep -v "^python3\.${_sys_python_minor}$" | head -1)
  if { [ -n "$_shared_python" ] && [ "$_shared_python" != "3.${_sys_python_minor}" ]; } || [ -n "$_stale_venv" ]; then
    log_trace "Pipx venvs use stale Python (shared=${_shared_python}, stale_venv=${_stale_venv}): rebuilding against 3.${_sys_python_minor}"
    pipx reinstall-all --quiet
  fi

elif $_is_arch; then
  install_or_upgrade_pacman_package python3
  install_or_upgrade_pacman_package python-pip
  install_or_upgrade_pacman_package python-pipx

elif $_is_osx; then
  install_or_upgrade_brew_package python3
  _python3_result=$?
  case $_python3_result in
    0)
      brew postinstall --quiet python3
      brew link --quiet python3
      brew reinstall --quiet pipx
      ;;
    1)
      install_or_upgrade_brew_package pipx
      ;;
    2)
      log_error "Failed to install or upgrade python3."
      return 1
      ;;
  esac

  _pipx_python_minor=$(python3 -c "import sys; print(sys.version_info.minor)" 2>/dev/null)
  _shared_python=$(ls ~/.local/pipx/shared/lib/ 2>/dev/null | grep '^python' | head -1 | sed 's/python//')
  _stale_venv=$(ls ~/.local/pipx/venvs/*/lib/ 2>/dev/null | grep '^python' | grep -v "^python3\.${_pipx_python_minor}$" | head -1)
  if { [ -n "$_shared_python" ] && [ "$_shared_python" != "3.${_pipx_python_minor}" ]; } || [ -n "$_stale_venv" ]; then
    log_trace "Pipx venvs use stale Python (shared=${_shared_python}, stale_venv=${_stale_venv}): rebuilding against 3.${_pipx_python_minor}"
    pipx reinstall-all --quiet
  elif [ "${_python3_result:-1}" = "0" ]; then
    pipx reinstall-all --quiet
  fi

else
  log_error "Unsupported OS: ${_OS}"
  return 1
fi

log_trace "Installing/updating packages (user-scope)"

pipx upgrade-all --quiet >/dev/null
install_pipx_package uv      # An extremely fast Python package installer and resolver
install_pipx_package glances # system stats      APT YAY BREW
install_pipx_package httpie  # curl-like with colorized output    APT PACMAN BREW
install_pipx_package icdiff  # improved color diff. Use it for diffing two files.     HOME_BIN

# Packages used at one point
# python3 -m pip install --user --upgrade jsbeautifier # reformat and reindent JavaScript code. jsbeautifier.org. Use with 'js-beautify somefile.js'
# python3 -m pip install --user --upgrade jupyter # Jupyter Notebooks
# python3 -m pip install --user --upgrade mitmproxy # http traffic interception
# python3 -m pip install --user --upgrade pygments # syntax highlighter
# python3 -m pip install --user --upgrade pylint # Python linter
# python3 -m pip install --user --upgrade ydiff # color diff. Use it within a Git repo.

log_info "Configuring Python3 done."
