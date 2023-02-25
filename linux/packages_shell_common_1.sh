dotrepos="$HOME/.repos"
mkdir -p "$dotrepos"

# FZF
if [ -d $dotrepos/fzf/.git ]; then
  git -C "$dotrepos/fzf" pull --prune
else
  git clone --depth 1 https://github.com/junegunn/fzf "$dotrepos/fzf"
fi
"$dotrepos/fzf/install" --key-bindings --completion --no-update-rc
