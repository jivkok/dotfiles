optional() {
  file="$1"
  [ -r "$file" ] && [ -f "$file" ] && source "$file";
}

source "$dotdir/bash/options.sh"
source "$dotdir/bash/completion.sh"
source "$dotdir/bash/prompt.sh"
source "$dotdir/sh/setenv.sh"
optional "$HOME/.fzf.bash"
# optional "$HOME/bin/fzf-git.sh"

# key bindings. Note: use 'cat' to easily see the escape sequences
# bind "^[[1;5D" backward-word # ctrl-left
# bind "^[[1;5C" forward-word # ctrl-right

if command -V zoxide >/dev/null 2>&1; then
  eval "$(zoxide init bash)"
fi
