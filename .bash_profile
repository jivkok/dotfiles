export PATH=$PATH
export PATH=/usr/bin:$PATH
export PATH=/usr/local/bin:$PATH
export PATH=/usr/local/sbin:$PATH
export PATH=$HOME/bin:$PATH

# Load the shell dotfiles
#   ~/.path.sh can be used to extend `$PATH`
#   ~/.profile_local.sh can be used for any local settings you don’t want to commit
for file in ~/{.bashrc,.exports.sh,.path.sh,.profile_local.sh}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

if [[ "$OSTYPE" = darwin* ]]; then
    eval $(/usr/libexec/path_helper -s)
fi
