#!/usr/bin/env bash
# Snapshot tmux sessions/windows/panes (layout, cwd, and best-effort the
# pane's foreground command line) to disk, so they can be reconstructed
# after a reboot via tmux-session-restore.sh. Deliberately lighter than
# tmux-resurrect: no pane scrollback, no program-specific restore
# strategies (e.g. reopening the file a vim pane had open) - this covers
# only what this setup actually used resurrect for.
#
# Usage: tmux-session-save.sh   (bound to prefix + Ctrl-s)

set -euo pipefail

SAVE_DIR="${TMUX_SESSION_SAVE_DIR:-$HOME/.tmux/session-save}"
mkdir -p "$SAVE_DIR"

# Best-effort: full args of whichever process is in the foreground process
# group of the pane's tty (falls back to the caller's plain command name if
# ps can't determine it, e.g. a minimal ps with no '+' foreground flag).
# Zombies are skipped: a short-lived child (e.g. a git subprocess spawned by
# lazygit) can still be in the tty's foreground process group after it
# exits, and ps then reports its args as the unusable "[name] <defunct>".
foreground_cmdline() {
    local tty="${1#/dev/}"
    ps -o stat=,args= -t "$tty" 2>/dev/null | awk '
        { stat = $1; sub(/^[^ ]+[ \t]+/, ""); if (stat ~ /\+/ && stat !~ /Z/) line = $0 }
        END { print line }
    '
}

tmux list-windows -a -F $'#{session_name}\t#{window_index}\t#{window_name}\t#{window_layout}\t#{window_active}' \
    > "$SAVE_DIR/windows.tsv"

: > "$SAVE_DIR/panes.tsv"
while IFS=$'\t' read -r session win_idx pane_idx active path cmd tty; do
    full_cmd=$(foreground_cmdline "$tty")
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$session" "$win_idx" "$pane_idx" "$active" "$path" "${full_cmd:-$cmd}" \
        >> "$SAVE_DIR/panes.tsv"
done < <(tmux list-panes -a -F $'#{session_name}\t#{window_index}\t#{pane_index}\t#{pane_active}\t#{pane_current_path}\t#{pane_current_command}\t#{pane_tty}')

tmux display-message "tmux session saved ($(wc -l < "$SAVE_DIR/windows.tsv" | tr -d ' ') windows)"
