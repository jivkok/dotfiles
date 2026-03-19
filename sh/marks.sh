# shellcheck shell=bash
# Shell bookmarks

export MARKPATH=$HOME/.marks

# Change to a bookmarked directory
function to {
  cd -P "$MARKPATH/$1" 2>/dev/null || echo "No such mark: $1"
}

# Create a bookmark for the current directory
function mark {
  if [[ -z "$1" ]]; then
    echo "Usage: mark <name>"
    return 1
  fi
  if [[ -e "$MARKPATH/$1" ]]; then
    echo "Mark '$1' already exists: $(readlink "$MARKPATH/$1")"
    return 1
  fi
  mkdir -p "$MARKPATH"
  ln -s "$(pwd)" "$MARKPATH/$1"
}

# Remove a bookmark
function unmark {
  rm -i "$MARKPATH/$1"
}

# List all bookmarks with their target paths
function marks {
  local mark target
  for mark in "$MARKPATH"/*; do
    [[ -L "$mark" ]] || continue
    target=$(readlink "$mark")
    printf "%-10s -> %s\n" "$(basename "$mark")" "$target"
  done
}

# Interactively select and change to a bookmarked directory
function cdm {
  local dest_dir
  # Output "path\tname" lines; fzf displays only the name (--with-nth=2),
  # then cut extracts the path — avoids any parsing of mark name or path content.
  dest_dir=$(for mark in "$MARKPATH"/*; do
    [[ -L "$mark" ]] || continue
    printf '%s\t%s\n' "$(readlink "$mark")" "$(basename "$mark")"
  done | fzf --delimiter=$'\t' --with-nth=2 | cut -f1)
  if [[ -n "$dest_dir" ]]; then
    cd "$dest_dir" || return
  fi
}

if [[ -n "$BASH_VERSION" ]]; then
  _completemarks() {
    local curw=${COMP_WORDS[COMP_CWORD]}
    local marks=()
    local mark
    for mark in "$MARKPATH"/*; do
      [[ -L "$mark" ]] && marks+=("$(basename "$mark")")
    done
    # shellcheck disable=SC2207  # array from compgen; no mapfile in older bash
    COMPREPLY=($(compgen -W "${marks[*]}" -- "$curw"))
    return 0
  }

  complete -F _completemarks to unmark
elif [[ -n "$ZSH_VERSION" ]]; then
  function _completemarks {
    local marks=()
    local mark
    for mark in "$MARKPATH"/*; do
      [[ -L "$mark" ]] && marks+=("$(basename "$mark")")
    done
    # shellcheck disable=SC2034  # reply is the zsh completion return array
    reply=("${marks[@]}")
  }

  compctl -K _completemarks to
  compctl -K _completemarks unmark
fi
