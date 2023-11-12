# Returns whether the given command is executable/aliased
_has() {
  return $(command -v "$1" >/dev/null 2>&1)
}

# Compares files or directories
# Usage: jdiff file_or_dir_1 file_or_dir_2
jdiff() {
  if [ -z "$2" ]; then
    echo "Compares files or directories"
    echo "Usage: jdiff file_or_dir_1 file_or_dir_2"
    return 1
  fi
  if [ ! -e "$1" ]; then
    echo "$1: does not exist"
    return 1
  fi
  if [ ! -e "$2" ]; then
    echo "$2: does not exist"
    return 1
  fi

  if [ -d "$1" ]; then
    if [ -d "$2" ]; then
      _comp='-Naur' # N: treat missing file as file with zero size; a: treat all (even binaries) files as ASCII text; produce unified diff; r: recursive
    else
      echo "Cannot compare directory ( $1 ) with a file ( $2 )"
      return 1
    fi
  else
    if [ ! -d "$2" ]; then
      _comp='-au'
    else
      echo "Cannot compare file ( $1 ) with a directory ( $2 )"
      return 1
    fi
  fi

  if _has delta; then
    diff "$_comp" "$1" "$2" | delta
  elif _has diff-so-fancy; then
    diff "$_comp" "$1" "$2" | diff-so-fancy
  elif _has ydiff; then
    diff "$_comp" "$1" "$2" | ydiff
  elif _has git; then
    git diff --no-index "$1" "$2"
  else
    diff "$_comp" "$1" "$2"
  fi
}
