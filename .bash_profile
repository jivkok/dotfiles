for file in ~/{.bashrc}; do
    [ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

