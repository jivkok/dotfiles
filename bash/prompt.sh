if command -v starship >/dev/null 2>&1; then

  export STARSHIP_CONFIG="$dotdir/bash/starship.toml"
  eval "$(starship init bash)"

else

  if [ -f "$HOME/bin/git-prompt.sh" ]; then
    source "$HOME/bin/git-prompt.sh"
    GIT_PS1_SHOWDIRTYSTATE=1
    GIT_PS1_SHOWUNTRACKEDFILES=1
    GIT_PS1_SHOWUPSTREAM="auto"
  else
    function __git_ps1 {
      return
    }
  fi

  if [ -n $(which tput) ] && [ "Msys" != $(uname -o) ]; then
    # Solarized colors, taken from http://git.io/solarized-colors.
    tput sgr0 # reset colors
    BOLD=$(tput bold)
    COLOR_RESET=$(tput sgr0)
    BLACK=$(tput setaf 0)
    RED=$(tput setaf 124)
    RED_BOLD="$BOLD$RED"
    GREEN=$(tput setaf 64)
    GREEN_BOLD="$BOLD$GREEN"
    YELLOW=$(tput setaf 136)
    YELLOW_BOLD="$BOLD$YELLOW"
    BLUE=$(tput setaf 33)
    BLUE_BOLD="$BOLD$BLUE"
    PURPLE=$(tput setaf 125)
    PURPLE_BOLD="$BOLD$PURPLE"
    CYAN=$(tput setaf 37)
    CYAN_BOLD="$BOLD$CYAN"
    WHITE=$(tput setaf 15)
    WHITE_BOLD="$BOLD$WHITE"
    ORANGE=$(tput setaf 166)
    ORANGE_BOLD="$BOLD$ORANGE"
    VIOLET=$(tput setaf 61)
    VIOLET_BOLD="$BOLD$VIOLET"
  else
    COLOR_RESET='\[\e[0m\]'
    NO_COLOUR="\[\033[0m\]"
    BLACK="\[\033[0;30m\]"
    RED="\[\033[0;31m\]"
    RED_BOLD="\[\033[01;31m\]"
    GREEN="\[\033[0;32m\]"
    GREEN_BOLD="\[\033[01;32m\]"
    YELLOW="\[\033[0;33m\]"
    YELLOW_BOLD="\[\033[01;33m\]"
    BLUE="\[\033[0;34m\]"
    BLUE_BOLD="\[\033[01;34m\]"
    PURPLE='\[\e[0;35m\]'
    PURPLE_BOLD='\[\e[01;35m\]'
    CYAN='\[\e[0;36m\]'
    CYAN_BOLD='\[\e[01;36m\]'
    WHITE='\[\e[0;37m\]'
    WHITE_BOLD='\[\e[01;37m\]'
  fi

  function precmd {
    local separator=' : '
    local user=''
    if [ -n "$LOGNAME" ]; then
      user="$LOGNAME"
    elif [ -n "$USER" ]; then
      user="$USER"
    elif [ -n "$USERNAME" ]; then
      user="$USERNAME"
    fi

    local sshflag=''
    if [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
      sshflag=' ⇄'
    fi

    local location="$(dirs -0)"

    local prefix="\n${YELLOW_BOLD}${user}${COLOR_RESET} @ ${YELLOW_BOLD}${HOSTNAME}${COLOR_RESET}${separator}${GREEN_BOLD}${location}${COLOR_RESET}${BLUE_BOLD}$(__git_ps1 " (%s)")${COLOR_RESET}${sshflag}${COLOR_RESET}"

    local title="${user}${separator}${location}$(__git_ps1 " (%s)")"
    echo -ne "\033]0;${title}\007"
    export PS1="${prefix}\n\$ "
  }

  export PROMPT_COMMAND=precmd

fi
