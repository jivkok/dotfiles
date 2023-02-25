# Returns whether the given command is executable/aliased
_has() {
  return $(command -v "$1" >/dev/null 2>&1)
}

# Make vim the default editor
export EDITOR="vi"
export VISUAL='vi'
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
  export VISUAL='nvim'
elif command -v gvim >/dev/null 2>&1; then
  export EDITOR="gvim"
  export VISUAL='gvim'
elif command -v vim >/dev/null 2>&1; then
  export EDITOR="vim"
  export VISUAL='vim'
fi

# Larger bash history (allow 32³ entries; default is 500)
export HISTSIZE=32768
export HISTFILESIZE=$HISTSIZE
export HISTCONTROL=ignoreboth
# Make some commands not show up in history
export HISTIGNORE="..:...:....:* --help:cd:cd -:clear:date:exit:ll:ls:pwd:reload:rr:v:x"

# Prefer US English and use UTF-8
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Highlight section titles in manual pages
export LESS_TERMCAP_md="${yellow}"

# Enable colored `grep` output
if echo zzz | grep --color=auto zzz >/dev/null 2>&1; then
  export GREP_COLORS='mt1;31' # matches
fi

# fzf + rg/ag
if _has fzf; then
  if _has rg; then
    export FZF_DEFAULT_COMMAND="rg --smart-case --files --no-ignore --hidden --follow --glob '!{.git,node_modules}/*'"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  elif _has ag; then
    export FZF_DEFAULT_COMMAND='ag --nocolor -g ""'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    #    export FZF_ALT_C_COMMAND="$FZF_DEFAULT_COMMAND"
    #    export FZF_DEFAULT_OPTS='
    # --color fg:242,bg:236,hl:65,fg+:15,bg+:239,hl+:108
    # --color info:108,prompt:109,spinner:108,pointer:168,marker:168
    #'
  fi
fi

# .Net
[ -d "$HOME/.dotnet" ] && export DOTNET_ROOT="$HOME/.dotnet"
