set -o vi               # vi keys
set -o noclobber        # prevent overwriting files with cat
setopt no_BEEP
setopt no_NOMATCH       # Do not display an error if there are no matches
setopt no_HUP           # Leave processes open when closing a shell with background processes
