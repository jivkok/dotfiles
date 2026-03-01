# MCP Servers

MCP servers are configured in `.mcp.json`:

| Server | Command | Purpose |
|--------|---------|---------|
| `docker` | `uvx mcp-server-docker` | Manage Docker containers and images — introspect test environments, read build/run logs, check which `dotfiles-test-<os>-<hash>` images exist. |
| `homebrew` | `brew mcp-server` | Look up Homebrew formula and cask names before writing them into `osx/configure_osx.sh` or package lists. Tools: `search`, `info`, `deps`, etc. |
| `arch-linux` | `uvx arch-ops-server` | Look up official Arch and AUR package names before writing them into `linux/*.txt`. Tools: `get_official_package_info`, `search_aur`. |

## Tools without MCP server

### ShellCheck (no MCP — use Bash directly)

No ShellCheck MCP server exists. Use the Bash tool with JSON output for structured results:
```bash
shellcheck -f json path/to/script.sh
```
This is already pre-approved in `.claude/settings.local.json`.

### apt / Debian package lookup

No suitable read-only apt MCP server exists. Use the Docker MCP to run a lookup inside the existing Debian test container:
```
list_containers  →  find dotfiles-test-debian-<hash>
exec / run: apt-cache show <package>
```
