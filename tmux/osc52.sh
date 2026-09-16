#!/usr/bin/env bash
# Wraps the OSC 52 sequence in a "DCS tmux;...ST" passthrough envelope,
# relayed via `allow-passthrough on` - this is the mechanism actually meant
# for an external script to ask tmux to forward raw bytes to the real
# terminal untouched. A bare (unwrapped) OSC 52 relies on `set-clipboard on`
# instead, which may just update tmux's own internal buffer without
# forwarding to the terminal at all - so the wrap is the more reliable
# choice here, not a redundant one.
buf=$(cat)
encoded=$(printf "%s" "$buf" | base64 | tr -d '\n')
pane_tty=$(tmux display-message -p '#{pane_tty}')
printf "\033Ptmux;\033\033]52;c;%s\007\033\\" "$encoded" > "$pane_tty"
