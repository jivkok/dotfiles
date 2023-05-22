# lazy man extract - example: ex tarball.tar
function ex() {
  if [ -f "$1" ]; then
    case $1 in
    *.tar.bz2) tar xjfv "$1" ;;
    *.tar.gz) tar xzfv "$1" ;;
    *.tar.xz) tar xJfv "$1" ;;
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
    *.zip) unzip -l "$1" ;;
    *) echo "'$1' unrecognized." ;;
    esac
  else
    echo "'$1' is not a valid file"
  fi
}

# Simple calculator
function calc() {
  local result=""
  result="$(echo "scale=10;$*" | bc --mathlib | tr -d '\\\n')"
  #                       └─ default (when `--mathlib` is used) is 20
  #
  if [[ "$result" == *.* ]]; then
    # improve the output for decimal numbers
    echo "$result" |
      sed -e 's/^\./0./' \ # add "0" for cases like ".5"
    -e 's/^-\./-0./' \ # add "0" for cases like "-.5"
    -e 's/0*$//;s/\.$//' # remove trailing zeros
  else
    echo "$result"
  fi
  printf "\n"
}

# Copy user's default ssh key to a remote machine
function ssh_copy_id() {
  cat ~/.ssh/id_rsa.pub | ssh "$1" -p "${2:-22}" "mkdir -p ~/.ssh && chmod 0700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 0644 ~/.ssh/authorized_keys && cat >> ~/.ssh/authorized_keys"
}

# Create a .tar.gz archive, using `zopfli`, `pigz` or `gzip` for compression
function targz() {
  local tmpFile="${*%/}.tar"
  tar -cvf "${tmpFile}" --exclude=".DS_Store" "${@}" || return 1

  size=$(
    stat -f"%z" "${tmpFile}" 2>/dev/null # OS X `stat`
    stat -c"%s" "${tmpFile}" 2>/dev/null # GNU `stat`
  )

  local cmd=""
  if ((size < 52428800)) && hash zopfli 2>/dev/null; then
    # the .tar file is smaller than 50 MB and Zopfli is available; use it
    cmd="zopfli"
  else
    if hash pigz 2>/dev/null; then
      cmd="pigz"
    else
      cmd="gzip"
    fi
  fi

  echo "Compressing .tar using \`${cmd}\`…"
  "${cmd}" -v "${tmpFile}" || return 1
  [ -f "${tmpFile}" ] && rm "${tmpFile}"
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

# Syntax-highlight JSON strings or files
# Usage: `json '{"foo":42}'` or `echo '{"foo":42}' | json`
function json() {
  if [ -t 0 ]; then # argument
    python -mjson.tool <<<"$*" | pygmentize -l javascript
  else # pipe
    python -mjson.tool | pygmentize -l javascript
  fi
}

# Support multiple encodings (URL, base64, Unicode, etc.)
function encode() {
  local encoding="$1"
  local string="$2"
  local encoded=""

  if [ -z "$encoding" ] || [ -z "$string" ]; then
    echo "Encode string"
    echo "Usage: encode <encoding> <string>"
    echo " - encoding: url, html, base64, utf8"
    return
  fi

  if [ "$encoding" = "url" ]; then
    echo -n "$string" | perl -pe 's/([^-_.~A-Za-z0-9])/sprintf("%%%02X", ord($1))/seg'
  elif [ "$encoding" = "html" ]; then
    echo -n "$string" | php -R 'echo htmlentities($argn);'
  elif [ "$encoding" = "base64" ]; then
    echo -n "$string" | base64
  elif [ "$encoding" = "utf8" ]; then
    printf "\\\x%s" $(printf "%s" "$string" | xxd -p -c1 -u)
  else
    echo "Unsupported encoding: $encoding"
    return
  fi
}

# Support multiple encodings (URL, base64, Unicode, etc.)
function decode() {
  local encoding="$1"
  local string="$2"
  local encoded=""

  if [ -z "$encoding" ] || [ -z "$string" ]; then
    echo "Encode string"
    echo "Usage: decode <encoding> <string>"
    echo " - encoding: url, html, base64, utf8"
    return
  fi

  if [ "$encoding" = "url" ]; then
    echo -n "$string" | perl -pe 's/\+/ /g; s/%([0-9a-f]{2})/chr(hex($1))/eig'
  elif [ "$encoding" = "html" ]; then
    echo -n "$string" | php -R 'echo html_entity_decode($argn);'
  elif [ "$encoding" = "base64" ]; then
    echo -n "$string" | base64 -D
  elif [ "$encoding" = "utf8" ]; then
    perl -e "binmode(STDOUT, ':utf8'); print \"$string\""
  else
    echo "Unsupported encoding: $encoding"
    return
  fi
}

# encode a given image file as base64 and output css background property to clipboard
function img2base64() {
  openssl base64 -in "$1" | awk -v ext="${1#*.}" '{ str1=str1 $0 }END{ print "background:url(data:image/"ext";base64,"str1");" }' | pbcopy
  echo "$1 encoded as base64 and copied as css background property to clipboard"
}

# encode a given font file as base64 and output css src property to clipboard
function 64font() {
  openssl base64 -in "$1" | awk -v ext="${1#*.}" '{ str1=str1 $0 }END{ print "src:url(\"data:font/"ext";base64,"str1"\")  format(\"woff\");" }' | pbcopy
  echo "$1 encoded as font and copied as css src property to clipboard"
}

# Get a character’s Unicode code point
function codepoint() {
  perl -e "use utf8; print sprintf('U+%04X', ord(\"$*\"))"
  # print a newline unless we’re piping the output to another program
  if [ -t 1 ]; then
    echo "" # newline
  fi
}

# Show all the names (CNs and SANs) listed in the SSL certificate
# for a given domain
function getcertnames() {
  if [ -z "${1}" ]; then
    echo "ERROR: No domain specified."
    return 1
  fi

  local domain="${1}"
  echo "Testing ${domain}…"
  echo "" # newline

  local tmp
  tmp=$(echo -e "GET / HTTP/1.0\nEOT" |
    openssl s_client -connect "${domain}:443" -servername "${domain}" 2>&1)

  if [[ "${tmp}" = *"-----BEGIN CERTIFICATE-----"* ]]; then
    local certText
    certText=$(echo "${tmp}" |
      openssl x509 -text -certopt "no_aux, no_header, no_issuer, no_pubkey, \
            no_serial, no_sigdump, no_signame, no_validity, no_version")
    echo "Common Name:"
    echo "" # newline
    echo "${certText}" | grep "Subject:" | sed -e "s/^.*CN=//" | sed -e "s/\/emailAddress=.*//"
    echo "" # newline
    echo "Subject Alternative Name(s):"
    echo "" # newline
    echo "${certText}" | grep -A 1 "Subject Alternative Name:" |
      sed -e "2s/DNS://g" -e "s/ //g" | tr "," "\n" | tail -n +2
    return 0
  else
    echo "ERROR: Certificate not found."
    return 1
  fi
}

# MAC lookup
function mac-lookup() {
  local mac="$1"
  if [ -z "$mac" ]; then
    echo "MAC vendor lookup"
    echo "Usage: mac-lookup MAC_address_or_prefix"
    return
  fi

  mac=${mac//:/}
  mac=${mac:0:6}

  curl "https://api.macvendors.com/$mac"
}
