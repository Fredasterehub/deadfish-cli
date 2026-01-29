# Naming Conventions

```yaml
tracks: "T{nn}-{slug}"            # T01-auth-system (lowercase, hyphens, ≤30 chars)
tasks: "{track-id}.{nn}"          # T01-auth-system.01
pivots: "{YYYY-MM-DD}-{slug}"     # 2026-01-28-switch-to-postgres
clauses: "{DOC}.{X}{n}"           # VISION.V1, WORKFLOW.W3, PATTERNS.P2, SPEC.S1
branches: "{type}/{track-id}"     # feat/T01-auth-system
dates:
  filenames: YYYY-MM-DD
  timestamps: ISO-8601            # 2026-01-28T04:15:00Z
  display: "Mon DD, YYYY"         # Jan 28, 2026
```
