# Task: Improve Test Output Readability

**Status**: done
**Priority**: medium
**Created**: 2026-03-09

## Description

Improve test output readability.
Currently the console outputs all tests-related output. Intent is to limit (by default) what gets shown during a test run with focus on summary activity and test results. Suggestion: have a LOG_LEVEL (Error, Info, Trace). Have summary data and use the Info level, test details use the Trace level, test failures use the Error level. Also, paint test successes with green foreground color, test failures with red foreground color.

## Log Level Model

Levels are an ordered enumeration: `error=0 < info=1 < trace=2`. Output at a given level is shown when its level ≤ the active log level.

| Output | Level |
|--------|-------|
| `FAIL` lines, failure summary | error (0) |
| Environment headers, test file names, `PASSED`/`FAILED` per file, pass/fail counts, final pass line | info (1) |
| Individual `OK` lines, Docker preamble, all subprocess detail | trace (2) |

Consequence: at `info`, both info-level and error-level output appear (FAIL lines are shown for failing tests). At `trace`, everything appears. At `error`, only FAIL lines and failure summary.

## Acceptance Criteria

- [x] `run-tests.sh` accepts a `--log-level <level>` flag (valid values: `error`, `info`, `trace`; case-insensitive); default is `info`.
- [x] Individual test-case scripts and helpers (`startup-checks.sh`, etc.) read a `LOG_LEVEL` env var (same values); default is `info`.
- [x] `run-tests.sh` exports `LOG_LEVEL` to all subprocesses (local and Docker) so individual scripts inherit the active level.
- [x] `--log-level` CLI flag takes precedence over a `LOG_LEVEL` env var when both are set.
- [x] Passing an invalid `--log-level` value prints a usage error to stderr and exits non-zero.
- [x] At `info` level, `run-tests.sh` prints: environment headers, test file names, per-test-file `PASSED`/`FAILED` result, `FAIL` lines for failing tests, pass/fail counts, and the final overall pass/fail line.
- [x] At `trace` level, all output is shown: everything at `info` plus individual `OK` lines, Docker preamble, and all subprocess detail.
- [x] At `error` level, only individual `FAIL` lines and the final failure summary are shown; all other output is suppressed.
- [x] Individual `OK` lines are hidden at `info` and `error` levels (trace-level output).
- [x] Docker preamble noise (`bash: no job control`, locale warnings) is suppressed at `info` and `error` levels.
- [x] `FAIL` lines are printed with a red ANSI foreground (`\033[31m`) when colors are enabled.
- [x] Pass summaries and `OK`-level lines are printed with a green ANSI foreground (`\033[32m`) when colors are enabled.
- [x] Colors are disabled automatically when stdout is not a TTY.
- [x] Colors are disabled when the `NO_COLOR` env var is set (any non-empty value).
- [x] All shared test infrastructure (colors, level constants, `_should_log`, `ok`, `fail`, counters) is centralised in `tests/testlib.sh`; all other scripts source it instead of duplicating the logic.

## Out of Scope

- Changes to what tests verify or assert — output format only.
- Persistent log file output; console only.
- Log levels beyond `error`, `info`, and `trace`.
- Windows / PowerShell test scripts.
- Colorising output from within Docker containers (color applies to the host-side runner output only).

## Edge Cases / Test Scenarios

- `--log-level` with an unrecognised value (`--log-level verbose`) → exits non-zero with a clear error message.
- `LOG_LEVEL` env var set to a valid level and no CLI flag → env var is respected.
- Both `LOG_LEVEL=trace` env var and `--log-level error` flag set → CLI flag wins, output matches `error` level.
- Running in a CI environment (non-TTY stdout) → colors are automatically disabled without any explicit flag.
- `NO_COLOR=1` set in a TTY environment → colors are disabled despite TTY detection.
- A test file that passes at `error` level → produces no output (entirely silent for that file).
- Docker test run at `info` level → Docker preamble lines do not appear in output.

## Assumptions

- CLI flag name is `--log-level` (hyphenated, not `--log_level` or `-l`).
- Env var name is `LOG_LEVEL` (uppercase, underscore).
- Level values are matched case-insensitively (`INFO`, `info`, and `Info` all accepted).
- Per-test-file pass/fail at `info` level is determined from the subprocess exit code, not by parsing output.
- `run-tests.sh` propagates the resolved level by setting and exporting `LOG_LEVEL` before invoking test scripts and Docker containers.
- Color support is detected via `[ -t 1 ]` (stdout is a TTY); `NO_COLOR` check takes priority over TTY detection.

## Implementation Notes

- All shared test infrastructure centralised in `tests/testlib.sh` (root of tests, not helpers/): color setup (`FAIL_COLOR`, `SUCCESS_COLOR`, `RESET`), level constants (`LOG_LEVEL_ERROR/INFO/TRACE`), `_resolve_log_level`, `_ACTIVE_LOG_LEVEL`, `_should_log`, named logging functions (`log_error`/`log_info`/`log_trace`), `ok`/`fail` functions, and `_TEST_PASS`/`_TEST_FAIL` counters. Placed at `tests/` root because it serves the whole suite (runner + test scripts + helpers), not just one subdirectory. Old `log.sh` and `helpers/testlib.sh` stubs emit a fatal error to catch stale references.
- The full log-level model (ordered enumeration, output visible at each level) is documented inside `testlib.sh` next to the constants. `run-tests.sh` references `testlib.sh` for this rather than duplicating it.
- `log.sh` uses `tr` (not `${var,,}`) for lowercasing so it is portable to zsh — `startup-checks.sh` is run via `zsh -l` and sources `log.sh` in a zsh context.
- `startup-checks.sh` uses `${BASH_SOURCE[0]:-$0}` for its source path to work correctly in both bash and zsh.
- Log levels are an ordered enumeration (error=0, info=1, trace=2); a message is shown when its level ≤ the active level. FAIL lines are error-level and therefore appear at `info` as well.
- At `info`/`error` levels, `run-tests.sh` captures subprocess output with `2>&1` and filters it; at `trace` level output flows through directly (preserving TTY for subprocess color detection).
- Docker preamble suppression at `info`/`error` is a natural consequence of full output capture.
- All `[[ ... ]] && echo` guard patterns replaced with `if/fi` to avoid spurious non-zero returns triggering `set -e`.
- Docker tests receive `LOG_LEVEL` via `-e LOG_LEVEL` on the `docker run` command.
- Runner counts test files (not individual assertions); individual assertion counts visible only at `trace`.
- At `error` level with all passing: zero output, exit 0 (silent success for CI).
