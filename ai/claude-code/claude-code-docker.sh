#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'
# Run the ai/claude-code Docker image against the current directory.
#
# More flexible than docker compose for this single-container use case:
#   - forwards ANTHROPIC_API_KEY to the container only if it's set on the
#     host (opt-in metered billing); otherwise Claude Code logs into your
#     Claude.ai subscription via its normal browser flow, same as natively
#   - mounts the current directory as /workspace
#   - accepts extra host directories to mount as CLI arguments
#   - reads a project-local config file (.aiproj / .aiproj.yaml / .aiproj.yml,
#     first one found) for a top-level "volumes:" list of additional mounts,
#     e.g.:
#       volumes:
#         - ~/repos:/repos
#
# Usage:
#   ai/claude-code/claude-code-docker.sh [host_path:container_path ...]
#
# Builds the image automatically the first time it's needed for the current
# ai/claude-code/BUILD number, tagged <claude_code_version>.<build_number>
# (e.g. 2.1.270.1) - the Claude Code version is resolved from
# downloads.claude.ai and pinned into the build so it's reproducible, rather
# than the image silently drifting to whatever Claude Code ships next.
# Bump BUILD and re-run after changing the Dockerfile/entrypoint to force a
# fresh build (which also picks up whatever Claude Code version is current
# at that time). Independently of BUILD, downloads.claude.ai is also
# re-checked at most once a day (stamped in a temp file) and the image is
# rebuilt if a newer Claude Code version is available - see below.
#
# Runs claude with --permission-mode auto (a classifier judges each action
# against Claude Code's built-in allow/soft_deny/hard_deny rules, rather than
# prompting for everything beyond file edits the way acceptEdits does) plus
# --add-dir for every mounted folder beyond /workspace, since Claude Code
# scopes file-tool access to declared directories independently of what the
# container itself can reach.
#
# Also, so each run isn't a fresh install:
#   - persists Claude Code's own state (onboarding/trust/theme/settings)
#     across --rm runs, in $XDG_STATE_HOME/ai-claude-code (or
#     ~/.local/state/ai-claude-code)
#   - passes TZ through from the host so container time matches local time

dotdir="$(cd "$(dirname "$0")/../.." && pwd)"
source "$dotdir/setup/setup_functions.sh"

IMAGE_DIR="$dotdir/ai/claude-code"
IMAGE_NAME="ai-claude-code"
BUILD_N="$(<"$IMAGE_DIR/BUILD")"
CONFIG_CANDIDATES=(".aiproj" ".aiproj.yaml" ".aiproj.yml")

# Reuse whatever image is already tagged for this BUILD number - picking the
# highest Claude Code version if more than one is somehow tagged for it -
# then decide whether it's still worth asking downloads.claude.ai for
# something newer. That check only actually runs (a) when no image exists
# yet for this BUILD number at all, or (b) at most once a day otherwise,
# tracked via a per-user stamp file in the temp dir (so a reboot, a cleared
# /tmp, or a new day all naturally trigger a re-check). This keeps every
# other run - already checked today - network-independent.
IMAGE_TAG="$(docker images "$IMAGE_NAME" --format '{{.Repository}}:{{.Tag}}' 2>/dev/null \
  | grep -E "^${IMAGE_NAME}:[0-9]+\.[0-9]+\.[0-9]+\.${BUILD_N}\$" \
  | sort -t: -k2 -V | tail -n1)"

VERSION_CHECK_STAMP="${TMPDIR:-/tmp}/ai-claude-code-version-check-$(id -u)"
_today="$(date +%Y-%m-%d)"
_last_checked="$(cat "$VERSION_CHECK_STAMP" 2>/dev/null || true)"

if [ -z "$IMAGE_TAG" ] || [ "$_last_checked" != "$_today" ]; then
  if [ -z "$IMAGE_TAG" ]; then
    log_info "No image found for build ${BUILD_N}; resolving current Claude Code version ..."
  else
    log_trace "Daily check: resolving current Claude Code version (last checked ${_last_checked:-never}) ..."
  fi

  claude_code_version="$(curl -fsSL https://downloads.claude.ai/claude-code-releases/latest)"
  if [[ "$claude_code_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    # Only stamp today's date on a successful check - a network hiccup
    # should retry next run, not silently wait out the rest of the day.
    echo "$_today" >"$VERSION_CHECK_STAMP"
    _resolved_tag="${IMAGE_NAME}:${claude_code_version}.${BUILD_N}"
    if [ "$_resolved_tag" != "$IMAGE_TAG" ]; then
      log_info "${IMAGE_TAG:+Newer Claude Code version found; }Building ${_resolved_tag} ..."
      docker build --build-arg CLAUDE_CODE_VERSION="$claude_code_version" \
        -t "$_resolved_tag" -t "${IMAGE_NAME}:latest" "$IMAGE_DIR"
      # Drop the now-superseded version tag for this BUILD number so images
      # don't quietly pile up on every upstream release; best-effort only,
      # e.g. a container still using it shouldn't block this run.
      [ -n "$IMAGE_TAG" ] && docker rmi "$IMAGE_TAG" >/dev/null 2>&1
      IMAGE_TAG="$_resolved_tag"
    fi
  elif [ -z "$IMAGE_TAG" ]; then
    log_error "claude-code-docker.sh: couldn't resolve the current Claude Code version (got \"${claude_code_version}\")."
    exit 1
  else
    log_warning "claude-code-docker.sh: couldn't check for a newer Claude Code version (got \"${claude_code_version}\"); using cached image ${IMAGE_TAG}."
  fi
fi

docker_args=(run --rm)

if [ -t 0 ] && [ -t 1 ]; then
  docker_args+=(-it)
else
  docker_args+=(-i)
fi

docker_args+=(
  -v "$(pwd):/workspace"
  -w /workspace
  # Run as the host's own uid:gid, not the image's baked-in claude user, so
  # writes to the host-owned state directories mounted below (persistence)
  # actually succeed instead of silently failing on a uid mismatch — see
  # the Dockerfile's matching comment for why that mismatch happens at all.
  --user "$(id -u):$(id -g)"
  # Without a correct TERM, Claude Code can misdetect terminal capabilities
  # (including which clipboard integration path to use).
  -e "TERM=${TERM:-xterm-256color}"
)

# Only forward ANTHROPIC_API_KEY if it's actually set in the host shell -
# it's deliberately not required. Setting it switches Claude Code to
# pay-per-token API billing (credits) instead of a logged-in Claude.ai
# subscription (Pro/Max/Team), which is almost certainly not what you want
# for everyday use. Leave it unset and Claude Code falls back to its normal
# browser-based account login on first run inside the container, same as a
# native install; that login persists into $STATE_DIR/claude/.credentials.json
# below (already covered by the ~/.claude bind mount, no extra mount needed)
# so you only log in once. Only export ANTHROPIC_API_KEY before running this
# script if you specifically want metered API billing for this session.
if [ -n "${ANTHROPIC_API_KEY:-}" ]; then
  docker_args+=(-e "ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}")
fi

# Claude Code's fullscreen TUI (enabled by default in this image) captures
# mouse events for its own use — including, when it detects $TMUX, writing
# a mouse selection straight to the tmux clipboard buffer ("Copied N chars
# to tmux buffer"), which this repo's own tmux config then mirrors out to
# the host clipboard via OSC 52. That only works if the container can reach
# the *same* tmux server: bridge its socket and $TMUX through when present.
# Without tmux to bridge through, mouse capture just hijacks the terminal's
# native click-and-drag selection with nowhere for it to go — disable mouse
# clicks instead so that native selection (and whatever clipboard handling
# your terminal does on its own) works, at the cost of click/drag/hover
# within Claude Code itself; scroll-wheel support is unaffected either way.
if [ -n "${TMUX:-}" ] && [ -S "${TMUX%%,*}" ]; then
  docker_args+=(-e "TMUX=${TMUX}" -v "${TMUX%%,*}:${TMUX%%,*}")
else
  docker_args+=(-e "CLAUDE_CODE_DISABLE_MOUSE_CLICKS=1")
fi

# Pass through the host's effective git identity (user.name / user.email,
# resolved the same way any git command run outside Docker would resolve
# them for this directory - i.e. respecting a repo-local override) as a
# minimal global .gitconfig inside the container, so Claude can create
# commits without extra setup. Written as a *global* config, not
# GIT_AUTHOR_NAME/EMAIL env vars, so precedence still matches normal git
# behavior: the mounted repo's own local config (e.g. a per-project identity
# override) continues to win over this default, whereas env vars would
# incorrectly override even that. Only user.name/email are propagated -
# deliberately not the rest of the host's ~/.gitconfig (credential helpers,
# GPG signing, core.editor, etc.), since those commonly point at host-only
# binaries/keys that don't exist in this ephemeral container and would
# break git operations rather than help them. Regenerated fresh on every
# run (not persisted in STATE_DIR below) so it always reflects the host's
# current config.
_git_user_name="$(git config user.name 2>/dev/null || true)"
_git_user_email="$(git config user.email 2>/dev/null || true)"
if [ -n "$_git_user_name" ] || [ -n "$_git_user_email" ]; then
  _gitconfig_tmp="$(mktemp)"
  trap '[ -n "${_gitconfig_tmp:-}" ] && rm -f "$_gitconfig_tmp"' EXIT
  {
    echo "[user]"
    [ -n "$_git_user_name" ] && printf '\tname = %s\n' "$_git_user_name"
    [ -n "$_git_user_email" ] && printf '\temail = %s\n' "$_git_user_email"
  } >"$_gitconfig_tmp"
  docker_args+=(-v "$_gitconfig_tmp:/home/claude/.gitconfig:ro")
else
  log_warning "claude-code-docker.sh: no git user.name/email configured on the host; commits made inside the container won't have an author identity unless set manually."
fi

# Match the container's clock to the host's (the image otherwise defaults to
# UTC). /etc/localtime is a symlink into the IANA zoneinfo tree on both
# Linux and macOS, so this works cross-platform without relying on
# Linux-only tools like /etc/timezone or timedatectl.
_host_tz="$(readlink /etc/localtime 2>/dev/null | sed -n 's#.*/zoneinfo/##p')"
if [ -n "$_host_tz" ]; then
  docker_args+=(-e "TZ=${_host_tz}")
fi

# Persist Claude Code's own state (onboarding/trust-dialog/theme, in
# ~/.claude.json; settings/plugins/custom-themes in ~/.claude/) across --rm
# runs. Kept separate from any host Claude Code install — its own state
# directory, not shared with $HOME/.claude(.json). /home/claude must match
# the image's CLAUDE_USER (Dockerfile ARG, default "claude").
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ai-claude-code"
mkdir -p "$STATE_DIR/claude"
# An empty file isn't valid JSON — claude.json must start as "{}", or
# Claude Code fails immediately with "JSON Parse error: Unexpected EOF".
[ -s "$STATE_DIR/claude.json" ] || echo '{}' >"$STATE_DIR/claude.json"
docker_args+=(
  -v "$STATE_DIR/claude.json:/home/claude/.claude.json"
  -v "$STATE_DIR/claude:/home/claude/.claude"
)

# CLAUDE_ADD_DIRS tracks the container-side path of every mount beyond
# /workspace, so Claude Code's own directory scoping (via --add-dir) matches
# exactly what's bind-mounted into the container.
CLAUDE_ADD_DIRS=()

_mount_extra_dir() {
  docker_args+=(-v "$1")
  local _rest="${1#*:}"
  CLAUDE_ADD_DIRS+=("${_rest%%:*}")
}

for extra_dir in "$@"; do
  extra_dir="${extra_dir/#\~/$HOME}"
  log_trace "Mounting extra directory (CLI): ${extra_dir}"
  _mount_extra_dir "$extra_dir"
done

_config_file=""
for candidate in "${CONFIG_CANDIDATES[@]}"; do
  if [ -f "$candidate" ]; then
    _config_file="$candidate"
    break
  fi
done

if [ -n "$_config_file" ]; then
  log_trace "Reading project config: ${_config_file}"

  if _has yq; then
    _volume_count="$(yq '.volumes | length' "$_config_file" 2>/dev/null || echo 0)"
    if [[ "$_volume_count" =~ ^[0-9]+$ ]] && [ "$_volume_count" -gt 0 ]; then
      for ((i = 0; i < _volume_count; i++)); do
        _vol="$(yq -r ".volumes[$i]" "$_config_file")"
        _vol="${_vol/#\~/$HOME}"
        log_trace "Mounting extra directory (config): ${_vol}"
        _mount_extra_dir "$_vol"
      done
    fi
  else
    # Minimal fallback parser for the simple "volumes:" list format shown
    # above, used when yq isn't installed.
    _in_volumes=false
    while IFS= read -r line; do
      if [[ "$line" =~ ^volumes: ]]; then
        _in_volumes=true
        continue
      fi
      if $_in_volumes; then
        if [[ "$line" =~ ^[[:space:]]+-[[:space:]]*(.+)$ ]]; then
          _vol="${BASH_REMATCH[1]}"
          _vol="${_vol/#\~/$HOME}"
          log_trace "Mounting extra directory (config): ${_vol}"
          _mount_extra_dir "$_vol"
        else
          _in_volumes=false
        fi
      fi
    done <"$_config_file"
  fi
fi

docker_args+=("$IMAGE_TAG" claude --permission-mode auto)
for add_dir in "${CLAUDE_ADD_DIRS[@]}"; do
  docker_args+=(--add-dir "$add_dir")
done

log_info "Launching ${IMAGE_TAG} ..."
docker "${docker_args[@]}"
