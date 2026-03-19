# shellcheck shell=bash

# Top 10 processes by CPU usage
alias pscpu10='ps aux | head -1; ps aux | tail -n +2 | sort -nr -k 3 | head -10'
# Top 10 processes by memory usage
alias psmem10='ps aux | head -1; ps aux | tail -n +2 | sort -nr -k 4 | head -10'

# Memory summary
alias meminfo='free -m -l -t'

# Networking
if _has ss; then
  alias ports='ss -tulan'
else
  alias ports='netstat -tulan'
fi

# IP addresses
alias myip='dig +short myip.opendns.com @resolver1.opendns.com'
if _has ip; then
  alias localip="ip -4 addr show | grep -Eo 'inet ([0-9]+\\.){3}[0-9]+' | grep -Eo '([0-9]+\\.){3}[0-9]+' | grep -v '127\\.0\\.0\\.1'"
else
  alias localip="ifconfig | grep -Eo 'inet (addr:)?([0-9]+\\.){3}[0-9]+' | grep -Eo '([0-9]+\\.){3}[0-9]+' | grep -v '127\\.0\\.0\\.1'"
fi

# Identify the source and type of a shell command
function help() {
  local cmd="$1"
  if [ -z "$cmd" ]; then
    echo "Helps identifying the source/content of a command"
    echo "Usage: help command"
    return
  fi

  local DEFAULT="\033[0;39m" RED="\033[0;31m" GREEN="\033[0;32m"
  local hasBat=0
  _has bat && hasBat=1

  local cmdtest
  cmdtest="$(type "$cmd")" # command -V, which

  # alias
  if [[ $cmdtest == *"is an alias for"* ]]; then
    echo -e "${GREEN}Alias${DEFAULT}"
    alias "$cmd"
    return
  fi

  # function
  if [[ $cmdtest == *"is a shell function"* ]]; then
    echo -e "${GREEN}${cmdtest}${DEFAULT}"
    if [[ $hasBat == 1 ]]; then
      which "$cmd" | bat -l sh
    else
      which "$cmd"
    fi
    return
  fi

  # file
  local f
  f="$(echo "$cmdtest" | sed -E 's/.+\ is\ (.*)/\1/')"
  if [ -f "$f" ]; then
    echo -e "${GREEN}${cmdtest}${DEFAULT}"
    file "$f"
    return
  fi

  # man
  if man "$cmd" >/dev/null 2>&1; then
    echo -e "${GREEN}Found man entry for: ${cmd}${DEFAULT}"
    man "$cmd"
    return
  fi

  # whatis
  local mantest
  mantest="$(man -f "$cmd")"
  if [[ $mantest != *"nothing appropriate"* ]]; then
    echo -e "${GREEN}Found whatis entries for: ${cmd}${DEFAULT}"
    man -f "$cmd"
    return
  fi

  # apropos
  mantest="$(man -k "$cmd")"
  if [[ $mantest != *"nothing appropriate"* ]]; then
    echo -e "${GREEN}Found whatis strings for: ${cmd}${DEFAULT}"
    man -k "$cmd"
    return
  fi

  echo -e "${RED}Could not find anything for: ${cmd}${DEFAULT}"
  return 1
}

# Disk usage for a directory; delegates to ncdu if available
# Arguments:
#   $1 - directory (default: current)
#   $2 - count (default: 20)
#   $3 - depth (default: 1)
diskusage() {
  if _has ncdu; then
    ncdu "${1:-.}"
    return
  fi

  local _dushow _dusort
  if echo zzz | sort -h >/dev/null 2>&1; then
    _dushow="-h"
    _dusort="-h"
  else
    _dushow=""
    _dusort="-n"
  fi

  # shellcheck disable=SC2086  # _dushow and _dusort are intentionally unquoted option flags
  du $_dushow -d "${3:-1}" -t 1K "${1:-.}" | sort $_dusort -r | head -n "${2:-20}"
}

# Tail the system log; falls back to journalctl on systems without /var/log/syslog
function sys_log() {
  local syslog

  if $_is_linux; then
    if [ -f /var/log/syslog ]; then
      syslog=/var/log/syslog
    else
      # No syslog file (e.g. Arch Linux) — use journalctl
      if [[ $# -gt 0 ]]; then
        journalctl -f | grep -i --color=auto -E "$(echo "$*" | tr -s ' ' '|')"
      else
        journalctl -f
      fi
      return
    fi
  elif $_is_osx; then
    syslog=/var/log/system.log
  else
    echo "Unsupported OS: $_OS"
    return
  fi

  if [[ $# -gt 0 ]]; then
    local query
    query=$(echo "$*" | tr -s ' ' '|')
    tail -f "$syslog" | grep -i --color=auto -E "$query"
  else
    tail -f "$syslog"
  fi
}

# Show the top 20 most-used shell commands from history
function history_top_commands() {
  history | awk '{
    # Strip leading whitespace and history number
    sub(/^[[:space:]]*[0-9]+[[:space:]]+/, "")
    # Strip zsh EXTENDED_HISTORY prefix: ": <timestamp>:<elapsed>;"
    sub(/^:[[:space:]]*[0-9]+:[0-9]+;[[:space:]]*/, "")
    if ($0 != "") {
      CMD[$1]++
      count++
    }
  } END {
    for (a in CMD) print CMD[a] " " CMD[a]/count*100 "% " a
  }' | grep -v "./" | column -c3 -s " " -t | sort -nr | nl | head -n20
}
