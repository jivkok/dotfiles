#!/usr/bin/env bash
# tmux status bar IP helper - cross-platform with caching
#
# Usage:
#   tmux-status-ip.sh external  - Get external/public IP (cached, IPv4)
#   tmux-status-ip.sh local     - Get local/internal IP
#   tmux-status-ip.sh vpn       - Get VPN IP if connected (prints nothing when disconnected)
#   tmux-status-ip.sh all       - Get all IPs: ↑<external> ↓<local> [vpn <vpn-ip>]

CACHE_DIR="${TMPDIR:-/tmp}"
CACHE_TTL=3600 # 1h

get_external_ip() {
    local cache_file="$CACHE_DIR/tmux_external_ip"
    local now
    now=$(date +%s)

    # Check cache
    if [[ -f "$cache_file" ]]; then
        local cache_time
        # Try GNU stat first (-c %Y), then BSD/macOS stat (-f %m)
        cache_time=$(stat -c %Y "$cache_file" 2>/dev/null || /usr/bin/stat -f %m "$cache_file" 2>/dev/null)
        if [[ -n "$cache_time" ]] && (( now - cache_time < CACHE_TTL )); then
            cat "$cache_file"
            return
        fi
    fi

    # Try each service in order; fall through to the next on empty output.
    # Use -4 to force IPv4 (fits better in status bar).
    local ip=""
    ip=$(curl -4 -s --max-time 3 https://api.ipify.org 2>/dev/null)
    [[ -z "$ip" ]] && ip=$(curl -4 -s --max-time 3 https://icanhazip.com 2>/dev/null)
    [[ -z "$ip" ]] && ip=$(curl -4 -s --max-time 3 https://ipecho.net/plain 2>/dev/null)
    [[ -z "$ip" ]] && ip=$(dig +short +timeout=2 myip.opendns.com @resolver1.opendns.com 2>/dev/null | grep -E '^[0-9]+\.')

    if [[ -n "$ip" ]]; then
        # Atomic write to avoid partial reads under concurrent tmux polling
        echo "$ip" > "${cache_file}.tmp" && mv "${cache_file}.tmp" "$cache_file"
        echo "$ip"
    elif [[ -f "$cache_file" ]]; then
        # Return stale cache if all fetches failed
        cat "$cache_file"
    fi
}

get_local_ip() {
    local os
    os=$(uname -s)
    if [[ "$os" == "Darwin" ]]; then
        local iface
        iface=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')
        [[ -n "$iface" ]] && ipconfig getifaddr "$iface" 2>/dev/null
    elif [[ "$os" == "Linux" ]]; then
        local ip=""
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
        # Fallback: derive source IP from the routing table
        [[ -z "$ip" ]] && ip=$(ip -4 route get 1 2>/dev/null | grep -oP 'src \K[0-9.]+')
        echo "$ip"
    fi
}

get_vpn_ip() {
    local os vpn_ip
    os=$(uname -s)

    if [[ "$os" == "Darwin" ]]; then
        # macOS: find VPN interfaces (utun*, ppp*) with IPv4 addresses.
        # ipsec* was used on older macOS (pre-Sierra) and is omitted here.
        vpn_ip=$(ifconfig 2>/dev/null | awk '
            /^(utun|ppp)[0-9]+:/ { iface=1 }
            /^[a-z]/ && !/^(utun|ppp)/ { iface=0 }
            iface && /inet [0-9]/ { print $2; exit }
        ')
    elif [[ "$os" == "Linux" ]]; then
        # Linux: find VPN interfaces (tun*, tap*, wg*, ppp*) with IPv4 addresses
        vpn_ip=$(ip -4 addr 2>/dev/null | awk '
            /^[0-9]+: (tun|tap|wg|ppp)[0-9]*:/ { iface=1 }
            /^[0-9]+:/ && !/: (tun|tap|wg|ppp)/ { iface=0 }
            iface && /inet / { sub(/\/.*/, "", $2); print $2; exit }
        ')
    fi

    [[ -n "$vpn_ip" ]] && echo "vpn $vpn_ip"
}

case "${1:-all}" in
    external) get_external_ip ;;
    local)    get_local_ip ;;
    vpn)      get_vpn_ip ;;
    all)
        local_ip=$(get_local_ip)
        ext_ip=$(get_external_ip)
        vpn_seg=$(get_vpn_ip)
        echo "↑${ext_ip} ↓${local_ip}${vpn_seg:+ $vpn_seg}"
        ;;
    *)
        echo "Usage: $(basename "$0") external|local|vpn|all" >&2
        exit 1
        ;;
esac
