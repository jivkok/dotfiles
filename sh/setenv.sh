_has() {
  return $(command -v "$1" >/dev/null 2>&1)
}

source "$dotdir/sh/path.sh"
source "$dotdir/sh/system.sh"
source "$dotdir/sh/ls.sh"
source "$dotdir/sh/edits.sh"
source "$dotdir/sh/finds.sh"
source "$dotdir/sh/utils.sh"
source "$dotdir/sh/web.sh"
source "$dotdir/sh/marks.sh"
source "$dotdir/git/git.sh"
_has docker && source "$dotdir/docker/docker.sh"
[ "$(uname -s)" = "Darwin" ] && source "$dotdir/osx/setenv.sh"
