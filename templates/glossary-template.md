# Glossary

Canonical definitions. All models must use these terms consistently.

## Core Terms

| Term | Definition |
|------|------------|
| **Task** | Atomic unit of work. One TASK.md, one commit, one verification. |
| **Track** | High-level unit of work (feature, bugfix). Contains multiple tasks. Has spec + plan. |
| **Phase** | Deprecated. Use "track" instead. |
| **Verify** | Confirm task output meets acceptance criteria via concrete, executable steps. |
| **Done** | Task passes all verify steps AND checker approves. |
| **MVP** | Minimum viable product. Defined in VISION.md scope. Not negotiable without pivot. |
| **Pivot** | Major direction change requiring VISION.md update. Requires Pivot Record. |

## Document Terms

| Term | Definition |
|------|------------|
| **Constitution** | VISION.md. Static. Changes only via Pivot Record. |
| **Living Doc** | Updates after successful tasks. PRODUCT, TECH_STACK, WORKFLOW, PATTERNS, PITFALLS, RISKS. |
| **Contract** | Any clause in VISION, WORKFLOW, PATTERNS, or track spec that can be cited in disputes. |
| **Clause ID** | Stable identifier for contract clauses (e.g., `WORKFLOW.W3`, `VISION.V1`). |

## Workflow Terms

| Term | Definition |
|------|------------|
| **Proposer** | Model generating content (task, plan, doc update). |
| **Checker** | Model validating proposer output against contracts. |
| **Clarification** | Request for more info before iteration counter starts. Doesn't count toward 3 tries. |
| **Escalation** | Human intervention required. Triggers after 3 failed iterations or unresolvable dispute. |
| **Reflection** | Post-task analysis. Produces diff proposals, not prose. |

## Status Terms

| Term | Definition |
|------|------------|
| **planned** | Task generated, not yet executed. |
| **executing** | Task in progress. |
| **verifying** | Task executed, awaiting checker approval. |
| **done** | Task verified and approved. |
| **failed** | Task failed verification. Triggers failure reflection. |
| **blocked** | Task cannot proceed. Requires intervention. |
| **superseded** | Track/task replaced by newer version. |

## Pattern Terms

| Term | Definition |
|------|------------|
| **Experimental** | Pattern used once. Not yet blessed. Lives in track log until 2+ uses. |
| **Blessed** | Pattern used successfully 2+ times. Promoted to PATTERNS.md. |
| **Sunset** | Pattern marked for deprecation. Has "revisit by" date. |
