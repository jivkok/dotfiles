#!/usr/bin/env bash
buf=$(cat)
encoded=$(printf "%s" "$buf" | base64 | tr -d '\n')
pane_tty=$(tmux display-message -p '#{pane_tty}')
printf "\033Ptmux;\033\033]52;c;%s\007\033\\" "$encoded" > "$pane_tty"
