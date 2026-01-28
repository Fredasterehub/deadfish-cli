# Track Spec Template

Specification for ONE track. Frozen when track completes.

---

```markdown
# Spec: {Track ID} - {Track Name}

*Status*: draft | approved | in-progress | complete | superseded
*Created*: {date}
*Approved*: {date}

## Summary

{One paragraph: what this track delivers and why}

## User Story

As a {user type}
I want to {action}
So that {benefit}

## Acceptance Criteria

### S1: {Criterion Name}
{Specific, testable criterion}

### S2: {Criterion Name}
{Specific, testable criterion}

### S3: {Criterion Name}
{Specific, testable criterion}

## Non-Goals

- {What this track explicitly does NOT include}
- {Prevents scope creep}

## Technical Approach

### Overview
{High-level how}

### Key Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| {decision} | {what we chose} | {why} |

### Dependencies
- {What must exist before this track}
- {External services, APIs, etc.}

## UX Notes

{Any user experience considerations}

## Out of Scope

{What's deferred to future tracks}

## Open Questions

<!-- Resolve before approval -->
- [ ] {Question 1}
- [ ] {Question 2}

---
*Clause IDs: S1, S2, S3. Reference as SPEC.S1, etc.*
*This spec is frozen when track completes.*
```

## Lifecycle

1. **Draft**: Being written, questions open
2. **Approved**: Questions resolved, ready for planning
3. **In-progress**: Has associated plan, tasks executing
4. **Complete**: All acceptance criteria met, frozen
5. **Superseded**: Replaced by newer track (link to replacement)

## Checker Validation

Checkers validate tasks against:
- Acceptance criteria (S1, S2, S3...)
- Non-goals (must not include)
- Technical approach (must follow)
