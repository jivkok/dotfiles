ZSH_THEME_GIT_PROMPT_PREFIX=" %{$fg[blue]%}( "
ZSH_THEME_GIT_PROMPT_SUFFIX=" )%{$reset_color%}"
ZSH_THEME_GIT_PROMPT_DIRTY=" ⚡"
ZSH_THEME_GIT_PROMPT_CLEAN=""

function prompt_char {
    if [ $UID -eq 0 ]; then echo "%{$fg[red]%}#%{$reset_color%}"; else echo $; fi
}
PROMPT='%(?, ,%{$fg[red]%}errcode: $?%{$reset_color%}
)
%{$fg[yellow]%}%n%{$reset_color%} @ %{$fg[yellow]%}%M%{$reset_color%} : %{$fg[green]%}%~%{$reset_color%}
%_$(prompt_char) '

RPROMPT='$(git_prompt_info)'