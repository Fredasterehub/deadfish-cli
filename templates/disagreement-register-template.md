# Disagreement Register Template

For research phase when sources conflict.

```yaml
# Disagreement Register: {project-name}
date: {date}
researchers: [GPT-5.2, Claude-subagent, Claude-native]

disagreements:
  - id: D1
    topic: {what they disagree about}
    positions:
      - source: GPT-5.2
        position: {stance}
        confidence: high|medium|low
      - source: Claude
        position: {stance}
        confidence: high|medium|low
    conflict: {core disagreement}
    decision: {which position chosen}
    rationale: {why}
    change_mind_if: {conditions}
    resolution: synthesized|deferred|escalated

summary:
  - id: D1
    topic: {topic}
    decision: {choice}
    confidence: high|medium|low

agreed: [{topics where all sources aligned}]
```

## Resolution Strategies
- Majority: low-stakes, clear majority
- Expert source: one has domain authority
- Experiment: can test both cheaply
- Defer: decision can wait
- Escalate: high-stakes, no winner

## Integration
Disagreements may become: TECH_STACK entries, RISKS entries, or track-specific decisions.
