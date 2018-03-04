# Make vim the default editor
export EDITOR="vi";
export VISUAL='vi';
if command -v nvim >/dev/null 2>&1; then
    export EDITOR="nvim";
    export VISUAL='nvim';
elif command -v gvim >/dev/null 2>&1; then
    export EDITOR="gvim";
    export VISUAL='gvim';
elif command -v vim >/dev/null 2>&1; then
    export EDITOR="vim";
    export VISUAL='vim';
fi

# Larger bash history (allow 32³ entries; default is 500)
export HISTSIZE=32768;
export HISTFILESIZE=$HISTSIZE;
export HISTCONTROL=ignoredups;
# Make some commands not show up in history
export HISTIGNORE="ls:ll:cd:cd -:pwd:exit:clear:date:* --help";

# Prefer US English and use UTF-8
export LANG="en_US.UTF-8";
export LC_ALL="en_US.UTF-8";

# Highlight section titles in manual pages
export LESS_TERMCAP_md="${yellow}";

# Enable colored `grep` output
if echo zzz | grep --color=auto zzz > /dev/null 2>&1; then
    export GREP_OPTIONS="--color=auto";
    export GREP_COLOR='1;31' # matches
fi
