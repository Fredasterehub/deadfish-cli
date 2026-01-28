# deadf(ish) Methodology

Complete reference for the deadf(ish) development pipeline.

## Table of Contents

1. [Core Philosophy](#core-philosophy)
2. [Document Architecture](#document-architecture)
3. [Workflow Phases](#workflow-phases)
4. [Validation Rules](#validation-rules)
5. [Reflection Process](#reflection-process)
6. [Contract System](#contract-system)
7. [Naming Conventions](#naming-conventions)

---

## Core Philosophy

### Plan Incrementally

Don't plan everything upfront. Work in **tracks** (features/fixes):
1. Spec one track
2. Plan that track
3. Execute tasks
4. Reflect and learn
5. Next track

Each track completion is an opportunity to update understanding.

### Execute Atomically

One task = one commit = one verification.
- Tasks are the smallest unit of shippable work
- Each task has clear acceptance criteria
- Rollback instructions included

### Reflect on ALL Outcomes

Traditional pipelines only celebrate success. deadf(ish) learns from everything:

| Outcome | What We Learn | Where It Goes |
|---------|---------------|---------------|
| Success | Patterns that work | PATTERNS.md |
| Failure | Traps to avoid | PITFALLS.md, RISKS.md |
| Escalation | Missing contracts | WORKFLOW.md, VISION.md |

### Evolve Documentation

Docs are living artifacts, not write-once-read-never:
- Updated after successful tasks
- Updates are diffs, not prose
- Each update is reviewed before applying

---

## Document Architecture

### Hierarchy

```
Constitution (static)
    └── VISION.md

Living Docs (evolve)
    ├── PRODUCT.md      - Goals, users, metrics
    ├── TECH_STACK.md   - Stack decisions
    ├── WORKFLOW.md     - Process rules
    ├── PATTERNS.md     - Blessed approaches
    ├── PITFALLS.md     - Known traps
    ├── RISKS.md        - Proactive risks
    └── GLOSSARY.md     - Term definitions

Execution (continuous)
    ├── ROADMAP.md      - Themes + next tracks
    ├── STATE.md        - Current position
    └── TASK.md         - Current task

Tracks (per-feature)
    ├── tracks.md       - Index
    └── tracks/<id>/
        ├── spec.md     - Specification
        ├── plan.md     - Task breakdown
        └── log.md      - Decisions + learnings
```

### Document Purposes

| Document | Purpose | Updates When |
|----------|---------|--------------|
| VISION.md | Problem, users, MVP scope | Only via pivot record |
| PRODUCT.md | Current goals, metrics | Understanding changes |
| TECH_STACK.md | Stack decisions + rationale | Tech decisions change |
| WORKFLOW.md | Process rules (DoD, commits) | Process improves |
| PATTERNS.md | Blessed implementation patterns | Pattern proven 2+ times |
| PITFALLS.md | Known traps + mitigations | Failure analyzed |
| RISKS.md | Proactive risk management | Risk identified |
| GLOSSARY.md | Term definitions | Ambiguity found |
| ROADMAP.md | Themes + next 2-4 tracks | Priorities shift |
| STATE.md | What's happening now | Continuously |
| TASK.md | Current atomic task | Per task |

---

## Workflow Phases

### Phase 1: Initialize

**Goal**: Set up project structure and discover vision.

Steps:
1. Create project folder with document structure
2. Run brainstorm session → VISION.md
3. Research stack, patterns, pitfalls
4. Seed living docs from research
5. Create ROADMAP.md with initial themes

### Phase 2: Track Loop

**Goal**: Deliver one feature/fix at a time.

```
Select track from ROADMAP
         │
         ▼
Write spec (tracks/<id>/spec.md)
         │
         ▼
Validate spec against VISION
         │
         ▼
Write plan (tracks/<id>/plan.md)
         │
         ▼
Validate plan feasibility
         │
         ▼
    TASK LOOP ──────────────┐
         │                  │
         ▼                  │
    Generate TASK.md        │
         │                  │
         ▼                  │
    Execute task            │
         │                  │
         ▼                  │
    Verify output           │
         │                  │
         ▼                  │
    Reflect (ALL outcomes)  │
         │                  │
         ▼                  │
    Update living docs      │
         │                  │
    More tasks? ────────────┘
         │ No
         ▼
Mark track complete
Freeze spec
```

### Phase 3: Reflection

**Goal**: Extract learning from every outcome.

Triggered after:
- Task verified successful ✅
- Task failed verification ❌
- Validation escalated to human ⏫

Questions:
1. What changed? (facts)
2. What did we learn? (generalizable)
3. What should we do next time? (actionable)
4. Do docs need updating? (which, what change)

Output: Diff proposals for living doc updates.

---

## Validation Rules

### 3-Try Rule

All validation checkpoints use max 3 iterations:

```
Submission
    │
    ▼
[Clarification step - doesn't count]
    │
    ▼
Iteration 1 ───► Approved? ──► Continue
    │                 │
    │ Rejected        │
    ▼                 │
Iteration 2 ───► Approved? ──► Continue
    │                 │
    │ Rejected        │
    ▼                 │
Iteration 3 ───► Approved? ──► Continue
    │                 │
    │ Rejected        │
    ▼                 │
ESCALATE to human ◄──┘
```

### Clarification Step

Before iterations start, can request clarification:
- Used for genuine ambiguity
- NOT for disagreements
- Doesn't count toward 3 tries

### Contract Citation

When rejecting, MUST cite a contract clause:
- Format: `WORKFLOW.W3`, `PATTERNS.P2`, `SPEC.S1`
- No citation = discretionary issue
- Discretionary = default to original proposal

### Escalation

Escalate when:
- 3 iterations without consensus
- Neither party can cite contract
- Security concern
- VISION-level change proposed

---

## Reflection Process

### Success Reflection

```
Task succeeded
      │
      ▼
Did we use a new approach?
      │
      ├─► No: Done
      │
      ▼ Yes
Log as experimental pattern
      │
      ▼
Is this the 2nd+ use?
      │
      ├─► No: Stay in track log
      │
      ▼ Yes
Promote to PATTERNS.md (blessed)
```

### Failure Reflection

```
Task failed
      │
      ▼
Identify root cause
      │
      ▼
Is this a one-off mistake?
      │
      ├─► Yes: Add to PITFALLS.md
      │
      ▼ No
Is this systemic?
      │
      ├─► Yes: Add to RISKS.md
      │
      ▼ No
Log in track log only
```

### Escalation Reflection

```
Escalated to human
      │
      ▼
Why couldn't it resolve?
      │
      ├─► Missing contract clause
      │       └─► Propose addition
      │
      ├─► Ambiguous clause
      │       └─► Propose clarification
      │
      └─► Technical impasse
              └─► Log decision + rationale
```

### Diff Format

Reflection outputs diffs, not prose:

```diff
## Proposed Update: PITFALLS.md

### Reason
Task T02.03 failed due to timezone bug.

### Diff
+ ## PF7: Timezone Edge Cases
+
+ **Area**: datetime
+ **Severity**: 🟠 High
+
+ ### Symptom
+ Dates display incorrectly across timezones.
+
+ ### Prevention
+ Always store as UTC, convert on display.

### Location
Section: Pitfalls by Area
After: PF6
```

---

## Contract System

### Clause IDs

Every citable rule has a stable ID:

| Document | Format | Example |
|----------|--------|---------|
| VISION.md | V{n} | VISION.V1 |
| WORKFLOW.md | W{n} | WORKFLOW.W3 |
| PATTERNS.md | P{n} | PATTERNS.P2 |
| PITFALLS.md | PF{n} | PITFALLS.PF5 |
| RISKS.md | R{n} | RISKS.R1 |
| Track spec | S{n} | SPEC.S3 |

### Citing in Validation

When rejecting:
```
REJECTED
---
Clause: WORKFLOW.W2
Reason: Verification steps not executable
Fix: Add specific curl command with expected output
```

When approving with notes:
```
APPROVED
---
Notes: Consider PATTERNS.P3 for error handling
```

### Adding New Clauses

When reflection suggests a missing clause:
1. Propose diff to relevant document
2. Include clause ID in sequence
3. Review before applying
4. Update GLOSSARY if new term introduced

---

## Naming Conventions

### Track IDs

Format: `T{nn}-{slug}`
- `T01-auth-system`
- `T02-receipt-upload`

### Task IDs

Format: `{track-id}.{nn}`
- `T01-auth-system.01`
- `T01-auth-system.02`

### Clause IDs

Format: `{DOC}.{letter}{n}`
- `VISION.V1`
- `WORKFLOW.W3`
- `PATTERNS.P2`

### Branch Names

Format: `{type}/{track-id}`
- `feat/T01-auth-system`
- `fix/T05-login-bug`

### Commit Messages

Format: `{type}({scope}): {description}`
- `feat(auth): add registration endpoint`
- `fix(upload): handle large files`

---

## Summary

deadf(ish) is built on four pillars:

1. **Incremental Planning** - One track at a time
2. **Atomic Execution** - One task, one commit
3. **Universal Reflection** - Learn from all outcomes
4. **Living Documentation** - Evolve with the project

Follow the workflow. Trust the process. Ship good code.

---

*deadf(ish) - Plan incrementally, execute atomically, reflect always.* 🐟💀
