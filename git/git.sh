alias g='git'
alias lg='lazygit'

# Pull all repos in the current (or specified) directory
function git_pull_all() {
  dir="${1:-.}"
  find "$dir" -mindepth 1 -maxdepth 2 -type d | while read -r repodir; do
    [ -d "$repodir/.git" ] && echo -e "\nRepo: $repodir" && git -C "$repodir" pull --prune --rebase
  done
}

function git_pull_submodules() {
  dir="${1:-.}"

  if [ ! -f "$dir/.gitmodules" ]; then
    echo "No submodules found."
    return
  fi

  sed -rn 's/\s+path\ =\ (.*)/\1/p' "$dir/.gitmodules" | while read -r repodir; do
    echo -e "\n\033[0;32mUpdating $repodir ...\033[0;39m\n"
    git -C "$repodir" checkout master
    git -C "$repodir" pull --prune --recurse-submodules
    git -C "$repodir" submodule update --init --recursive
  done
}

# Create a git.io short URL
function gitio() {
  if [ -z "${1}" ] || [ -z "${2}" ]; then
    echo "Usage: \`gitio slug url\`"
    return 1
  fi
  curl -i http://git.io/ -F "url=${2}" -F "code=${1}"
}

# Git FZF functions ###########################################################

# checkout git branch (including remote branches)
git-fzf-checkout-branch() {
  local branches branch
  branches=$(git branch --all | grep -v HEAD) &&
    branch=$(echo "$branches" | fzf-tmux -d $((2 + $(wc -l <<<"$branches"))) +m) &&
    git checkout "$(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")"
}

# checkout git tag
git-fzf-checkout-tag() {
  local branches branch
  tags=$(git tag) &&
    tag=$(echo "$tags" | fzf-tmux -d $((2 + $(wc -l <<<"$tags"))) +m) &&
    git checkout "$tag"
}

# checkout git branch/tag
git-fzf-checkout-branch-or-tag() {
  local tags branches target
  tags=$(
    git tag | awk '{print "\x1b[31;1mtag\x1b[m\t" $1}'
  ) || return
  branches=$(
    git branch --all | grep -v HEAD |
      sed "s/.* //" | sed "s#remotes/[^/]*/##" |
      sort -u | awk '{print "\x1b[34;1mbranch\x1b[m\t" $1}'
  ) || return
  target=$(
    (
      echo "$tags"
      echo "$branches"
    ) |
      fzf-tmux -l30 -- --no-hscroll --ansi +m -d "\t" -n 2
  ) || return
  git checkout "$(echo "$target" | awk '{print $2}')"
}

# checkout git commit
git-fzf-checkout-commit() {
  local commits commit
  commits=$(git log --pretty=oneline --abbrev-commit --reverse) &&
    commit=$(echo "$commits" | fzf --tac +s +m -e) &&
    git checkout "$(echo "$commit//" | sed "s/ .*//")"
}

# git commits browser
git-fzf-commits() {
  git log --graph --color=always \
    --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
    fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF"
}

# git commit sha browser
# example usage: git rebase -i $(git-fzf-sha)
git-fzf-sha() {
  local commits commit
  commits=$(git log --color=always --pretty=oneline --abbrev-commit --reverse) &&
    commit=$(echo "$commits" | fzf --tac +s +m -e --ansi --reverse) &&
    echo -n $(echo "$commit" | sed "s/ .*//")
}

# git stash manager
# enter key: shows stash contents
# ctrl-d: shows a diff of the stash against current HEAD
# ctrl-b: checks out the stash as a branch
git-fzf-stashes() {
  local out q k sha
  while out=$(
    git stash list --pretty="%C(yellow)%h %>(14)%Cgreen%cr %C(blue)%gs" |
      fzf --ansi --no-sort --query="$q" --print-query \
        --expect=ctrl-d,ctrl-b
  ); do
    mapfile -t out <<<"$out"
    q="${out[0]}"
    k="${out[1]}"
    sha="${out[-1]}"
    sha="${sha%% *}"
    [[ -z "$sha" ]] && continue
    if [[ "$k" == 'ctrl-d' ]]; then
      git diff "$sha"
    elif [[ "$k" == 'ctrl-b' ]]; then
      git stash branch "stash-$sha" "$sha"
      break
    else
      git stash show -p "$sha"
    fi
  done
}

# git modified files browser (with preview)
git-fzf-status() {
  preview="git diff --color=always -- {-1}"
  git status -sb | fzf -m --ansi --preview $preview
}

# git tags
git-fzf-tags() {
  git tag | fzf -m --ansi
}

gitf() {
  if [ "$1" = "co" ] || [ "$1" = "checkout" ]; then
    if [ "$2" = "br" ] || [ "$2" = "branch" ]; then
      git-fzf-checkout-branch
    elif [ "$2" = "tag" ]; then
      git-fzf-checkout-tag
    elif [ "$2" = "cm" ] || [ "$2" = "commit" ]; then
      git-fzf-checkout-commit
    else
      echo "Usage: gitf checkout branch/tag/commit"
    fi
  elif [ "$1" = "commits" ] || [ "$1" = "cm" ]; then
    git-fzf-commits
  elif [ "$1" = "sha" ]; then
    git-fzf-sha
  elif [ "$1" = "stashes" ]; then
    git-fzf-stashes
  elif [ "$1" = "status" ] || [ "$1" = "st" ]; then
    git-fzf-status
  elif [ "$1" = "tags" ]; then
    git-fzf-tags
  else
    echo "Usage: gitf checkout/commits/sha/stashes/status/tags"
  fi
}
