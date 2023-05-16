#set -o vi               # vi keys
set -o noclobber # prevent overwriting files with cat

shopt -s cdspell      # Autocorrect typos in path names when using `cd`
shopt -s checkwinsize # Make sure terminals wrap lines correctly after resizing them
shopt -s dotglob      # files beginning with . to be returned in the results of path-name expansion.
shopt -s histappend   # Append to history (http://www.tldp.org/HOWTO/Bash-Prompt-HOWTO/x329.html)
shopt -s nocaseglob   # Case-insensitive globbing (used in pathname expansion)
# Enable some Bash 4 features when possible
shopt -s autocd 2>/dev/null   # * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
shopt -s globstar 2>/dev/null # * Recursive globbing, e.g. `echo **/*.txt`

OS="$(uname -s)"
if [ "$OS" = "Linux" ]; then

  # Set up umask permissions (http://en.wikipedia.org/wiki/Umask)
  # umask 002 allows only you to write (but the group to read) any new files that you create.
  # umask 022 allows both you and the group to write to any new files which you make.
  # In general we want umask 022 on the server and umask 002 on local machines.
  # The command 'id' gives the info we need to distinguish these cases.
  #    $ id -gn  #gives group name
  #    $ id -un  #gives user name
  #    $ id -u   #gives user ID
  # So: if the group name is the same as the username OR the user id is not greater than 99
  # (i.e. not root or a privileged user), then we are on a local machine, so we set umask 002.
  if [ "$(id -gn)" == "$(id -un)" -a $(id -u) -gt 99 ]; then
    umask 002
  else
    umask 022
  fi

fi
