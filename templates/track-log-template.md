# Track Log Template

Decisions and learnings for ONE track. Append-only.

---

```markdown
# Log: {Track ID} - {Track Name}

*Spec*: [spec.md](spec.md)
*Plan*: [plan.md](plan.md)

---

## {Date}: {Entry Title}

**Type**: decision | learning | pivot | issue
**Task**: {task-id or "general"}

### Context
{What was happening}

### Decision/Learning
{What we decided or learned}

### Rationale
{Why}

### Implications
{What this affects going forward}

### Promotion Status
- [ ] Promote to PATTERNS.md (if pattern, needs 2+ uses)
- [ ] Add to PITFALLS.md (if trap discovered)
- [ ] Add to RISKS.md (if systemic risk)
- [ ] Update TECH_STACK.md (if stack decision)
- [ ] No promotion needed

---

## {Date}: {Another Entry}

...

---

## Top Learnings (Summary)

<!-- Updated when track completes -->
1. {Key learning 1}
2. {Key learning 2}
3. {Key learning 3}

## Decisions Made

| Decision | Date | Task | Rationale |
|----------|------|------|-----------|
| {decision} | {date} | {task-id} | {brief why} |

---
*Append-only during track. "Top Learnings" summarized at track completion.*
```

## Entry Types

| Type | When to Log |
|------|-------------|
| **decision** | Chose between alternatives |
| **learning** | Discovered something unexpected |
| **pivot** | Changed approach mid-track |
| **issue** | Hit a blocker or problem |

## Promotion Flow

After logging, evaluate for promotion:

```
Learning logged
     ↓
Is it generalizable?
     ↓ Yes
Is it a pattern (reusable approach)?
     ↓ Yes → Tag for PATTERNS.md (needs 2nd use to promote)
     ↓ No
Is it a pitfall (trap to avoid)?
     ↓ Yes → Add to PITFALLS.md
     ↓ No
Is it a risk (systemic issue)?
     ↓ Yes → Add to RISKS.md
     ↓ No
Stay in track log only
```

## Keeping It Lean

- Each entry: 5-10 lines max
- Top Learnings: max 5 items
- If log exceeds 50 entries, summarize older ones
