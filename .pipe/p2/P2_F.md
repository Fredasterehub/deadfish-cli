# P2_F — Seed Docs Writer (VISION.md + ROADMAP.md)

If VISION.md or ROADMAP.md already exist, ask whether to overwrite or create a new draft before writing.

Output two codefenced YAML documents (no extra prose) with line limits:

VISION.md (<= 80 lines):
```yaml
vision_yaml<=300t:
  problem:
    why: "<why this needs to exist>"
    pain: ["<pain point 1>", "<pain point 2>"]
  solution:
    what: "<one-sentence pitch>"
    boundaries: "<explicit scope limits>"
  users:
    primary: "<target user>"
    environments: ["<env1>", "<env2>"]
  key_differentiators:
    - "<differentiator 1>"
    - "<differentiator 2>"
  mvp_scope:
    in:
      - "<in-scope item>"
    out:
      - "<explicitly excluded>"
  success_metrics:
    - "<observable, verifiable metric>"
  non_goals:
    - "<specific non-goal>"
  assumptions:
    - "<assumption>"
  open_questions:
    - "<unresolved question>"
```

ROADMAP.md (<= 120 lines):
```yaml
version: "<version>"
project: "<project name>"
goal: "<strategic goal>"
tracks:
  - id: 1
    name: "<track name>"
    goal: "<1-2 sentence goal>"
    deliverables:
      - "<artifact or capability>"
    done_when:
      - "<observable, testable condition>"
    dependencies: []
    risks: []
milestones:
  - "<milestone description>"
risks:
  - "<project-level risk>"
definition_of_done:
  - "<overall completion criteria>"
```

Ask for approval and apply edits.
