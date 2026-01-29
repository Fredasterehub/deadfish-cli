# Track Plan Template

Execution plan for one track. Updated as tasks complete.

```yaml
# Plan: {Track ID} — {Track Name}
status: planning|executing|complete
created: {date}
spec: spec.md

overview: {how we'll implement this}

tasks:
  phase_1: {name}
    - id: "01"
      name: {task}
      status: done|active|pending
      notes: {optional}
    - id: "02"
      name: {task}
      status: pending

  phase_2: {name}
    - id: "03"
      name: {task}
      status: pending

testing:
  unit: {approach}
  integration: {approach}
  manual: {what to check}

rollout:
  - {step 1}
  - {step 2}

checkpoints:
  - after: {task-id}
    verify: {what to check}

progress:
  started: {date}
  updated: {date}
  completed: {date or —}

# Frozen when track completes.
```

## Task Granularity
Good: 1 session, 1 logical unit, independently verifiable.
Split if: multiple concerns, multiple sessions, unrelated checks.
