# shellcheck shell=bash

# Returns whether the given command is available
_has() {
  command -v "$1" >/dev/null 2>&1
}
