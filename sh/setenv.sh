# shellcheck shell=bash

source "$dotdir/sh/helpers.sh"
source "$dotdir/sh/path.sh"
source "$dotdir/sh/system.sh"
source "$dotdir/sh/sysinfo.sh"
source "$dotdir/sh/ls.sh"
source "$dotdir/sh/edits.sh"
source "$dotdir/sh/finds.sh"
source "$dotdir/sh/utils.sh"
source "$dotdir/sh/web.sh"
source "$dotdir/sh/marks.sh"
[ -f "$dotdir/git/git.sh" ] && source "$dotdir/git/git.sh"
[ -f "$dotdir/docker/docker.sh" ] && source "$dotdir/docker/docker.sh"
# shellcheck disable=SC2139  # $dotdir is a stable, exported env var; intentional expansion at definition time
[ -f "$dotdir/bin/worktrees.sh" ] && alias wt="$dotdir/bin/worktrees.sh"
if $_is_osx; then
  source "$dotdir/osx/setenv.sh"
fi
