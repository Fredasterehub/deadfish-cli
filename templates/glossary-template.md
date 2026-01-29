# Glossary Template

Canonical definitions. All models use these terms. Budget: 200 tokens.

```yaml
# GLOSSARY.md

pipeline:
  task: atomic work unit — one TASK.md, one commit, one verify
  track: feature/fix unit — contains tasks, has spec + plan
  verify: confirm output meets criteria via executable steps
  done: passes all verify + checker approves
  mvp: minimum viable product per VISION.md — non-negotiable without pivot
  pivot: direction change requiring VISION.md update + Pivot Record

docs:
  constitution: VISION.md — static, changes via Pivot Record only
  living_doc: updates after successful tasks (PRODUCT, TECH_STACK, WORKFLOW, PATTERNS, PITFALLS, RISKS)
  contract: citable clause in VISION/WORKFLOW/PATTERNS/SPEC
  clause_id: "DOC.X{n}" (e.g. WORKFLOW.W3, VISION.V1)

workflow:
  proposer: model generating content
  checker: model validating against contracts
  clarification: info request before iteration counter — doesn't count
  escalation: human needed — after 3 fails or unresolvable dispute
  reflection: post-task analysis — diffs not prose

status: [planned, executing, verifying, done, failed, blocked, superseded]

pattern_tiers:
  experimental: used once, not enforced
  blessed: 2+ uses, enforced
  sunset: deprecated, warn only
```
