# Roadmap Template

Thin document. Themes and next tracks only. NOT detailed phases.

---

```markdown
# Roadmap: {project-name}

*Last updated: {ISO date}*

## Current Theme

**{Theme Name}**: {One sentence description of current focus}

## Active Tracks

| ID | Track | Status | Target |
|----|-------|--------|--------|
| {id} | {name} | 🟢 Active / 🟡 Planned / ⏸️ Paused | {date or "TBD"} |

## Next Up (2-4 tracks)

### {Track ID}: {Track Name}
**Why now**: {Sequencing rationale}
**Depends on**: {Prerequisites}
**Unknowns**: {What must be learned first}

### {Track ID}: {Track Name}
**Why now**: {Sequencing rationale}
**Depends on**: {Prerequisites}
**Unknowns**: {What must be learned first}

## Future Themes (not yet planned)

- **{Theme 1}**: {Brief description}
- **{Theme 2}**: {Brief description}

## Sequencing Rationale

{Why tracks are ordered this way. Dependencies, learning priorities, etc.}

## Key Unknowns

| Unknown | Blocking | Resolution Plan |
|---------|----------|-----------------|
| {unknown 1} | {which tracks} | {how we'll learn} |

---
*Detailed planning lives in tracks/<id>/spec.md and plan.md*
*This doc is intentionally thin*
```

## What Goes Here vs Tracks

| ROADMAP.md | tracks/<id>/* |
|------------|---------------|
| Themes | Full specification |
| Track list + status | Detailed plan |
| Sequencing rationale | Task breakdown |
| Key unknowns | Acceptance criteria |
| ~50 lines | As detailed as needed |

## Update Cadence

- After each track completes: update status, add learnings to rationale
- When priorities shift: reorder "Next Up"
- When new theme emerges: add to "Future Themes"
