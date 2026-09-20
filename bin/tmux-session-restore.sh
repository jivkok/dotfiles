#!/usr/bin/env bash
# Reconstruct tmux sessions/windows/panes from the snapshot written by
# tmux-session-save.sh: window layout, pane cwd, and (best-effort) each
# pane's foreground command line are restored; pane scrollback and
# program-internal state (e.g. a vim buffer's contents) are not.
# Sessions that already exist under the same name are left untouched,
# unless the existing session is just tmux's untouched lone default
# window/pane (e.g. the "0" created when tmux itself just started) - that
# one is adopted and reused as the first restored window, since it would
# otherwise collide by name with a saved auto-numbered session.
#
# Usage: tmux-session-restore.sh   (bound to prefix + Ctrl-r)

set -euo pipefail

SAVE_DIR="${TMUX_SESSION_SAVE_DIR:-$HOME/.tmux/session-save}"
WINDOWS="$SAVE_DIR/windows.tsv"
PANES="$SAVE_DIR/panes.tsv"

if [[ ! -f "$WINDOWS" || ! -f "$PANES" ]]; then
    tmux display-message "No saved session found in $SAVE_DIR"
    exit 1
fi

is_shell() {
    case "${1%% *}" in
        bash|zsh|sh|fish|-bash|-zsh|-sh|-fish) return 0 ;;
        *) return 1 ;;
    esac
}

# True if $1 is an existing session with nothing in it worth keeping: a
# single window with a single pane sitting at an idle shell prompt.
session_is_lone_default() {
    local session="$1" pane_cmds
    (( $(tmux list-windows -t "=$session" | wc -l) == 1 )) || return 1
    pane_cmds=$(tmux list-panes -t "=$session" -F '#{pane_current_command}')
    (( $(wc -l <<< "$pane_cmds") == 1 )) || return 1
    is_shell "$pane_cmds"
}

created_sessions=""
skipped_sessions=""
restored=0

while IFS=$'\t' read -r session win_idx win_name layout active; do
    [[ " $skipped_sessions " == *" $session "* ]] && continue

    is_new_session=0
    adopt_session=0
    if [[ " $created_sessions " != *" $session "* ]]; then
        if tmux has-session -t "=$session" 2>/dev/null; then
            if session_is_lone_default "$session"; then
                adopt_session=1
            else
                skipped_sessions="$skipped_sessions $session"
                continue
            fi
        else
            is_new_session=1
        fi
        created_sessions="$created_sessions $session"
    fi

    win_panes=()
    while IFS= read -r line; do
        win_panes+=("$line")
    done < <(awk -F'\t' -v s="$session" -v w="$win_idx" '$1 == s && $2 == w' "$PANES" | sort -t$'\t' -k3n)
    (( ${#win_panes[@]} == 0 )) && continue

    first_path=$(cut -f5 <<< "${win_panes[0]}")
    target="$session:$win_name"

    if (( is_new_session )); then
        tmux new-session -d -s "$session" -n "$win_name" -c "$first_path"
    elif (( adopt_session )); then
        existing_win=$(tmux list-windows -t "=$session" -F '#{window_index}')
        tmux rename-window -t "$session:$existing_win" "$win_name"
        first_pane_idx=$(cut -f3 <<< "${win_panes[0]}")
        tmux send-keys -t "$target.$first_pane_idx" "cd $(printf '%q' "$first_path")" Enter
    else
        tmux new-window -t "$session:" -n "$win_name" -c "$first_path"
    fi

    for ((i = 1; i < ${#win_panes[@]}; i++)); do
        path=$(cut -f5 <<< "${win_panes[$i]}")
        tmux split-window -t "$target" -c "$path"
    done
    tmux select-layout -t "$target" "$layout" 2>/dev/null || true

    active_pane_idx=""
    for pane_line in "${win_panes[@]}"; do
        pane_idx=$(cut -f3 <<< "$pane_line")
        pane_active=$(cut -f4 <<< "$pane_line")
        cmd=$(cut -f6 <<< "$pane_line")
        is_shell "$cmd" || tmux send-keys -t "$target.$pane_idx" "$cmd" Enter
        [[ "$pane_active" == "1" ]] && active_pane_idx="$pane_idx"
    done
    [[ -n "$active_pane_idx" ]] && tmux select-pane -t "$target.$active_pane_idx"

    [[ "$active" == "1" ]] && tmux select-window -t "$target"
    restored=$((restored + 1))
done < "$WINDOWS"

if [[ -n "$skipped_sessions" ]]; then
    tmux display-message "tmux session restored ($restored windows; skipped existing:$skipped_sessions)"
else
    tmux display-message "tmux session restored ($restored windows)"
fi
