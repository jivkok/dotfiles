if [[ "$_ZSH_DEBUG" = profile ]]; then
  zmodload zsh/zprof
fi

optional() {
  file="$1"
  [ -r "$file" ] && [ -f "$file" ] && source "$file";
}

source "$dotdir/zsh/plugins.sh"
source "$dotdir/zsh/options.sh"
source "$dotdir/zsh/completion.sh"
source "$dotdir/zsh/prompt.sh"
source "$dotdir/sh/setenv.sh"
optional "$HOME/.fzf.zsh"
# optional "$HOME/bin/fzf-git.sh"

if command -V zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# key bindings
# Note: use 'cat' to easily see the escape sequences
#bindkey "^[[1;5D" backward-word # ctrl-left
#bindkey "^[[1;5C" forward-word # ctrl-right

if [[ "$_ZSH_DEBUG" = profile ]]; then
  zprof
fi
