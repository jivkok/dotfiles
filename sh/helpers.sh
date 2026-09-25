# shellcheck shell=bash

# Returns whether the given command is available
_has() {
  command -v "$1" >/dev/null 2>&1
}

# OS detection
_OS="$(uname -s)"
[[ "$_OS" == "Darwin" ]] && _is_osx=true   || _is_osx=false
[[ "$_OS" == "Linux"  ]] && _is_linux=true  || _is_linux=false

# Distro detection (Linux only)
[[ -f /etc/arch-release ]]   && _is_arch=true   || _is_arch=false
[[ -f /etc/debian_version ]] && _is_debian=true || _is_debian=false

# GUI-skip detection: for headless / SSH-only machines (e.g. a Mac administered
# purely over SSH, no keyboard/monitor access). Auto-detects an SSH session;
# override with DOT_SKIP_GUI=1 (force skip) or DOT_SKIP_GUI=0 (force GUI installs
# even over SSH).
if [[ -n "${DOT_SKIP_GUI:-}" ]]; then
  [[ "$DOT_SKIP_GUI" == "1" ]] && _skip_gui=true || _skip_gui=false
elif [[ -n "${SSH_CONNECTION:-}${SSH_TTY:-}" ]]; then
  _skip_gui=true
else
  _skip_gui=false
fi
