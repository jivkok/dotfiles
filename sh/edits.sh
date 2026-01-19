export EDITOR="vi"
export VISUAL='vi'

if [ "$SSH_TTY" = "" ] && { command -v code >/dev/null 2>&1 || command -v codium >/dev/null 2>&1; }; then
  alias e='code'
  alias ee='codium'
  if command -v codium >/dev/null 2>&1; then # prefer VSCodium
    export EDITOR="codium"
    export VISUAL='codium'
  elif command -v code >/dev/null 2>&1; then
    export EDITOR="code"
    export VISUAL='code'
  fi
elif command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
  export VISUAL='nvim'
elif command -v vim >/dev/null 2>&1; then
  export EDITOR="vim"
  export VISUAL='vim'
fi

if command -v nvim >/dev/null 2>&1; then
  alias v='nvim'
elif command -v vim >/dev/null 2>&1; then
  alias v='vim'
else
  alias v='vi'
fi
alias vimupd='v +PlugUpdate +qall'

if [ "$(uname -s)" = "Linux" ] && command -v xsel >/dev/null 2>&1; then
  alias pbcopy='xsel --clipboard --input'
  alias pbpaste='xsel --clipboard --output'
fi

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
