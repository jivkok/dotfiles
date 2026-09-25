# shellcheck shell=bash
# Coverage-map helpers shared by tests/run-tests.sh and the coverage/lint tests.
#
# Test file headers (within the first COV_HEADER_LINES lines):
#   # COVERS: <path-or-glob> ...   repo-relative paths/globs the test exercises
#   # COVERAGE: meta               the test's COVERS entries select it but do not
#                                  count as coverage (e.g. lint, coverage map)
#   # REQUIRES: <cmd> ...          commands the test needs (see run-tests.sh)
#
# Globs: `*` and `?` do not cross `/`; `**` matches any number of path segments
# (`**/` may match zero segments, so `**/*.sh` also matches `setup.sh`).
#
# tests/coverage-exclude: one `<path-or-glob>  # <reason>` per line; blank lines
# and lines starting with `#` are ignored.

COV_HEADER_LINES=15

# Compiled glob regexes, keyed by glob (filled lazily by cov_glob_to_regex).
declare -gA _COV_RE_CACHE=()

# cov_get_header <file> <NAME>  — value of the first `# NAME:` header, or empty.
cov_get_header() {
  local line n=0
  while ((n++ < COV_HEADER_LINES)) && IFS= read -r line; do
    if [[ "$line" == "# $2:"* ]]; then
      line="${line#"# $2:"}"
      read -r line <<< "$line"   # trim surrounding whitespace
      printf '%s' "$line"
      return 0
    fi
  done < "$1"
}

# cov_is_meta <test-file>  — true if the test's COVERS don't count as coverage.
cov_is_meta() {
  [[ "$(cov_get_header "$1" COVERAGE)" == "meta" ]]
}

# cov_glob_to_regex <glob>  — compile <glob> into COV_REGEX (an anchored ERE),
# caching the result so repeated matching never recompiles or forks.
cov_glob_to_regex() {
  local glob="$1" re="" c i n=${#1}
  if [[ -n "${_COV_RE_CACHE[$glob]+set}" ]]; then
    COV_REGEX="${_COV_RE_CACHE[$glob]}"
    return 0
  fi
  for ((i = 0; i < n; i++)); do
    c="${glob:i:1}"
    case "$c" in
      '*')
        if [[ "${glob:i+1:1}" == '*' ]]; then
          if [[ "${glob:i+2:1}" == '/' ]]; then
            re+='(.*/)?'
            i=$((i + 2))
          else
            re+='.*'
            i=$((i + 1))
          fi
        else
          re+='[^/]*'
        fi
        ;;
      '?') re+='[^/]' ;;
      [.+\(\)\|^\$\[\]\{\}\\]) re+="\\$c" ;;
      *) re+="$c" ;;
    esac
  done
  COV_REGEX="^${re}\$"
  _COV_RE_CACHE[$glob]="$COV_REGEX"
}

# cov_path_matches_any <path> <glob>...  — true if <path> matches any glob.
cov_path_matches_any() {
  local path="$1" glob
  shift
  for glob in "$@"; do
    cov_glob_to_regex "$glob"
    [[ "$path" =~ $COV_REGEX ]] && return 0
  done
  return 1
}

# cov_glob_matches_any <glob> <path>...  — true if <glob> matches any path.
cov_glob_matches_any() {
  local path
  cov_glob_to_regex "$1"
  shift
  for path in "$@"; do
    [[ "$path" =~ $COV_REGEX ]] && return 0
  done
  return 1
}

# cov_is_script <path>  — true for repo scripts that need test coverage.
# Files under tests/ are the test suite itself and are handled separately.
cov_is_script() {
  case "$1" in
    tests/*) return 1 ;;
    *.sh | *.zsh | bin/*) return 0 ;;
    *) return 1 ;;
  esac
}

# cov_exclude_lines <exclude-file>  — print `<glob>\t<reason>` per entry.
# An entry without a `# reason` is printed with an empty reason.
cov_exclude_lines() {
  local line glob reason
  [[ -f "$1" ]] || return 0
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
    read -r glob _ <<< "${line%%#*}"
    reason=""
    if [[ "$line" == *'#'* ]]; then
      read -r reason <<< "${line#*#}"
    fi
    printf '%s\t%s\n' "$glob" "$reason"
  done < "$1"
}

# cov_tracked_files <repo-root>  — tracked + untracked (non-ignored) files, sorted.
# safe.directory: the repo is bind-mounted into Docker test containers.
cov_tracked_files() {
  git -c safe.directory='*' -C "$1" ls-files --cached --others --exclude-standard | sort -u
}
