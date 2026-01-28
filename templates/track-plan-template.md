# Track Plan Template

Execution plan for ONE track. Updated as tasks complete.

---

```markdown
# Plan: {Track ID} - {Track Name}

*Status*: planning | executing | complete
*Created*: {date}
*Spec*: [spec.md](spec.md)

## Overview

{How we'll implement this track}

## Tasks

### Phase 1: {Phase Name}

| # | Task | Status | Notes |
|---|------|--------|-------|
| 01 | {task name} | ✅ Done / 🔄 Active / ⬜ Pending | {notes} |
| 02 | {task name} | ⬜ Pending | |

### Phase 2: {Phase Name}

| # | Task | Status | Notes |
|---|------|--------|-------|
| 03 | {task name} | ⬜ Pending | |
| 04 | {task name} | ⬜ Pending | |

## Test Strategy

{How we'll verify this track works}

- Unit tests: {approach}
- Integration tests: {approach}
- Manual verification: {what to check}

## Rollout Plan

{How we'll deploy/release this}

1. {Step 1}
2. {Step 2}

## Checkpoints

| After Task | Verify |
|------------|--------|
| {task-id} | {what to check manually} |

## Progress

- Started: {date}
- Last update: {date}
- Completed: {date or "—"}

---
*Updated as tasks complete. Frozen when track completes.*
```

## Task Granularity

Good tasks:
- Completable in 1 session
- One logical unit of work
- Independently verifiable

Split if:
- Task spans multiple files/concerns
- Verification requires multiple unrelated checks
- Would take multiple sessions

## Status Flow

```
⬜ Pending → 🔄 Active → ✅ Done
                    ↓
                  ❌ Failed → 🔄 Retry
```

## Checkpoint Purpose

Checkpoints are manual verification points between phases. Use for:
- Demo to stakeholder
- Integration testing
- Performance validation
