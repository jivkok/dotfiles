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
# export UPDATE_ZSH_DAYS=13

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
if [[ "$OSTYPE" = darwin* ]]; then
    plugins=(colored-man colorize rsync zsh-syntax-highlighting brew osx xcode)
else
    plugins=(colored-man colorize rsync zsh-syntax-highlighting)
fi

# User configuration

source $ZSH/oh-my-zsh.sh

## set options
set -o vi               # vi keys
set -o noclobber        # prevent overwriting files with cat

# Load the shell dotfiles, (~/.bash_extra can be used for any local settings you don’t want to commit)
for file in ~/.{zsh-theme,aliases,functions,bash_extra}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;
