# Dotfiles (macOS / Linux / Windows) — AI Agents Entry Point

## Purpose

This repository bootstraps my machines (macOS, Linux, Windows) by:
- installing core CLI/dev tools (Homebrew / apt / pacman / Chocolatey)
- configuring shell environments (bash/zsh), git, python tools, vim/neovim, tmux, fzf
- linking/sourcing dotfiles in a way that preserves local overrides

## AI Agent Workflow

Follow the process in `docs/development.md` — including the mandatory testing step after every code change.

## Docs for refactoring (read next)

- `docs/structure.md` — repo layout, flows, invariants
- `docs/os-matrix.md` — cross-platform differences and mappings
- `docs/development.md` — conventions, rules, refactoring playbook, and validation checklists
- `docs/testing.md` — testing approach, workflow, environments, and scripts reference
- `docs/coding-conventions.md` — coding conventions (detail files in `docs/coding-conventions/`)
- `docs/mcp-servers.md` — MCP servers configured for AI agents
