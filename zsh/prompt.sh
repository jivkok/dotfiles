if command -v starship >/dev/null 2>&1; then

  export STARSHIP_CONFIG="$dotdir/zsh/starship.toml"
  eval "$(starship init zsh)"

elif [ -d "$ZSH" ] && [ -n "$ZSH_CACHE_DIR" ] && [ -n "$ZSH_CUSTOM" ] && [ -n "$SHORT_HOST" ]; then # checks for .oh-my-zsh presense

  ZSH_THEME_GIT_PROMPT_PREFIX="%{$fg[blue]%}:"
  ZSH_THEME_GIT_PROMPT_SUFFIX="%{$reset_color%}"
  ZSH_THEME_GIT_PROMPT_DIRTY="%{$fg[yellow]%}±%{$reset_color%}"
  ZSH_THEME_GIT_PROMPT_CLEAN=""

  function prompt_char {
    if [ $UID -eq 0 ]; then echo "%{$fg[red]%}#%{$reset_color%}"; else echo $; fi
  }
  PROMPT='%(?, ,%{$fg[red]%}errcode: $?%{$reset_color%}
)
%{$fg[yellow]%}%n%{$reset_color%} @ %{$fg[yellow]%}%M%{$reset_color%} : %{$fg[green]%}%~%{$reset_color%}
%_$(prompt_char) '

  RPROMPT='$(git_prompt_info)'
  if [[ ! -z "$SSH_CLIENT" ]]; then
    RPROMPT="$RPROMPT ⇄" # ssh icon
  fi

else

  # ZSH prompt: https://zsh.sourceforge.io/Doc/Release/Prompt-Expansion.html

  PROMPT='%(?, ,%F{red}errcode: %?%f
)
%F{yellow}%B%n%b%f @ %F{yellow}%B%M%b%f : %F{green}%B%~%b%f
%(!.#.$) '

  # Autoload zsh add-zsh-hook and vcs_info functions (-U autoload w/o substition, -z use zsh style)
  autoload -Uz add-zsh-hook vcs_info
  # Enable substitution in the prompt.
  setopt prompt_subst
  # Run vcs_info just before a prompt is displayed (precmd)
  add-zsh-hook precmd vcs_info

  # Enable checking for (un)staged changes, enabling use of %u and %c
  zstyle ':vcs_info:*' check-for-changes true
  # Set custom strings for an unstaged vcs repo changes (*) and staged changes (+)
  zstyle ':vcs_info:*' unstagedstr '*'
  zstyle ':vcs_info:*' stagedstr '+'
  # Set the format of the Git information for vcs_info
  zstyle ':vcs_info:git:*' formats       '%F{blue}:%b%f%F{yellow}%u%c%f'
  zstyle ':vcs_info:git:*' actionformats '%F{blue}:%b%f%F{yellow}|%a%u%c%f'

  # add ${vcs_info_msg_0} to the prompt
  RPROMPT='${vcs_info_msg_0_}'
  if [[ -n "$SSH_CLIENT" ]]; then
    RPROMPT="$RPROMPT ⇄" # ssh icon
  fi

fi
