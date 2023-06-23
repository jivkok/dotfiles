function _prepend_to_path() {
  if [[ -d "$1" && ! :$PATH: =~ :$1: ]]; then
    PATH=$1:$PATH
  fi
}

function _prepend_to_manpath() {
  if [[ -d "$1" && ! :$MANPATH: =~ :$1: ]]; then
    MANPATH=$1:$MANPATH
  fi
}

_prepend_to_path /usr/bin
_prepend_to_path /usr/local/bin
_prepend_to_path /usr/local/sbin

if [[ "$OSTYPE" = darwin* ]]; then
  eval "$(/usr/libexec/path_helper -s)"
  eval "$(/opt/homebrew/bin/brew shellenv)"

  if [[ "$SHELL" == *zsh* ]]; then
    setopt null_glob
  else
    shopt -s nullglob
  fi

  for gnupath in /usr/local/Cellar/*/*/libexec/gnubin; do
    _prepend_to_path "$gnupath"
  done

  for gnupath in /usr/local/Cellar/*/*/libexec/gnuman; do
    _prepend_to_manpath "$gnupath"
  done
fi

_prepend_to_path "$HOME/.dotnet/tools"
_prepend_to_path "$HOME/.dotnet"
_prepend_to_path "$HOME/.cargo/bin"
_prepend_to_path /usr/local/go/bin
_prepend_to_path "$HOME/go/bin"
command -v python3 >/dev/null && _prepend_to_path "$(python3 -m site --user-base)/bin"
_prepend_to_path "$HOME/dotfiles/bin"
_prepend_to_path "$HOME/.local/bin"
_prepend_to_path "$HOME/bin"

export PATH=$PATH
export MANPATH=$MANPATH
