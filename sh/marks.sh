#!/usr/bin/env bash
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
    ls -l "$MARKPATH" | tail -n +2 | sed 's/  / /g' | cut -d' ' -f8- | awk -F ' -> ' '{printf "%-10s -> %s\n", $1, $2}'
  }
  function cdm {
    local dest_dir=$(ls -l "$MARKPATH" | tail -n +2 | sed 's/  / /g' | cut -d' ' -f10- | fzf )
    if [[ $dest_dir != '' ]]; then
      cd "$dest_dir"
    fi
  }
else
  function marks {
    ls -l "$MARKPATH" | sed 's/  / /g' | cut -d' ' -f9- | sed 's/ -/\t-/g' && echo
  }
  function cdm {
    local dest_dir=$(ls -l "$MARKPATH" | tail -n +2 | sed 's/  / /g' | cut -d' ' -f11- | fzf )
    if [[ $dest_dir != '' ]]; then
      cd "$dest_dir"
    fi
  }
fi

currentShell=$(ps -hp $$ | sed -n 2p | awk -F ' ' '{print $4}')
if [[ "$currentShell" == *bash ]]; then
  _completemarks() {
    local curw=${COMP_WORDS[COMP_CWORD]}
    local wordlist=$(ls $MARKPATH | tr " " "\n")
    COMPREPLY=($(compgen -W '${wordlist[@]}' -- "$curw"))
    return 0
  }

  complete -F _completemarks to unmark
elif [[ "$currentShell" == *zsh ]]; then
  function _completemarks {
    reply=($(ls $MARKPATH))
  }

  compctl -K _completemarks to
  compctl -K _completemarks unmark
fi
