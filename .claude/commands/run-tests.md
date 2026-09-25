Run the test suite across all environments (local + any Docker images registered in tests/.testenv).

Arguments: $ARGUMENTS

- **Default (no arguments):** run only the tests relevant to the current changes:

  ```bash
  bash tests/run-tests.sh --changed
  ```

- **Full suite:** if the arguments include `--all` or `--full`, run everything instead:
  - `--full` → `bash tests/run-tests.sh` (default mode: tests with missing optional tools are skipped)
  - `--all` → `bash tests/run-tests.sh --all` (every test unconditionally; fails if a required tool is missing)

Other flags are passed through:

- `--filter <cmd>` — run only tests that declare `<cmd>` in their `# REQUIRES:` header (post-install verification).
- `--changed <ref>` — compare against `<ref>...HEAD` plus the working tree (e.g. `--changed master` for a branch).
- `--list` — print the selected tests without running them.

Selection rules are documented in `docs/testing.md` — Coverage map and change-based selection.
