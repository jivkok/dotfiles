# PATH
export PATH=$PATH
export PATH=/usr/bin:$PATH
export PATH=/usr/local/bin:$PATH
export PATH=/usr/local/sbin:$PATH
[ -d /usr/local/opt/coreutils/libexec/gnubin ] && export PATH=/usr/local/opt/coreutils/libexec/gnubin:$PATH
export PATH=$HOME/bin:$PATH
export PATH=$HOME/.local/bin:$PATH

# MANPATH
[ -d /usr/local/opt/coreutils/libexec/gnuman ] && export MANPATH=/usr/local/opt/coreutils/libexec/gnuman:$MANPATH

# Load the shell dotfiles (~/.path.sh can be used to extend `$PATH`)
for file in ~/{.exports.sh,.path.sh}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;
