#!/usr/bin/env bash
# tmux status bar CPU/RAM helper - cross-platform, no plugin dependency
#
# Usage:
#   tmux-status-cpu.sh cpu   - CPU usage %, colored by load
#   tmux-status-cpu.sh ram   - RAM usage %, colored by load
#   tmux-status-cpu.sh all   - "CPU:XX% RAM:XX%" (default)

CACHE_DIR="${TMPDIR:-/tmp}"
CPU_CACHE="$CACHE_DIR/tmux_cpu_stat"

color_for() {
    # $1 = percentage (integer)
    local pct=$1
    if (( pct >= 80 )); then
        echo "red"
    elif (( pct >= 50 )); then
        echo "yellow"
    else
        echo "green"
    fi
}

cpu_percentage() {
    local os pct=0
    os=$(uname -s)

    if [[ "$os" == "Linux" ]]; then
        # /proc/stat gives cumulative counters since boot; diff against the
        # previous sample (cached) to get load over the last status-interval.
        read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
        local idle_all=$((idle + iowait))
        local total=$((user + nice + system + idle_all + irq + softirq + steal))

        if [[ -f "$CPU_CACHE" ]]; then
            local prev_total prev_idle dtotal didle
            read -r prev_total prev_idle < "$CPU_CACHE"
            dtotal=$((total - prev_total))
            didle=$((idle_all - prev_idle))
            (( dtotal > 0 )) && pct=$(( 100 * (dtotal - didle) / dtotal ))
        fi
        echo "$total $idle_all" > "$CPU_CACHE"
    elif [[ "$os" == "Darwin" ]]; then
        pct=$(top -l 1 -n 0 2>/dev/null | awk -F'[:,%]' '
            /CPU usage/ {
                for (i = 1; i <= NF; i++) {
                    if ($i ~ /idle/) {
                        v = $(i - 1)
                        gsub(/ /, "", v)
                        printf "%d", 100 - v
                    }
                }
            }')
    fi

    echo "${pct:-0}"
}

ram_percentage() {
    local os pct=0
    os=$(uname -s)

    if [[ "$os" == "Linux" ]]; then
        pct=$(awk '
            /^MemTotal:/     { total = $2 }
            /^MemAvailable:/ { avail = $2 }
            END { if (total > 0) printf "%d", 100 * (total - avail) / total }
        ' /proc/meminfo)
    elif [[ "$os" == "Darwin" ]]; then
        local page_size total_pages free_pages
        page_size=$(sysctl -n hw.pagesize)
        total_pages=$(( $(sysctl -n hw.memsize) / page_size ))
        free_pages=$(vm_stat | awk '/Pages free/ { gsub(/\./, "", $3); print $3 }')
        (( total_pages > 0 )) && pct=$(( 100 * (total_pages - free_pages) / total_pages ))
    fi

    echo "${pct:-0}"
}

fmt() {
    # $1 = label, $2 = percentage
    printf '#[fg=%s]%s:%s%%#[default]' "$(color_for "$2")" "$1" "$2"
}

main() {
    case "${1:-all}" in
        cpu) fmt CPU "$(cpu_percentage)" ;;
        ram) fmt RAM "$(ram_percentage)" ;;
        all)
            printf '%s %s' "$(fmt CPU "$(cpu_percentage)")" "$(fmt RAM "$(ram_percentage)")"
            ;;
        *)
            echo "Usage: $(basename "$0") cpu|ram|all" >&2
            exit 1
            ;;
    esac
}

# Sourcing (tests) only defines the functions above.
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
