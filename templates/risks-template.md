# Risks Template

Living document. Proactive risk management. Fed by analysis.

---

```markdown
# Risks: {project-name}

*Last updated: {ISO date}*

## Risk Matrix

| ID | Risk | Impact | Likelihood | Score | Status |
|----|------|--------|------------|-------|--------|
| R1 | {name} | H/M/L | H/M/L | {I×L} | 🟢 Mitigated / 🟡 Monitoring / 🔴 Active |

---

## R1: {Risk Name}

**Category**: Technical | External | Resource | Schedule
**Impact**: 🔴 High | 🟠 Medium | 🟡 Low
**Likelihood**: 🔴 High | 🟠 Medium | 🟡 Low
**Status**: 🟢 Mitigated | 🟡 Monitoring | 🔴 Active
**Owner**: {who monitors this}

### Description
{What could go wrong}

### Trigger Conditions
{How we'd know this is happening}

### Impact if Realized
{Consequences}

### Mitigation Strategy
{How we're preventing/reducing this}

### Contingency Plan
{What we do if it happens anyway}

### Monitoring
{How we track this risk}

---

## R2: {Another Risk}

**Category**: {category}
**Impact**: {level}
**Likelihood**: {level}
**Status**: {status}
**Owner**: {owner}

### Description
{description}

### Trigger Conditions
{triggers}

### Mitigation Strategy
{strategy}

---

## Risk Categories

### Technical Risks
- R1, R3: {brief description}

### External Risks
- R2: {brief description}

### Resource Risks
- R4: {brief description}

---
*Clause IDs: R1, R2, etc. Reference as RISKS.R1, etc.*
```

## Update Triggers

Add to RISKS.md when:
- Research identifies potential issue
- Failure analysis reveals systemic risk
- External factors change (dependencies, market, etc.)
- Escalation reveals process gap

## Risk Scoring

| Impact | Likelihood | Score | Action |
|--------|------------|-------|--------|
| High | High | 9 | Immediate mitigation required |
| High | Medium | 6 | Active mitigation |
| High | Low | 3 | Monitor closely |
| Medium | High | 6 | Active mitigation |
| Medium | Medium | 4 | Standard monitoring |
| Medium | Low | 2 | Accept with awareness |
| Low | Any | 1-3 | Accept |

## Reflection → Risks Flow

When reflection identifies a failure:
1. Check if it's a one-off (→ PITFALLS) or systemic (→ RISKS)
2. Systemic issues get risk entry with mitigation plan
3. Owner assigned for monitoring
