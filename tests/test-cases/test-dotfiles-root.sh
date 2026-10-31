#!/usr/bin/env bash
# REQUIRES: zsh
# shellcheck disable=SC2016  # single quotes are deliberate: the profile text under test contains literal $VARS
# COVERS: bash/.bashrc zsh/.zshrc sh/path.sh setup/configure_shell_profiles.sh
# The DOTFILES variable: shell bootstraps resolve the repo location from it
# (default ~/dotfiles), and setup pins the location it ran from in ~/.bashrc and
# ~/.zshrc. Everything runs under an isolated HOME with the repo copied to a
# path containing a space.
set -euo pipefail

DOTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# shellcheck source=../testlib.sh
source "$(dirname "${BASH_SOURCE[0]}")/../testlib.sh"
# shellcheck source=../coverage-lib.sh
source "${DOTDIR}/tests/coverage-lib.sh"

tmpdir="$(mktemp -d)"
tmpdir="$(cd "$tmpdir" && pwd -P)"
trap 'rm -rf "$tmpdir"' EXIT

# A copy of the tracked repo at a non-default location.
copy="${tmpdir}/my dots"
mkdir -p "$copy"
(
  cd "$DOTDIR"
  cov_tracked_files . | while IFS= read -r f; do [[ -e "$f" ]] && printf '%s\0' "$f"; done \
    | tar --null -T - -cf -
) | tar -C "$copy" -xf -

# new_home <name>  — print a fresh, empty HOME
new_home() { mkdir -p "${tmpdir}/$1"; printf '%s' "${tmpdir}/$1"; }

# shell_env <home> <shell> [VAR=value...]  — start an interactive <shell> (rc files
# loaded, nothing inherited but HOME/PATH and the given variables) and print
# "DOT=<DOTFILES>", "DIR=<dotdir>", "EXP=<yes if dotdir is exported>" and "PATH=<PATH>" lines.
shell_env() {
  local home="$1" shell="$2"; shift 2
  env -i HOME="$home" PATH="$PATH" "$@" "$shell" -i -c \
    'printf "DOT=%s\nDIR=%s\nEXP=%s\nPATH=%s\n" "$DOTFILES" "${dotdir:-}" "$(env | grep -q "^dotdir=" && echo yes || echo no)" "$PATH"' 2>/dev/null </dev/null
}
field() { sed -n "s/^$1=//p" <<< "$2" | head -n1; }

# ── Default: bootstrap only, repo at ~/dotfiles ───────────────────────────────
log_trace "--- default location ---"
home="$(new_home default)"
ln -s "$copy" "${home}/dotfiles"
cp "${copy}/bash/.bashrc" "${home}/.bashrc"
cp "${copy}/zsh/.zshrc" "${home}/.zshrc"
for sh in bash zsh; do
  out="$(shell_env "$home" "$sh")"
  assert_eq "$sh: DOTFILES defaults to \$HOME/dotfiles" "${home}/dotfiles" "$(field DOT "$out")"
  assert_eq "$sh: dotdir follows DOTFILES" "${home}/dotfiles" "$(field DIR "$out")"
  assert_eq "$sh: dotdir is not exported" "no" "$(field EXP "$out")"
done

# ── Environment override ───────────────────────────────────────────────────────
log_trace "--- DOTFILES from the environment ---"
home="$(new_home override)"   # no ~/dotfiles at all
cp "${copy}/bash/.bashrc" "${home}/.bashrc"
cp "${copy}/zsh/.zshrc" "${home}/.zshrc"
for sh in bash zsh; do
  out="$(shell_env "$home" "$sh" "DOTFILES=${copy}")"
  assert_eq "$sh: DOTFILES from env" "$copy" "$(field DOT "$out")"
  assert_contains "$sh: env location's bin dir is on PATH" "${copy}/bin" "$(field PATH "$out")"
done

# ── Setup pins the location it ran from ───────────────────────────────────────
log_trace "--- setup from a non-default location ---"
home="$(new_home pinned)"
HOME="$home" bash "${copy}/setup/configure_shell_profiles.sh" >/dev/null
for f in .bashrc .zshrc; do
  assert_eq "$f: exactly one pinned DOTFILES line" "1" \
    "$(grep -c '^export DOTFILES="${DOTFILES:-/' "${home}/${f}")"
  assert_file_content "${home}/${f}" "export DOTFILES=\"\${DOTFILES:-${copy}}\""
done
for sh in bash zsh; do
  out="$(shell_env "$home" "$sh")"
  assert_eq "$sh: DOTFILES is the setup location" "$copy" "$(field DOT "$out")"
  assert_contains "$sh: setup location's bin dir is on PATH" "${copy}/bin" "$(field PATH "$out")"
done

log_trace "--- setup is idempotent ---"
before="$(cksum "${home}/.bashrc" "${home}/.zshrc")"
HOME="$home" bash "${copy}/setup/configure_shell_profiles.sh" >/dev/null
assert_eq "profiles unchanged by a second setup run" "$before" "$(cksum "${home}/.bashrc" "${home}/.zshrc")"

log_trace "--- exported DOTFILES wins over the pinned default ---"
resolved="$(env -i HOME="$home" PATH="$PATH" DOTFILES=/elsewhere bash -c \
  'eval "$(grep "^export DOTFILES=\|^dotdir=" "$HOME/.bashrc")"; printf "%s|%s" "$DOTFILES" "$dotdir"' 2>/dev/null)"
assert_eq "env value beats the pinned default" "/elsewhere|/elsewhere" "$resolved"

# ── Profiles written by an older version ──────────────────────────────────────
log_trace "--- legacy profile with hardcoded dotdir ---"
home="$(new_home legacy)"
for f in .bashrc .zshrc; do
  shell="${f#.}"; shell="${shell%rc}"
  printf '# shellcheck shell=bash\n\nexport dotdir="$HOME/dotfiles"\nsource "$dotdir/%s/setenv.sh"\n' "$shell" > "${home}/${f}"
done
HOME="$home" bash "${copy}/setup/configure_shell_profiles.sh" >/dev/null
for f in .bashrc .zshrc; do
  check_not "$f: legacy hardcoded dotdir line removed" grep -qxF 'export dotdir="$HOME/dotfiles"' "${home}/${f}"
  assert_eq "$f: one pinned DOTFILES line" "1" "$(grep -c '^export DOTFILES="${DOTFILES:-/' "${home}/${f}")"
done
out="$(shell_env "$home" bash)"
assert_eq "legacy bash profile resolves the setup location" "$copy" "$(field DOT "$out")"
for f in .bashrc .zshrc; do
  check_not "$f: no dotdir export left" grep -q '^export dotdir=' "${home}/${f}"
  assert_eq "$f: dotdir assigned once, from DOTFILES" "1" "$(grep -c '^dotdir="\$DOTFILES"$' "${home}/${f}")"
  assert_eq "$f: setenv sourced exactly once" "1" "$(grep -c 'setenv\.sh"' "${home}/${f}")"
  assert_eq "$f: DOTFILES pinned directly above the source line" "1" \
    "$(grep -A2 '^export DOTFILES="${DOTFILES:-/' "${home}/${f}" | grep -c '^source "\$dotdir/')"
done

log_trace "--- profile from the intermediate DOTFILES-only form ---"
home="$(new_home interim)"
for f in .bashrc .zshrc; do
  shell="${f#.}"; shell="${shell%rc}"
  printf '# shellcheck shell=bash\n\nexport dotdir="${DOTFILES:-$HOME/dotfiles}"\nexport DOTFILES="$dotdir"\nsource "$DOTFILES/%s/setenv.sh"\n' "$shell" > "${home}/${f}"
done
HOME="$home" bash "${copy}/setup/configure_shell_profiles.sh" >/dev/null
for f in .bashrc .zshrc; do
  assert_eq "$f: setenv sourced exactly once" "1" "$(grep -c 'setenv\.sh"' "${home}/${f}")"
  assert_eq "$f: sourced via \$dotdir" "1" "$(grep -c '^source "\$dotdir/' "${home}/${f}")"
  check_not "$f: no DOTFILES re-export left" grep -qxF 'export DOTFILES="$dotdir"' "${home}/${f}"
done

finish_test
