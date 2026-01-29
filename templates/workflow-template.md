# Workflow Template

Living document. Citable clauses. Budget: 400 tokens.

```yaml
# WORKFLOW.md
# Last updated: {date}

W1_done:
  - all verify steps pass
  - checker approves
  - builds without errors
  - tests pass (per W2)
  - committed with proper format

W2_testing:
  feature: unit tests for core logic
  bugfix: regression test
  refactor: existing tests pass
  config_docs: none

W3_commits:
  format: "{type}({scope}): {description}"
  types: [feat, fix, refactor, docs, test, chore]
  rules: [one per task, <72 chars, task ID in body]

W4_validation:
  clarification: before counter, doesn't count
  max_iterations: 3
  then: escalate to human
  disputes: must cite clause, no cite = proposer wins

W5_branches:
  main: always deployable
  feature: "feat/{track-id}"
  merge: squash to main

W6_review:
  focus: [correctness, patterns, security]
  style: only if violates PATTERNS.md

W7_escalation:
  - 3 iterations without consensus
  - no contract clause citable
  - security concern
  - VISION-level change proposed

W8_doc_updates:
  format: diffs not prose
  review: checker approves before apply
  atomic: one change per proposal
  log: reason in commit

# Clause IDs: WORKFLOW.W1–W8
```
