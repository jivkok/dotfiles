Run the full agent pipeline autonomously: triage all inbox tasks, clarify all clarifying tasks, then implement all ready tasks. Do not stop to ask the user during any phase — use documented assumptions throughout.

## Phases

Execute each phase in sequence using the Task tool to spawn a sub-agent per phase, so each loads its role with a clean context.

**Phase 1 — Triage**
Run `/project:triage`. Process all files in `tasks/inbox/`.

**Phase 2 — Clarify**
Run `/project:clarify`. Process all files in `tasks/clarifying/` (including any moved there by Phase 1). Use documented assumptions — do not escalate to the user unless genuinely blocked with no reasonable assumption available.

**Phase 3 — Implement**
Run `/project:implement` repeatedly until `tasks/ready/` is empty. Each iteration claims and implements one task. On failure, record it and continue with the next task — do not abort the pipeline.

## Output

Print a final summary after all phases complete:

```
Pipeline complete.

Triage:    N tasks processed → N ready, N clarifying
Clarify:   N tasks processed → N ready, N blocked
Implement: N tasks processed → N done, N failed

Failed:
→ tasks/failed/<filename>.md — <one-line reason>

Blocked (clarify):
→ tasks/clarifying/<filename>.md — <what information is needed>

Ready but unimplemented: none | N tasks remaining
```

Omit sections that are empty (no failures, no blocked tasks).
