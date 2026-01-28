# Pitfalls Template

Living document. Known traps and mitigations. Fed by failures.

---

```markdown
# Pitfalls: {project-name}

*Last updated: {ISO date}*

## How to Use

Checkers scan relevant pitfalls before approving tasks that touch affected areas.

---

## PF1: {Pitfall Name}

**Area**: {e.g., auth, database, deployment}
**Severity**: 🔴 Critical | 🟠 High | 🟡 Medium
**Added**: {date}
**Source**: {task-id or "research"}

### Symptom
{How you know you've hit this}

### Cause
{Why this happens}

### Fix
{How to resolve when encountered}

### Prevention
{How to avoid in the first place}

### Affected Patterns
- {Pattern ID if relevant}

---

## PF2: {Another Pitfall}

**Area**: {area}
**Severity**: 🟠 High
**Added**: {date}
**Source**: {task-id}

### Symptom
{What you observe}

### Cause
{Root cause}

### Fix
{Resolution steps}

### Prevention
{Preventive measures}

---

## Pitfalls by Area

| Area | Pitfalls |
|------|----------|
| Auth | PF1, PF3 |
| Database | PF2 |
| Deployment | PF4 |
| Testing | PF5 |

---
*Clause IDs: PF1, PF2, etc. Reference as PITFALLS.PF1, etc.*
```

## Update Triggers

Add to PITFALLS.md when:
- Task fails and root cause identified
- Near-miss discovered during review
- Research surfaces known issues
- External advisory (security, deprecation)

## Diff Format

```diff
+ ## PF{n}: {New Pitfall}
+ 
+ **Area**: {area}
+ **Severity**: {level}
+ **Added**: {date}
+ **Source**: {task-id}
+ 
+ ### Symptom
+ {description}
+ 
+ ### Cause
+ {description}
+ 
+ ### Fix
+ {steps}
+ 
+ ### Prevention
+ {measures}
```

## Merge Rules

- Similar pitfalls: merge into one with broader scope
- If mitigation becomes routine: promote to WORKFLOW.md checklist
- Quarterly review: prune resolved/obsolete pitfalls
