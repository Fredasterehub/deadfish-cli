# Disagreement Register Template

For research phase when sources conflict.

---

```markdown
# Research Disagreement Register: {project-name}

*Research date*: {date}
*Researchers*: GPT-5.2, Claude subagent, Claude native

---

## D1: {Topic of Disagreement}

### Sources

| Source | Position | Confidence |
|--------|----------|------------|
| GPT-5.2 | {position} | High/Medium/Low |
| Claude subagent | {position} | High/Medium/Low |
| Claude native | {position} | High/Medium/Low |
| {External source} | {position} | — |

### The Conflict
{What exactly the sources disagree about}

### Our Decision
**Chose**: {which position}
**Rationale**: {why this over others}

### What Would Change Our Mind
{Conditions that would trigger reconsideration}

### Resolution
- [ ] Resolved in synthesis
- [ ] Deferred to implementation
- [ ] Escalated to human

---

## D2: {Another Disagreement}

...

---

## Summary

| ID | Topic | Decision | Confidence |
|----|-------|----------|------------|
| D1 | {topic} | {choice} | High/Medium/Low |
| D2 | {topic} | {choice} | High/Medium/Low |

## No Disagreement Areas

{List topics where all sources agreed - for confidence}

---
*Created during research synthesis. Reference when related decisions arise.*
```

## When to Create

Create disagreement register when:
- Research sources give conflicting recommendations
- Best practices vary by context
- Trade-offs have no clear winner
- External sources conflict with model knowledge

## Resolution Strategies

| Strategy | When to Use |
|----------|-------------|
| **Majority** | Low-stakes, clear majority |
| **Expert source** | One source has domain authority |
| **Experimentation** | Can test both cheaply |
| **Defer** | Decision can wait for more info |
| **Escalate** | High-stakes, no clear winner |

## Integration with Living Docs

Disagreements may become:
- TECH_STACK.md entries (with "revisit when")
- RISKS.md entries (if unresolved = risk)
- Track-specific decisions (logged in track log)
