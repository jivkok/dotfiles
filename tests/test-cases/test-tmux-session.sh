#!/usr/bin/env bash
# REQUIRES: tmux
# COVERS: bin/tmux-session-save.sh bin/tmux-session-restore.sh
# Round-trip tests for tmux-session-save.sh / tmux-session-restore.sh.
#
# Isolation: a dedicated tmux server (TMUX_TMPDIR) and TMUX_SESSION_SAVE_DIR
# under a temp dir; nothing touches the developer's tmux sessions or saves.
# A `tmux` wrapper first on PATH forces `-f /dev/null` (no user config) and
# records `display-message` text, which is otherwise invisible without an
# attached client.
set -euo pipefail

DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SAVE="${DOTDIR}/bin/tmux-session-save.sh"
RESTORE="${DOTDIR}/bin/tmux-session-restore.sh"

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"

tmpdir="$(mktemp -d)"
tmpdir="$(cd "$tmpdir" && pwd -P)"
real_tmux="$(command -v tmux)"
unset TMUX TMUX_PANE
export TMUX_TMPDIR="${tmpdir}/tmux"
export TMUX_SESSION_SAVE_DIR="${tmpdir}/save"
mkdir -p "$TMUX_TMPDIR" "${tmpdir}/bin"
trap '"$real_tmux" kill-server 2>/dev/null || true; rm -rf "$tmpdir"' EXIT

msg_log="${tmpdir}/messages.log"
cat > "${tmpdir}/bin/tmux" <<EOF
#!/usr/bin/env bash
if [[ "\${1:-}" == "display-message" ]]; then
  printf '%s\n' "\${*:2}" >> "$msg_log"
  exit 0
fi
exec "$real_tmux" -f /dev/null "\$@"
EOF
chmod +x "${tmpdir}/bin/tmux"
export PATH="${tmpdir}/bin:${PATH}"

d1="${tmpdir}/dir one"; d2="${tmpdir}/dir-two"; d3="${tmpdir}/dir3"
mkdir -p "$d1" "$d2" "$d3"

window_names() { tmux list-windows -t "=$1" -F '#{window_name}' | tr '\n' ' ' | sed 's/ $//'; }
pane_paths()   { tmux list-panes -t "$1" -F '#{pane_current_path}' | sort | tr '\n' '|'; }

# kill_server  — kill the test server and wait until it is really gone, so the
# next command does not connect to a server that is still shutting down.
kill_server() {
  local i
  tmux kill-server 2>/dev/null || true
  for ((i = 0; i < 50; i++)); do
    case "$(tmux has-session 2>&1)" in
      *"no server running"* | *"error connecting"*) return 0 ;;
    esac
    sleep 0.1
  done
}

# wait_for_shell <target>  — wait until the pane's foreground command is a shell.
wait_for_shell() {
  local i cmd
  for ((i = 0; i < 50; i++)); do
    cmd="$(tmux list-panes -t "$1" -F '#{pane_current_command}' | head -n1)"
    case "$cmd" in bash | zsh | sh | fish) return 0 ;; esac
    sleep 0.1
  done
  return 1
}

# ── Save ───────────────────────────────────────────────────────────────────────
log_trace "--- save ---"
tmux new-session -d -s s1 -n w1 -c "$d1"
tmux split-window -t s1:w1 -c "$d2"
tmux new-window -t s1: -n w2 -c "$d3"
wait_for_shell s1:w1 || true

bash "$SAVE" >/dev/null
assert_eq "windows.tsv has 2 lines" "2" "$(wc -l < "${TMUX_SESSION_SAVE_DIR}/windows.tsv" | tr -d ' ')"
assert_eq "panes.tsv has 3 lines" "3" "$(wc -l < "${TMUX_SESSION_SAVE_DIR}/panes.tsv" | tr -d ' ')"
assert_file_content "${TMUX_SESSION_SAVE_DIR}/panes.tsv" "$d1"
assert_file_content "${TMUX_SESSION_SAVE_DIR}/panes.tsv" "$d2"

# ── Restore into a fresh server ────────────────────────────────────────────────
log_trace "--- restore ---"
kill_server
tmux new-session -d -s keepalive      # server without s1
: > "$msg_log"
bash "$RESTORE"

check "s1 restored" tmux has-session -t =s1
assert_eq "s1 window names" "w1 w2" "$(window_names s1)"
assert_eq "w1 has 2 panes" "2" "$(tmux_pane_count s1:w1)"
assert_eq "w2 has 1 pane" "1" "$(tmux_pane_count s1:w2)"
assert_eq "w1 pane cwds" "$(printf '%s|%s|' "$d1" "$d2" | tr '|' '\n' | sort | tr '\n' '|')" "$(pane_paths s1:w1)"
assert_eq "w2 pane cwd" "${d3}|" "$(pane_paths s1:w2)"

# ── Existing non-default session is skipped ───────────────────────────────────
log_trace "--- restore: skip existing session ---"
tmux kill-session -t =s1
tmux new-session -d -s s1 -n keep1 -c "$d3"
tmux new-window -t s1: -n keep2 -c "$d3"
: > "$msg_log"
bash "$RESTORE"
assert_eq "existing s1 left unchanged" "keep1 keep2" "$(window_names s1)"
assert_file_content "$msg_log" "skipped existing: s1"

# ── Lone default session is adopted ────────────────────────────────────────────
log_trace "--- restore: adopt lone default session ---"
tmux kill-session -t =s1
tmux new-session -d -s s1 -c "$d3"
if wait_for_shell s1; then
  bash "$RESTORE"
  assert_eq "adopted s1 window names" "w1 w2" "$(window_names s1)"
  assert_eq "adopted w1 has 2 panes" "2" "$(tmux_pane_count s1:w1)"
else
  fail "lone default pane never reached an idle shell"
fi

# ── Missing snapshot ───────────────────────────────────────────────────────────
log_trace "--- restore: missing snapshot ---"
for missing in windows.tsv panes.tsv; do
  partial="${tmpdir}/partial-${missing}"
  mkdir -p "$partial"
  cp "${TMUX_SESSION_SAVE_DIR}"/*.tsv "$partial/"
  rm "${partial}/${missing}"
  TMUX_SESSION_SAVE_DIR="$partial" run_capture bash "$RESTORE"
  assert_eq "restore without ${missing}: exit code" "1" "$rc"
done

finish_test
