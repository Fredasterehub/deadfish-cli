# Roadmap Template

Thin document. Themes + next tracks only. Budget: 500 tokens.

```yaml
# ROADMAP.md
# Last updated: {date}

theme: {current focus — one sentence}

active:
  - id: {track-id}
    name: {name}
    status: active|planned|paused
    target: {date or TBD}

next:                              # 2-4 tracks
  - id: {track-id}
    name: {name}
    why_now: {sequencing rationale}
    depends: [{prerequisites}]
    unknowns: [{what to learn first}]

future_themes:
  - {theme}: {brief description}

sequencing: {why ordered this way}

unknowns:
  - what: {unknown}
    blocks: [{track-ids}]
    resolution: {how we'll learn}

# Detail lives in tracks/<id>/spec.md + plan.md. This doc stays thin (~50 lines).
```
