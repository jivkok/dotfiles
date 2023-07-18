[ -z "$HISTFILE" ] && HISTFILE="$HOME/.zsh_history"
[ "$HISTSIZE" -lt 50000 ] && HISTSIZE=50000
[ "$SAVEHIST" -lt 20000 ] && SAVEHIST=20000


setopt APPEND_HISTORY         # multiple zsh sessions will append their history list to the history file, rather than replace it.
setopt EXTENDED_HISTORY       # record timestamp and duration of command in HISTFILE
setopt HIST_EXPIRE_DUPS_FIRST # delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt HIST_FCNTL_LOCK        # use better history file locking
setopt HIST_IGNORE_DUPS       # do not enter command lines into the history list if they are duplicates of the previous event.
setopt HIST_IGNORE_SPACE      # do not add command lines to history list when the first character on the line is a space
setopt HIST_VERIFY            # do not run a command picked from history, just show it in the terminal line instead.
setopt INC_APPEND_HISTORY     # immediately append to the history file, not just when a term is closed.
setopt SHARE_HISTORY          # share command history data.
