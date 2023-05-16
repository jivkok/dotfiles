export zpluginsdir="$HOME/.zsh/plugins"

for dir in $(find "$zpluginsdir" -mindepth 1 -maxdepth 1 -type d); do
  name="$(basename "$dir")"
  file="$dir/$name.plugin.zsh"
  [ -r "$file" ] && [ -f "$file" ] && source "$file";
done
