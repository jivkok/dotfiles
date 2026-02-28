# Bash Coding Conventions

## 1. Scope

Bash is approved for:

* Automation
* DevOps workflows
* CI/CD glue
* System orchestration
* Small utilities (<300–500 LOC)

Do not build application logic in Bash. Escalate to Python/Go when complexity increases.

---

## 2. Mandatory Script Header

All scripts must start with:

```bash
#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'
```

No exceptions without documented justification.

---

## 3. File Structure

Order must be:

1. Shebang + safety flags
2. `source` / imports
3. `readonly` constants
4. Global config (minimal)
5. Functions
6. `main()`
7. `main "$@"`

No executable logic at top level.

---

## 4. Naming Conventions

| Type            | Convention                   |
| --------------- | ---------------------------- |
| Constants       | `readonly ALL_CAPS`          |
| Exported vars   | `ALL_CAPS`                   |
| Local variables | `lowercase_with_underscores` |
| Functions       | `lowercase_with_underscores` |

No camelCase.
Avoid implicit globals.
Use `local` inside all functions.

---

## 5. Quoting & Expansion (Non-Negotiable)

* Always quote variables: `"$var"`
* Use `$(command)` not backticks
* Prefer `[[ ... ]]` over `[ ... ]`
* Use `(( ))` for arithmetic
* Use arrays instead of space-delimited strings

Unquoted variables are considered defects.

---

## 6. Error Handling

* Do not rely solely on `set -e`
* Explicitly check expected failures
* Use `trap` for cleanup

---

## 7. Argument Parsing

* Use `getopts` for simple flags
* If CLI becomes complex, switch languages

---

## 8. External Dependencies

* Validate required commands at startup
* Do not parse `ls`
* Use `shellcheck` in CI (mandatory)

Build fails on ShellCheck errors.

---

## 9. Formatting

Use `shfmt` to auto-format all scripts: `shfmt -w path/to/script.sh`

`shfmt` reads `.editorconfig` automatically (v3+). Do **not** pass `-i` or `-ln` flags that conflict with `.editorconfig`; let the file be the single source of truth for formatting style.

CI should run `shfmt -d` (diff mode) and fail on any unformatted files.

---

## 10. Prohibited Patterns

* Unquoted variables
* Backticks
* Implicit globals
* Parsing command output without error handling
* Scripts exceeding ~500 LOC without review

---
