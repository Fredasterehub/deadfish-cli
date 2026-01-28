# Product Template

Living document. Updated as understanding evolves.

---

```markdown
# Product: {project-name}

*Last updated: {ISO date}*
*Updated by: {model/person}*
*Reason: {what changed}*

## Current Goals

### Primary Goal
{One sentence - what we're optimizing for right now}

### Secondary Goals
- {Goal 2}
- {Goal 3}

## Users

### Primary User
- **Who**: {description}
- **Context**: {when/where they use this}
- **Jobs to be done**: {what they're trying to accomplish}

### Secondary Users
- {User type 2}: {brief description}

## Key Metrics

| Metric | Current | Target | Status |
|--------|---------|--------|--------|
| {Metric 1} | {value} | {target} | 🟢/🟡/🔴 |
| {Metric 2} | {value} | {target} | 🟢/🟡/🔴 |

## UX Constraints

- {Constraint 1 - e.g., "Must work on mobile"}
- {Constraint 2 - e.g., "Max 3 clicks to core action"}

## Current Understanding

### What We Know
- {Validated assumption 1}
- {Validated assumption 2}

### What We're Testing
- {Hypothesis 1}

### What Changed Recently
- {Date}: {Change and why}

---
*Living document. Update after tracks complete when understanding improves.*
```

## Update Triggers

Update PRODUCT.md when:
- User research reveals new insights
- Metrics show unexpected behavior
- Goals shift based on learnings
- A track completion changes understanding

## Diff Format

When proposing updates, use:
```diff
- Old line
+ New line
```

Target section explicitly: "Update PRODUCT.md > Current Goals > Primary Goal"
