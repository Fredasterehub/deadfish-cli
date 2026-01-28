# Workflow Template

Living document. Defines how we work. Contains citable clauses.

---

```markdown
# Workflow: {project-name}

*Last updated: {ISO date}*

## W1: Definition of Done

A task is "done" when ALL of the following are true:
- [ ] All verify steps pass
- [ ] Checker approves
- [ ] Code compiles/builds without errors
- [ ] Tests pass (if applicable per W2)
- [ ] Committed with proper message format

## W2: Testing Requirements

| Task Type | Test Requirement |
|-----------|------------------|
| New feature | Unit tests for core logic |
| Bug fix | Regression test for the bug |
| Refactor | Existing tests still pass |
| Config/docs | No tests required |

## W3: Commit Strategy

Format: `{type}({scope}): {description}`

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

Rules:
- One commit per task (atomic)
- Description < 72 chars
- Reference task ID in body

## W4: Validation Rules

### Clarification Step
- Before iteration counter starts
- Used for genuine ambiguity, not disagreement
- Doesn't count toward 3 tries

### Iteration Limit
- Max 3 back-and-forth per validation checkpoint
- After 3: escalate to human

### Dispute Resolution
- Disputes MUST cite a contract clause
- If neither party can cite: discretionary → default to proposer
- Unresolvable disputes: escalate immediately

## W5: Branch Strategy

- Main branch: always deployable
- Feature branches: `feat/{track-id}`
- One branch per track
- Squash merge to main

## W6: Code Review

- Checker reviews all code changes
- Focus: correctness, patterns compliance, security
- Style issues: only if violates PATTERNS.md

## W7: Escalation Protocol

Escalate to human when:
- 3 iterations without consensus
- Dispute cannot cite contract clause
- Security concern identified
- VISION-level change proposed

## W8: Living Doc Updates

- Updates proposed as diffs, not prose
- Checker reviews diff before applying
- Updates atomic: one change per proposal
- Log reason in commit message

---
*Clause IDs: W1-W8. Reference as WORKFLOW.W1, WORKFLOW.W2, etc.*
```

## Critical Clauses

**W4 (Validation Rules)** - Most frequently cited. Governs all checker interactions.

**W7 (Escalation Protocol)** - Defines when to stop iterating and ask human.

**W8 (Living Doc Updates)** - How docs evolve without degradation.
