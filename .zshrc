# To profile the zsh startup: export _ZSH_DEBUG=profile
if [[ "$_ZSH_DEBUG" = profile ]]; then
    zmodload zsh/zprof
fi

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.

# ZSH_THEME="fletcherm"
# ZSH_THEME="gallifrey"
# ZSH_THEME="gallois"
# ZSH_THEME="intheloop"
# ZSH_THEME="jreese"
# ZSH_THEME="kennethreitz"
# ZSH_THEME="maran"
# ZSH_THEME="tjkirch"


# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
export UPDATE_ZSH_DAYS=30

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(colored-man colorize encode64 httpie jsontools nmap npm pip python rsync urltools zsh-completions zsh-syntax-highlighting)
if [[ "$OSTYPE" = darwin* ]]; then
    plugins=("${plugins[@]}" brew osx pod xcode)
fi

# User configuration

[ -f "$ZSH/oh-my-zsh.sh" ] && source "$ZSH/oh-my-zsh.sh"

# set options
#set -o vi               # vi keys
set -o noclobber        # prevent overwriting files with cat
setopt no_BEEP
setopt no_NOMATCH       # Do not display an error if there are no matches
setopt no_HUP           # Leave processes open when closing a shell with background processes

# Completion system

[ -d $HOME/.zsh/completion ] && fpath=($HOME/.zsh/completion $fpath)

autoload -Uz compinit
compinit

zstyle ":completion:*" auto-description "specify: %d"
zstyle ":completion:*" completer _expand _complete _correct _approximate
zstyle ":completion:*" format "Completing %d :"
zstyle ":completion:*" group-name ""
zstyle ":completion:*" list-colors ""
zstyle ":completion:*" list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
zstyle ":completion:*" matcher-list "" "m:{a-z}={A-Z}" "m:{a-zA-Z}={A-Za-z}" "r:|[._-]=* r:|=* l:|=*"
zstyle ":completion:*" menu select=2
zstyle ":completion:*" menu select=long
zstyle ":completion:*" select-prompt %SScrolling active: current selection at %p%s
zstyle ":completion:*" verbose true
zstyle ":completion:*:default" list-colors ${(s.:.)LS_COLORS}

zstyle ":completion:*:*:kill:*:processes" list-colors "=(#b) #([0-9]#)*=0=01;31"
zstyle ":completion:*:kill:*" command "ps -u $USER -o pid,%cpu,tty,cputime,cmd"

# key bindings
# Note: use 'cat' to easily see the escape sequences
#bindkey "^[[1;5D" backward-word # ctrl-left
#bindkey "^[[1;5C" forward-word # ctrl-right

# Load the shell dotfiles
#   ~/.profile_local.sh can be used for any local settings you don’t want to commit
for file in ~/{.path.sh,.zsh-theme.sh,.aliases.sh,.functions.sh,.fzf.zsh,.marks.sh,.exports.sh,.profile_local.sh}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

if [[ "$_ZSH_DEBUG" = profile ]]; then
    zprof
fi

