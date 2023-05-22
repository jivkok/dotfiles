export EDITOR="vi"
export VISUAL='vi'
if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
  export VISUAL='nvim'
elif command -v vim >/dev/null 2>&1; then
  export EDITOR="vim"
  export VISUAL='vim'
fi
if [ "$(uname -s)" = "Darwin" ] && command -v code >/dev/null 2>&1; then
  export VISUAL='code'
  alias e='code'
fi

if command -v nvim >/dev/null 2>&1; then
  alias v='nvim'
elif command -v vim >/dev/null 2>&1; then
  alias v='vim'
else
  alias v='vi'
fi
alias vimupd='v +PlugUpdate +qall'

# open file/s in Emacs (in current session, if any) in new frame
function em() {
  if ! pgrep -f -u $USER "emacs --daemon" >/dev/null 2>&1; then
    emacs --daemon
  fi

  emacsclient -c "$@"
}

# open file/s in Emacs in existing frame/session
function ems() {
  if ! pgrep -f -u $USER "emacs --daemon" >/dev/null 2>&1; then
    emacs --daemon "$@"
    emacsclient "$@"
  else
    emacsclient -n "$@"
  fi
}

# close existing Emacs session
function emq() {
  if pgrep -f -u $USER "emacs --daemon" >/dev/null 2>&1; then
    emacsclient -e "(kill-emacs)" "$@"
  fi
}
