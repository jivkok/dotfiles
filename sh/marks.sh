# shellcheck shell=bash
# Shell bookmarks

export MARKPATH=$HOME/.marks

function to {
  cd -P "$MARKPATH/$1" 2>/dev/null || echo "No such mark: $1"
}

function mark {
  mkdir -p "$MARKPATH"; ln -s "$(pwd)" "$MARKPATH/$1"
}

function unmark {
  rm -i "$MARKPATH/$1"
}

os=$(uname -s)
if [ "$os" = "Darwin" ]; then
  function marks {
    # shellcheck disable=SC2012  # ls used intentionally for symlink display format
    ls -l "$MARKPATH" | tail -n +2 | sed 's/  / /g' | cut -d' ' -f8- | awk -F ' -> ' '{printf "%-10s -> %s\n", $1, $2}'
  }
  function cdm {
    local dest_dir
    # shellcheck disable=SC2012  # ls used intentionally for symlink display format
    dest_dir=$(ls -l "$MARKPATH" | tail -n +2 | sed 's/  / /g' | cut -d' ' -f10- | fzf )
    if [[ $dest_dir != '' ]]; then
      cd "$dest_dir" || return
    fi
  }
else
  function marks {
    # shellcheck disable=SC2012  # ls used intentionally for symlink display format
    ls -l "$MARKPATH" | sed 's/  / /g' | cut -d' ' -f9- | sed 's/ -/\t-/g' && echo
  }
  function cdm {
    local dest_dir
    # shellcheck disable=SC2012  # ls used intentionally for symlink display format
    dest_dir=$(ls -l "$MARKPATH" | tail -n +2 | sed 's/  / /g' | cut -d' ' -f11- | fzf )
    if [[ $dest_dir != '' ]]; then
      cd "$dest_dir" || return
    fi
  }
fi

currentShell=$(ps -hp $$ | sed -n 2p | awk -F ' ' '{print $4}')
if [[ "$currentShell" == *bash ]]; then
  _completemarks() {
    local curw=${COMP_WORDS[COMP_CWORD]}
    local wordlist
    # shellcheck disable=SC2034,SC2012  # wordlist used in compgen below; ls for simple mark names
    wordlist=$(ls "$MARKPATH" | tr " " "\n")
    # shellcheck disable=SC2207,SC2016  # array from compgen; single-quoted pattern is intentional
    COMPREPLY=($(compgen -W '${wordlist[@]}' -- "$curw"))
    return 0
  }

  complete -F _completemarks to unmark
elif [[ "$currentShell" == *zsh ]]; then
  function _completemarks {
    # shellcheck disable=SC2034,SC2207,SC2012  # reply is the zsh completion return array; ls for mark names
    reply=($(ls "$MARKPATH"))
  }

  compctl -K _completemarks to
  compctl -K _completemarks unmark
fi
