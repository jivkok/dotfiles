# Returns whether the given command is executable/aliased
_has() {
  return $(command -v "$1" >/dev/null 2>&1)
}

# fzf + rg/ag
if _has fzf; then
  if _has fd; then
    export FZF_DEFAULT_COMMAND="fd --type f --type l --follow --hidden --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    _fzf_compgen_path() {
      fd --follow --hidden --exclude ".git" . "$1"
    }
    _fzf_compgen_dir() {
      fd --type d --follow --hidden --exclude ".git" . "$1"
    }
  elif _has rg; then
    export FZF_DEFAULT_COMMAND="rg --smart-case --files --no-ignore --hidden --follow --glob '!.git'"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    _fzf_compgen_path() {
      rg --smart-case --files --no-ignore --hidden --follow --glob '!.git' . "$1"
    }
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

# bat colorizer
if _has batcat; then # bat is batcat in Debian (when using apt)
  alias cat="batcat"
elif _has bat; then
  alias cat="bat"
fi
if _has bat || _has batcat; then
  export BAT_PAGER="less -R"
  export BAT_STYLE="changes,numbers"
  export BAT_THEME="ansi"
fi

# Enable colored `grep` output
if echo zzz | grep --color=auto zzz >/dev/null 2>&1; then
  export GREP_COLORS='mt1;31' # matches
fi

# File system

# Pass selected files as arguments to the given command
# Usage: f echo
# Usage: f vim
f() {
  IFS=$'\n'
  files=($(fd . --type f --type l --follow --hidden --exclude .git "${@:2}" | fzf -0 -1 -m))
  IFS=$' '
  [[ -n "$files" ]] && $1 "${files[@]}"
}

# Pass selected directories as arguments to the given command
# Usage: d ws
d() {
  IFS=$'\n'
  dirs=($(fd . --type d --hidden --exclude .git "${@:2}" | fzf -0 -1 -m))
  IFS=$' '
  [[ -n "$dirs" ]] && $1 "${dirs[@]}"
}

ff() {
  if [ -z "$1" ]; then
    echo "Find Files (or directories)"
    echo "Usage: ff file_pattern [directory]"
    return
  fi

  file_pattern="$1"
  directory="$2"
  if [ -z "$directory" ]; then
    directory='.'
  fi

  if command -V fd >/dev/null 2>&1; then
    fd --hidden --follow --exclude .git "$file_pattern" "$directory"
  else
    find "$directory" -iname "$file_pattern"
  fi
}

fs() {
  if [ -z "$1" ]; then
    echo "Find Strings in files"
    echo "Usage: fs string_pattern [file_pattern] [directory]"
    return
  fi

  string_pattern="$1"
  file_pattern="$2"
  directory="$3"
  if [ -z "$file_pattern" ]; then
    file_pattern='*'
  fi
  if [ -z "$directory" ]; then
    directory='.'
  fi

  if command -V rg >/dev/null 2>&1; then
    rg --color=always --line-number --no-heading --smart-case --no-ignore --hidden --follow --glob '!{.git,node_modules}/*' --glob "$file_pattern" "$string_pattern" "$directory"
  else
    # find "$directory" -type f -iname "$file_pattern" -exec grep -I -l -i "$string_pattern" {} \; -exec grep -I -n -i "$string_pattern" {} \;
    grep -Hrn "$string_pattern" "$directory" --include "$file_pattern"
  fi
}

# 1. Search for text in files using Ripgrep
# 2. Interactively narrow down the list using fzf
# 3. Open the file in Vim
fsf() {
  if [ "$EDITOR" = *vim* ]; then
    cmd="$EDITOR {1} +{2}"
  elif [ "$EDITOR" = code ]; then
    cmd="$EDITOR -g {1}:{2}"
  else
    cmd="$EDITOR {1}"
  fi

  rg --no-ignore --hidden --color=always --line-number --no-heading --smart-case "${*:-}" |
    fzf --ansi \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --delimiter : \
        --preview 'bat --color=always {1} --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
        --bind "enter:become($cmd)"
#        --bind 'enter:become(vim {1} +{2})'
}

# find and list processes matching a case-insensitive partial-match string
fp() {
  ps Ao pid,comm | awk '{match($0,/[^\/]+$/); print substr($0,RSTART,RLENGTH)": "$1}' | grep -i "$1" | grep -v grep
}
