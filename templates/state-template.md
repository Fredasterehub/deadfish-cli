# State Template

Current position document. What's happening NOW.

---

```markdown
# State: {project-name}

*Last updated: {ISO timestamp}*

## Current Position

- **Active Track**: {track-id} - {track name}
- **Current Task**: {task-id} - {task name}
- **Status**: planned | executing | verifying | blocked

## Quick Stats

| Metric | Value |
|--------|-------|
| Tracks complete | {n}/{total} |
| Current track tasks | {n}/{total} |
| Blockers | {count} |

## Blockers

<!-- Empty if none -->
| Blocker | Since | Waiting On |
|---------|-------|------------|
| {description} | {date} | {what unblocks} |

## Recent Activity

| Date | What | Outcome |
|------|------|---------|
| {date} | {task/decision} | ✅/❌/⏸️ |

## Next Actions

1. {Immediate next step}
2. {Following step}

## Notes

{Any context needed for resuming work}

---
*Updated automatically by pipeline. Manual edits preserved in Notes section.*
```

## Update Triggers

STATE.md is updated:
- When starting a new task
- When task status changes
- When blockers arise or resolve
- At end of work session

## Relationship to Other Docs

| Doc | STATE.md reads | STATE.md writes |
|-----|----------------|-----------------|
| tracks.md | Active track | Track status |
| TASK.md | Current task | Task status |
| ROADMAP.md | — | — |

STATE.md is the "now" pointer. Everything else is "what" and "how".
