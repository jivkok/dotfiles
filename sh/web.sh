# URL-encode strings
alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);"'

# Web servers
alias nginxreload='/usr/local/nginx/sbin/nginx -s reload'
alias nginxtest='/usr/local/nginx/sbin/nginx -t'
alias lightyload='/etc/init.d/lighttpd reload'
alias lightytest='/usr/sbin/lighttpd -f /etc/lighttpd/lighttpd.conf -t'
alias httpdreload='/usr/sbin/apachectl -k graceful'
alias httpdtest='/usr/sbin/apachectl -t && /usr/sbin/apachectl -t -D DUMP_VHOSTS'

os=$(uname -s)

# View HTTP traffic
_interface=eth0
if [ "$os" = "Darwin" ]; then
  _interface=en0
fi
alias httpdump="sudo tcpdump -i $_interface -n -s 0 -w -"
unset _interface

if [ "$os" = "Darwin" ]; then
  for method in GET HEAD POST PUT DELETE TRACE OPTIONS; do
    alias "$method"="lwp-request -m '$method'"
  done
fi

# Start an HTTP server from a directory, optionally specifying the port
function server() {
  local port="${1:-8000}"
  sleep 1 && open "http://localhost:${port}/" &
  # Set the default Content-Type to `text/plain` instead of `application/octet-stream`
  # And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
  python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port"
}

# Start a PHP server from a directory, optionally specifying the port
# (Requires PHP 5.4.0+.)
function phpserver() {
  local interface ip port
  interface=$1
  if [ -z "$interface" ]; then interface=en0; fi
  ip=$(ipconfig getifaddr $interface)
  port="${2:-4000}"
  echo "Interface: $interface; ip: $ip; port: $port"
  sleep 1 && open "http://${ip}:${port}/" &
  php -S "${ip}:${port}"
}
