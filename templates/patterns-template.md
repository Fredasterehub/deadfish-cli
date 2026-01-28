# Patterns Template

Living document. Blessed patterns for this project.

---

```markdown
# Patterns: {project-name}

*Last updated: {ISO date}*

## Pattern Tiers

| Tier | Meaning | Checker Behavior |
|------|---------|------------------|
| 🧪 Experimental | Used once, not yet blessed | Inform, don't enforce |
| ✅ Blessed | Used 2+ times successfully | Enforce compliance |
| 🌅 Sunset | Deprecated, has replacement | Warn, suggest alternative |

---

## P1: {Pattern Name}

**Tier**: ✅ Blessed
**Added**: {date}
**Uses**: {count}

### Description
{What this pattern is}

### When to Use
{Trigger conditions}

### Implementation
```{language}
{Code example}
```

### Why
{Rationale - why this over alternatives}

### Revisit When
{Conditions that would trigger reconsideration}

---

## P2: {Pattern Name}

**Tier**: 🧪 Experimental
**Added**: {date}
**Uses**: 1
**Track**: {track where first used}

### Description
{What this pattern is}

### Notes
{Observations from first use}

---

## Sunset Patterns

### PS1: {Deprecated Pattern}

**Sunset**: {date}
**Replaced by**: P{n}
**Reason**: {why deprecated}

---
*Clause IDs: P1, P2, etc. Reference as PATTERNS.P1, PATTERNS.P2, etc.*
*Experimental patterns use PE prefix until blessed.*
```

## Promotion Rules

### Experimental → Blessed
- Used successfully in 2+ different tasks
- No issues reported
- Checker validates uses

### Blessed → Sunset
- Better alternative discovered
- Causes consistent friction
- External best practices changed

## Checker Behavior

| Tier | Violation Response |
|------|-------------------|
| Experimental | Note in review, don't block |
| Blessed | REJECT if violated without justification |
| Sunset | WARN, suggest replacement, don't block |
