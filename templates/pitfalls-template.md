# Pitfalls Template

Living document. Known traps. Fed by failures. Budget: 300 tokens.

```yaml
# PITFALLS.md
# Last updated: {date}

pitfalls:
  - id: PF1
    name: {name}
    area: {e.g. auth, db, deploy}
    severity: critical|high|medium
    added: {date}
    source: {task-id or "research"}
    symptom: {how you know}
    cause: {why it happens}
    fix: {resolution}
    prevention: {avoidance}
    patterns: [P{n}]          # optional

by_area:
  auth: [PF1, PF3]
  database: [PF2]

# Clause IDs: PITFALLS.PF1, PF2, etc.
```

## Update Triggers
- Task failure with identified root cause
- Near-miss in review
- Research surfaces known issues
- Security/deprecation advisory
