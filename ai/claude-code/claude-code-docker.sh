#!/usr/bin/env bash
set -uo pipefail
IFS=$'\n\t'
# Run the ai/claude-code Docker image against the current directory.
#
# More flexible than docker compose for this single-container use case:
#   - passes ANTHROPIC_API_KEY through to the container
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
# at that time).
#
# Runs claude with --permission-mode acceptEdits (auto-approves file
# edits/writes and basic filesystem commands; Bash beyond that, WebFetch,
# etc. still prompt normally) plus --add-dir for every mounted folder beyond
# /workspace, since Claude Code scopes file-tool access to declared
# directories independently of what the container itself can reach.
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

if [ -z "${ANTHROPIC_API_KEY:-}" ]; then
  log_error "claude-code-docker.sh: ANTHROPIC_API_KEY is not set in the environment."
  exit 1
fi

# Reuse whatever image is already tagged for this BUILD number, whatever
# Claude Code version it happens to be pinned to - a rebuild is only needed
# when BUILD changes (this image's own recipe changed) or nothing has been
# built yet, not merely because upstream Claude Code shipped a new version
# since. This also keeps a normal (cache-hit) run network-independent: the
# Claude Code version is only resolved from downloads.claude.ai when an
# actual build is about to happen.
IMAGE_TAG="$(docker images "$IMAGE_NAME" --format '{{.Repository}}:{{.Tag}}' 2>/dev/null \
  | grep -E "^${IMAGE_NAME}:[0-9]+\.[0-9]+\.[0-9]+\.${BUILD_N}\$" \
  | head -n1)"

if [ -z "$IMAGE_TAG" ]; then
  log_info "No image found for build ${BUILD_N}; resolving current Claude Code version ..."
  claude_code_version="$(curl -fsSL https://downloads.claude.ai/claude-code-releases/latest)"
  if [[ ! "$claude_code_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    log_error "claude-code-docker.sh: couldn't resolve the current Claude Code version (got \"${claude_code_version}\")."
    exit 1
  fi
  IMAGE_TAG="${IMAGE_NAME}:${claude_code_version}.${BUILD_N}"
  log_info "Image ${IMAGE_TAG} not found locally; building ..."
  docker build --build-arg CLAUDE_CODE_VERSION="$claude_code_version" \
    -t "$IMAGE_TAG" -t "${IMAGE_NAME}:latest" "$IMAGE_DIR"
fi

docker_args=(run --rm)

if [ -t 0 ] && [ -t 1 ]; then
  docker_args+=(-it)
else
  docker_args+=(-i)
fi

docker_args+=(
  -e "ANTHROPIC_API_KEY=${ANTHROPIC_API_KEY}"
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

docker_args+=("$IMAGE_TAG" claude --permission-mode acceptEdits)
for add_dir in "${CLAUDE_ADD_DIRS[@]}"; do
  docker_args+=(--add-dir "$add_dir")
done

log_info "Launching ${IMAGE_TAG} ..."
docker "${docker_args[@]}"
