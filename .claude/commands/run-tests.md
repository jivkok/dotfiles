Run the test suite across all environments (local + any Docker images registered in tests/.testenv):

```bash
bash tests/run-tests.sh
```

Optional flags:

- `--all` — run every test unconditionally; fail if a required tool is missing (full audit mode).
- `--filter <cmd>` — run only tests that declare `<cmd>` in their `# REQUIRES:` header (post-install verification).

