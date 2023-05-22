if [[ "$_ZSH_DEBUG" = profile ]]; then
  zmodload zsh/zprof
fi

optional() {
  file="$1"
  [ -r "$file" ] && [ -f "$file" ] && source "$file";
}

source "$dotdir/sh/setenv.sh"
source "$dotdir/zsh/options.sh"
source "$dotdir/zsh/plugins.sh"
source "$dotdir/zsh/prompt.sh"
source "$dotdir/zsh/completion.sh"
optional "$HOME/.fzf.zsh"
# optional "$HOME/bin/fzf-git.sh"

if command -V zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

# key bindings
# Note: use `cat`` / `ctrl-v` to easily see the escape sequences
# Note: in iTerm2, update "Option" key settings: Preferences -> Profiles -> Keys: for both Left and Right Option Key: choose option "Esc+" instead of "Normal".
bindkey "^[^[[D" backward-word # alt-left
bindkey "^[^[[C" forward-word # alt-right
bindkey '\e^?' backward-kill-word # alt-backspace

if [[ "$_ZSH_DEBUG" = profile ]]; then
  zprof
fi
