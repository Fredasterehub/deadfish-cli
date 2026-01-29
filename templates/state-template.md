# State Template

Current position. Budget: 200 tokens.

```yaml
# STATE.md
# Last updated: {timestamp}

position:
  track: {track-id} — {name}
  task: {task-id} — {name}
  status: planned|executing|verifying|blocked

stats:
  tracks: {done}/{total}
  tasks: {done}/{total}
  blockers: {count}

blockers:                          # omit if none
  - what: {description}
    since: {date}
    waiting: {unblocks}

recent:
  - date: {date}
    what: {task/decision}
    result: pass|fail|paused

next:
  - {immediate step}
  - {following step}

notes: |
  {context for resuming}

# Auto-updated by pipeline. Manual edits in notes only.
```
