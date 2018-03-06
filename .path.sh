function _prepend_to_path() {
    if [[ -d "$1" && ! :$PATH: =~ :$1: ]]; then
        PATH=$1:$PATH;
    fi
}

function _prepend_to_manpath() {
    if [[ -d "$1" && ! :$MANPATH: =~ :$1: ]]; then
        MANPATH=$1:$MANPATH;
    fi
}

_prepend_to_path /usr/bin
_prepend_to_path /usr/local/bin
_prepend_to_path /usr/local/sbin
_prepend_to_path /usr/local/opt/coreutils/libexec/gnubin
_prepend_to_path "$HOME/dotfiles/bin"
_prepend_to_path "$HOME/bin"
_prepend_to_path "$HOME/.local/bin"
export PATH=$PATH

_prepend_to_manpath /usr/local/opt/coreutils/libexec/gnuman
export MANPATH=$MANPATH

if [[ "$OSTYPE" = darwin* ]]; then
    eval "$(/usr/libexec/path_helper -s)"
fi

