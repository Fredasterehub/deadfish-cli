# Track Log Template

Append-only decisions/learnings for one track.

```yaml
# Log: {Track ID} — {Track Name}
spec: spec.md
plan: plan.md

entries:
  - date: {date}
    title: {title}
    type: decision|learning|pivot|issue
    task: {task-id or general}
    context: {what was happening}
    detail: {what we decided/learned}
    why: {rationale}
    implications: {affects going forward}
    promote:                       # optional
      patterns: false
      pitfalls: false
      risks: false
      tech_stack: false

top_learnings:                     # filled on track completion
  - {key learning}

decisions:
  - what: {decision}
    date: {date}
    task: {task-id}
    why: {brief}
```

## Promotion Flow
Generalizable? → Pattern (needs 2nd use) | Pitfall (trap) | Risk (systemic) | Stay in log.
Max 5 top learnings. Summarize older entries if log exceeds 50.
