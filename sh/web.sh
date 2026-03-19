# shellcheck shell=bash

# URL-encode a string
function urlencode() {
  python3 -c "import sys, urllib.parse; print(urllib.parse.quote_plus(sys.argv[1]))" "$1"
}

# View HTTP traffic
_interface=eth0
if $_is_osx; then
  _interface=en0
fi
# shellcheck disable=SC2139  # $_interface intentionally expands at definition time
alias httpdump="sudo tcpdump -i $_interface -n -s 0 -A 'tcp port 80 or tcp port 443'"
unset _interface

# Cross-platform URL opener
_open_url() {
  if _has xdg-open; then
    xdg-open "$1"
  elif _has open; then
    open "$1"
  else
    echo "Cannot open URL: no browser opener found (install xdg-open or open)"
  fi
}

# Start an HTTP server from a directory, optionally specifying the port
function server() {
  local port="${1:-8000}"
  sleep 1 && _open_url "http://localhost:${port}/" &
  python3 -m http.server "${port}"
}

# Start a PHP server from a directory, optionally specifying the port
function phpserver() {
  local interface ip port
  interface="${1:-en0}"
  if _has ipconfig; then
    ip=$(ipconfig getifaddr "$interface")
  else
    ip=$(ip -4 addr show "$interface" 2>/dev/null | grep -oE '([0-9]+\.){3}[0-9]+' | head -1)
  fi
  port="${2:-4000}"
  echo "Interface: $interface; ip: $ip; port: $port"
  sleep 1 && _open_url "http://${ip}:${port}/" &
  php -S "${ip}:${port}"
}
