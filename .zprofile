export PATH=$PATH
export PATH=/usr/bin:$PATH
export PATH=/usr/local/bin:$PATH
export PATH=/usr/local/sbin:$PATH
export PATH=$HOME/bin:$PATH
[ -d /usr/local/opt/coreutils/libexec/gnubin ] && export PATH=/usr/local/opt/coreutils/libexec/gnubin:$PATH

[ -d /usr/local/opt/coreutils/libexec/gnuman ] && export MANPATH=/usr/local/opt/coreutils/libexec/gnuman:$MANPATH

# Load the shell dotfiles (~/.path can be used to extend `$PATH`)
for file in ~/{.exports,.path}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;
