export PATH=$PATH
export PATH=/usr/bin:$PATH
export PATH=/usr/local/bin:$PATH
export PATH=/usr/local/sbin:$PATH
export PATH=$HOME/bin:$PATH

# Load the shell dotfiles
#   ~/.path can be used to extend `$PATH`
#   ~/.profile.local can be used for any local settings you don’t want to commit
for file in ~/{.bashrc,.exports,.path,.profile.local}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;
