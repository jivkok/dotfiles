# shellcheck shell=bash

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
      rg --ignore-case --files --no-ignore --hidden --follow --glob '!.git' . "$1"
    }
  elif _has ag; then
    export FZF_DEFAULT_COMMAND='ag --nocolor -g ""'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  fi
fi

# bat colorizer
if _has bat || _has batcat; then # bat is batcat in Debian (when using apt)
  export BAT_PAGER="less -R"
  export BAT_STYLE="changes,numbers"
  export BAT_THEME="Visual Studio Dark+"
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
  if [ -z "$1" ]; then
    echo "Pass selected files as arguments to the given command"
    echo "Usage: f <command> [pattern]"
    return
  fi
  IFS=$'\n'
  local files
  if _has fd; then
    # shellcheck disable=SC2207  # IFS-split fzf output into array; mapfile not available in zsh
    files=($(fd --type f --type l --follow --hidden --exclude .git "$2" . | fzf -0 -1 -m))
  else
    # shellcheck disable=SC2207  # IFS-split fzf output into array; mapfile not available in zsh
    files=($(find . -type f -not -path '*/.git/*' | fzf -0 -1 -m))
  fi
  IFS=$' '
  [[ ${#files[@]} -gt 0 ]] && "$1" "${files[@]}"
}

# Pass selected directories as arguments to the given command
# Usage: d ws
d() {
  if [ -z "$1" ]; then
    echo "Pass selected directories as arguments to the given command"
    echo "Usage: d <command> [fd-options]"
    return
  fi
  IFS=$'\n'
  local dirs
  # shellcheck disable=SC2207  # IFS-split fzf output into array; mapfile not available in zsh
  dirs=($(fd . --type d --hidden --exclude .git "${@:2}" | fzf -0 -1 -m))
  IFS=$' '
  [[ ${#dirs[@]} -gt 0 ]] && "$1" "${dirs[@]}"
}

# Find files by name pattern; uses fd if available, otherwise find
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

  if _has fd; then
    fd --hidden --follow --exclude .git "$file_pattern" "$directory"
  else
    find "$directory" -iname "$file_pattern"
  fi
}

# Find files containing a string pattern
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

  if _has rg; then
    rg --color=always --line-number --no-heading --smart-case --no-ignore --hidden --follow --glob '!{.git,node_modules}/*' --glob "$file_pattern" "$string_pattern" "$directory"
  else
    # find "$directory" -type f -iname "$file_pattern" -exec grep -I -l -i "$string_pattern" {} \; -exec grep -I -n -i "$string_pattern" {} \;
    grep -Hrn "$string_pattern" "$directory" --include "$file_pattern"
  fi
}

# Search for text in files with rg, narrow with fzf, open result in $EDITOR
fsf() {
  if ! _has rg || ! _has fzf; then
    echo "fsf requires rg (ripgrep) and fzf to be installed"
    return 1
  fi

  local editor="${EDITOR:-vi}"
  local cmd="$editor {1}"
  if [[ "$editor" == *vim* ]]; then
    cmd="$editor {1} +{2}"
  elif [[ "$editor" == *code* ]]; then
    cmd="$editor -g {1}:{2}"
  fi

  rg --no-ignore --hidden --color=always --line-number --no-heading --ignore-case "${*:-}" |
    fzf --ansi \
        --color "hl:-1:underline,hl+:-1:underline:reverse" \
        --delimiter : \
        --preview 'bat --color=always {1} --highlight-line {2}' \
        --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' \
        --bind "enter:become($cmd)"
}

# Find and list processes matching a case-insensitive partial-match string
fp() {
  ps Ao pid,comm | awk '{match($0,/[^\/]+$/); print substr($0,RSTART,RLENGTH)": "$1}' | grep -i "$1" | grep -v grep
}

# Find processes by substring and interactively select via fzf; prints selected PIDs
fpf() {
  if ! _has fzf; then
    echo "fpf requires fzf to be installed"
    return 1
  fi

  local query="${*:-}"
  ps Ao pid,comm | awk 'NR>1 {match($0,/[^\/]+$/); print substr($0,RSTART,RLENGTH)": "$1}' | \
    grep -v grep | \
    fzf -m --query="$query" --prompt='Process> ' --print0 | \
    tr '\0' '\n' | \
    awk -F': ' '{print $2}'
}

# Use fzf to pick a bat theme while previewing it on a file
bat_theme_picker() {
  if ! _has bat || ! _has fzf; then
    echo "bat_theme_picker requires bat and fzf to be installed"
    return 1
  fi

  local file="${1:-$HOME/.bashrc}"

  local theme
  theme="$(
    bat --list-themes | \
      fzf \
        --prompt='Bat theme> ' \
        --height=60% \
        --border \
        --preview="bat --theme={} --color=always \"$file\"" \
        --preview-window=right:80%
  )" || return 1

  export BAT_THEME="$theme"
}
