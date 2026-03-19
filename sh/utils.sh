# shellcheck shell=bash

# lazy man extract - example: ex tarball.tar
function ex() {
  if [ -f "$1" ]; then
    case $1 in
    *.tar.bz2) tar xjfv "$1" ;;
    *.tar.gz) tar xzfv "$1" ;;
    *.tar.xz) tar xJfv "$1" ;;
    *.tar.zst | *.zst)
      if ! _has zstd; then
        echo "zstd is required to extract '$1'"
        return 1
      fi
      if [[ "$1" == *.tar.* ]]; then
        tar -I zstd -xvf "$1"
      else
        zstd --decompress "$1"
      fi
      ;;
    *.bz2) bunzip2 "$1" ;;
    *.rar) rar x "$1" ;;
    *.gz) gunzip "$1" ;;
    *.tar) tar xfv "$1" ;;
    *.tbz2) tar xjfv "$1" ;;
    *.tgz) tar xzfv "$1" ;;
    *.zip) unzip "$1" ;;
    *.Z) uncompress "$1" ;;
    *.7z) 7z x "$1" ;;
    *) echo "'$1' cannot be extracted via extract()" ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# ls for archives (inspired by `extract`)
lsz() {
  if [ $# -ne 1 ]; then
    echo "lsz filename.[tar,tgz,gz,zip,etc]"
    return 1
  fi
  if [ -f "$1" ]; then
    case $1 in
    *.tar.bz2 | *.tar.gz | *.tar | *.tbz2 | *.tgz) tar tvf "$1" ;;
    *.tar.xz) tar tvf "$1" ;;
    *.zip) unzip -l "$1" ;;
    *.7z) 7z l "$1" ;;
    *.rar) rar l "$1" ;;
    *) echo "'$1' unrecognized." ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Copy user's SSH public key to a remote machine; delegates to ssh-copy-id if available
function ssh_copy_id() {
  local host="${1}"
  local port="${2:-22}"

  if _has ssh-copy-id; then
    ssh-copy-id -p "${port}" "${host}"
    return
  fi

  local key=""
  local candidate
  for candidate in ~/.ssh/id_ed25519.pub ~/.ssh/id_ecdsa.pub ~/.ssh/id_rsa.pub; do
    if [ -f "$candidate" ]; then
      key="$candidate"
      break
    fi
  done

  if [ -z "$key" ]; then
    echo "No SSH public key found in ~/.ssh/ (tried id_ed25519.pub, id_ecdsa.pub, id_rsa.pub)"
    return 1
  fi

  ssh "${host}" -p "${port}" "mkdir -p ~/.ssh && chmod 0700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 0644 ~/.ssh/authorized_keys && cat >> ~/.ssh/authorized_keys" < "$key"
}

# Create a .tar.gz archive using gzip
function targz() {
  local tmpFile="${*%/}.tar"
  tar -cvf "${tmpFile}" --exclude=".DS_Store" "${@}" || return 1
  echo "Compressing .tar using gzip…"
  gzip -v "${tmpFile}" || return 1
  echo "${tmpFile}.gz created successfully."
}

# Create a data URL from a file
function dataurl() {
  local mimeType
  mimeType=$(file -b --mime-type "$1")
  if [[ $mimeType == text/* ]]; then
    mimeType="${mimeType};charset=utf-8"
  fi
  echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')"
}

# Format and syntax-highlight JSON from stdin using the best available tool
_json_format() {
  if _has jq; then
    jq '.'
  elif _has bat; then
    python3 -m json.tool | bat -l json
  else
    python3 -m json.tool
  fi
}

# Syntax-highlight JSON strings or files
# Usage: `json '{"foo":42}'` or `echo '{"foo":42}' | json`
function json() {
  if [ -t 0 ]; then # argument
    _json_format <<<"$*"
  else # pipe
    _json_format
  fi
}

# Support multiple encodings (URL, base64, Unicode, etc.)
function encode() {
  local encoding="$1"
  local string="$2"

  if [ -z "$encoding" ] || [ -z "$string" ]; then
    echo "Encode string"
    echo "Usage: encode <encoding> <string>"
    echo " - encoding: url, html, base64, utf8"
    return
  fi

  if [ "$encoding" = "url" ]; then
    echo -n "$string" | perl -pe 's/([^-_.~A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg'
  elif [ "$encoding" = "html" ]; then
    python3 -c "import html, sys; print(html.escape(sys.argv[1]))" "$string"
  elif [ "$encoding" = "base64" ]; then
    echo -n "$string" | base64
  elif [ "$encoding" = "utf8" ]; then
    # shellcheck disable=SC2046  # word splitting is intentional: each hex byte becomes a separate arg
    printf "\\\x%s" $(printf "%s" "$string" | xxd -p -c1 -u)
  else
    echo "Unsupported encoding: $encoding"
    return
  fi
}

# Decode strings in various encodings (URL, base64, Unicode, etc.)
function decode() {
  local encoding="$1"
  local string="$2"

  if [ -z "$encoding" ] || [ -z "$string" ]; then
    echo "Decode string"
    echo "Usage: decode <encoding> <string>"
    echo " - encoding: url, html, base64, utf8"
    return
  fi

  if [ "$encoding" = "url" ]; then
    echo -n "$string" | perl -pe 's/\+/ /g; s/%([0-9a-f]{2})/chr(hex($1))/eig'
  elif [ "$encoding" = "html" ]; then
    python3 -c "import html, sys; print(html.unescape(sys.argv[1]))" "$string"
  elif [ "$encoding" = "base64" ]; then
    echo -n "$string" | base64 --decode
  elif [ "$encoding" = "utf8" ]; then
    perl -e 'binmode(STDOUT, ":utf8"); my $s = $ARGV[0]; $s =~ s/\\x([0-9a-fA-F]{2})/chr(hex($1))/ge; print $s, "\n"' "$string"
  else
    echo "Unsupported encoding: $encoding"
    return
  fi
}

# Encode a given image file as base64 and output a CSS background property to clipboard
function img2base64() {
  if ! _has pbcopy; then
    echo "Error: pbcopy is not available on this system"
    return 1
  fi
  openssl base64 -in "$1" | awk -v ext="${1#*.}" '{ str1=str1 $0 }END{ print "background:url(data:image/"ext";base64,"str1");" }' | pbcopy
  echo "$1 encoded as base64 and copied as css background property to clipboard"
}

# Encode a given font file as base64 and output a CSS src property to clipboard
function font_base64() {
  if ! _has pbcopy; then
    echo "Error: pbcopy is not available on this system"
    return 1
  fi
  openssl base64 -in "$1" | awk -v ext="${1#*.}" '{ str1=str1 $0 }END{ print "src:url(\"data:font/"ext";base64,"str1"\")  format(\"woff\");" }' | pbcopy
  echo "$1 encoded as font and copied as css src property to clipboard"
}

# Get a character's Unicode code point
function codepoint() {
  perl -e "use utf8; print sprintf('U+%04X', ord(\"$*\"))"
  # print a newline unless we're piping the output to another program
  if [ -t 1 ]; then
    echo "" # newline
  fi
}

# Show all the names (CNs and SANs) listed in the SSL certificate for a given domain
function getcertnames() {
  if [ -z "${1}" ]; then
    echo "ERROR: No domain specified."
    return 1
  fi

  local domain="${1}"
  local port="${2:-443}"
  echo "Testing ${domain}:${port}…"
  echo "" # newline

  local tmp
  tmp=$(echo | openssl s_client -connect "${domain}:${port}" -servername "${domain}" -connect_timeout 5 2>/dev/null)

  if [[ "${tmp}" = *"-----BEGIN CERTIFICATE-----"* ]]; then
    local cert_info
    cert_info=$(echo "${tmp}" | openssl x509 -noout -subject -ext subjectAltName 2>/dev/null)
    echo "Common Name:"
    echo "" # newline
    echo "${cert_info}" | grep "^subject" | sed -E 's/.*CN *= *//'
    echo "" # newline
    echo "Subject Alternative Name(s):"
    echo "" # newline
    echo "${cert_info}" | grep -oE 'DNS:[^,]+' | sed 's/DNS: *//'
    return 0
  else
    echo "ERROR: Certificate not found."
    return 1
  fi
}

# MAC vendor lookup
function mac_lookup() {
  local mac="$1"
  if [ -z "$mac" ]; then
    echo "MAC vendor lookup"
    echo "Usage: mac_lookup MAC_address_or_prefix"
    return
  fi

  mac=${mac//:/}
  mac=${mac:0:6}

  if ! [[ "$mac" =~ ^[0-9a-fA-F]{6}$ ]]; then
    echo "Error: invalid MAC address (expected 6 hex characters after stripping colons)"
    return 1
  fi

  curl "https://api.macvendors.com/$mac"
  echo
}

# Compares files or directories with the best available diff tool
# Usage: jdiff file_or_dir_1 file_or_dir_2
jdiff() {
  if [ -z "$2" ]; then
    echo "Compares files or directories"
    echo "Usage: jdiff file_or_dir_1 file_or_dir_2"
    return 1
  fi
  if [ ! -e "$1" ]; then
    echo "$1: does not exist"
    return 1
  fi
  if [ ! -e "$2" ]; then
    echo "$2: does not exist"
    return 1
  fi

  local -a _comp
  if [ -d "$1" ]; then
    if [ -d "$2" ]; then
      _comp=('-Nur')
    else
      echo "Cannot compare directory ( $1 ) with a file ( $2 )"
      return 1
    fi
  else
    if [ ! -d "$2" ]; then
      _comp=('-u')
    else
      echo "Cannot compare file ( $1 ) with a directory ( $2 )"
      return 1
    fi
  fi

  if _has difft; then
    diff "${_comp[@]}" "$1" "$2" | difft
  elif _has delta; then
    diff "${_comp[@]}" "$1" "$2" | delta
  elif _has diff-so-fancy; then
    diff "${_comp[@]}" "$1" "$2" | diff-so-fancy
  elif _has ydiff; then
    diff "${_comp[@]}" "$1" "$2" | ydiff
  elif _has git; then
    git diff --no-index "$1" "$2"
  else
    diff --color=auto "${_comp[@]}" "$1" "$2"
  fi
}
