# Risks Template

Living document. Proactive risk management. Budget: 300 tokens.

```yaml
# RISKS.md
# Last updated: {date}

risks:
  - id: R1
    name: {name}
    category: technical|external|resource|schedule
    impact: high|medium|low
    likelihood: high|medium|low
    status: mitigated|monitoring|active
    owner: {who}
    description: {what could go wrong}
    triggers: {how we'd know}
    mitigation: {prevention strategy}
    contingency: {if it happens anyway}

matrix:
  - id: R1
    impact: H
    likelihood: M
    score: 6
    status: monitoring

# Clause IDs: RISKS.R1, R2, etc.
```

## Scoring: H=3 M=2 L=1, score=impact×likelihood
- 6-9: immediate mitigation
- 3-5: active monitoring
- 1-2: accept

## Update Triggers
- Research identifies potential issue
- Failure analysis reveals systemic risk
- External factors change
- Escalation reveals process gap
