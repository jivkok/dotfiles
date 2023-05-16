# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[ -e "$HOME/.ssh/config" ] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2- | tr ' ' '\n')" scp sftp ssh

OS="$(uname -s)"
if [ "$OS" = "Linux" ]; then
  if [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
  fi
elif [ "$OS" = "Darwin" ]; then
  if which brew >/dev/null && [ -f "$(brew --prefix)/etc/bash_completion" ]; then
    source "$(brew --prefix)/etc/bash_completion"
  elif [ -f /etc/bash_completion ]; then
    source /etc/bash_completion
  fi
fi
