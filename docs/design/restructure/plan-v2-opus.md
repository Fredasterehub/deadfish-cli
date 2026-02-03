# Restructuring Plan v2 — deadf(ish) CLI Pipeline

> **Author:** Opus 4.5 (subagent)
> **Date:** 2026-02-02
> **Sources:** GSD, Google Conductor, synthesis-opus-orchestrator v1, GPT-5.2 codebase analysis, all current deadfish-cli files
> **Constraint:** Fred's `.deadf/` directive, CLAUDE.md ≤300 lines, semantic naming, fix contract/tool mismatches

---

## Executive Summary

This plan redesigns the deadfish-cli file structure, naming, and contract layout by synthesizing three reference systems:

| System | What we take | What we skip |
|--------|-------------|-------------|
| **GSD** | `.planning/` as inspiration for `.deadf/` layout; fresh-context-per-task; plans-as-prompts (already adopted); phase-organized artifacts; `CONTEXT.md` per-phase idea | Enterprise-oriented slash commands; no sentinel grammar; no deterministic verification |
| **Conductor** | `conductor/` as inspiration for project-context docs; `tracks/<id>/` per-track layout (already adopted); `product.md`/`tech-stack.md`/`workflow.md` → maps to our living docs; `tracks.md` index file; brownfield setup flow | Single-agent model; no multi-model dispatch; no nonce/sentinel; manual verification |
| **deadfish v1 synthesis** | `.claude/rules/` + `.claude/imports/` split; semantic naming table; contract/tool reconciliation priorities; implementation phases | Over-loaded `.claude/rules/` (940 lines auto-loaded); some naming inconsistencies |

**Key philosophical alignment:** All three systems agree on: (1) context management is the hard problem, (2) plans should be atomic and bounded, (3) project context should be structured docs not giant instruction files, (4) brownfield needs explicit discovery. We keep our unique strengths (deterministic verification, sentinel grammar, 3-tier recovery, multi-model architecture) while adopting their superior ergonomics.

---

## A) Proposed Directory Structure

### A.1 — deadfish-cli Repo (the toolkit)

This is the source repo. When deployed to a target project, scripts and templates get copied into `.deadf/`.

```
deadfish-cli/
├── CLAUDE.md                              # ≤250 lines — lean orchestrator skeleton
├── .claude/
│   ├── rules/                             # auto-loaded by Claude Code (~160 lines total)
│   │   ├── core.md                        #   role boundaries, one-cycle-one-action
│   │   ├── state-locking.md               #   flock pattern, atomic writes
│   │   ├── safety.md                      #   blocked paths, no secrets, tool restrictions  
│   │   └── output-contract.md             #   last-line tokens, block-only sentinel output
│   └── imports/                           # on-demand via @import
│       ├── actions/                       #   one file per DECIDE action
│       │   ├── seed-docs.md
│       │   ├── pick-track.md
│       │   ├── create-spec.md
│       │   ├── create-plan.md
│       │   ├── generate-task.md
│       │   ├── implement-task.md
│       │   ├── verify-task.md
│       │   ├── reflect.md
│       │   ├── qa-review.md
│       │   └── recovery.md               #   retry, replan, rollback, escalate, summarize
│       ├── grammars/                      #   sentinel format specs
│       │   ├── plan-v1.md
│       │   ├── track-v1.md
│       │   ├── spec-v1.md
│       │   ├── verdict-v1.md
│       │   ├── reflect-v1.md
│       │   └── qa-review-v1.md
│       └── integrations/                  #   cross-cutting concerns
│           ├── task-management.md         #   Claude Code Tasks naming, recovery, gate
│           ├── escalation.md              #   3-tier P10 protocol
│           └── notifications.md           #   mode-dependent notification rules
│
├── agents/                                # worker agent prompt templates (≈ GSD agents/)
│   ├── kick/
│   │   └── cycle-kick.md                  #   was P1_CYCLE_KICK.md
│   ├── research/
│   │   ├── brainstorm-main.md             #   was P2_MAIN.md
│   │   ├── brainstorm-a.md through g.md   #   was P2_A.md through P2_G.md
│   │   ├── brainstorm-a2.md               #   was P2_A2.md
│   │   └── templates/                     #   was P2_*_TEMPLATE.md
│   │       ├── project.tmpl.md
│   │       ├── requirements.tmpl.md
│   │       └── roadmap.tmpl.md
│   ├── init/                              #   was P12 prompts
│   │   ├── mapper-agent.md                #   was MAPPER_AGENT.md
│   │   ├── synthesizer.md                 #   was SYNTHESIZER.md
│   │   ├── brownfield-brainstorm.md       #   was BROWNFIELD_P2.md
│   │   └── living-docs.tmpl              #   was LIVING_DOCS.tmpl
│   ├── select-track/
│   │   ├── pick-track.md                  #   was P3_PICK_TRACK.md
│   │   ├── create-spec.md                 #   was P4_CREATE_SPEC.md
│   │   └── create-plan.md                 #   was P5_CREATE_PLAN.md
│   ├── execute/
│   │   ├── generate-task.md               #   was P6_GENERATE_TASK.md
│   │   └── implement-task.md              #   was P7_IMPLEMENT_TASK.md
│   ├── verify/
│   │   └── verify-criterion.md            #   was P9_VERIFY_CRITERION.md
│   ├── reflect/
│   │   └── reflect.md                     #   was P9_5_REFLECT.md
│   ├── repair/
│   │   ├── format-repair.md               #   was P10_FORMAT_REPAIR.md
│   │   └── auto-diagnose.md               #   was P10_AUTO_DIAGNOSE.md
│   └── qa/
│       └── qa-review.md                   #   was P11_QA_REVIEW.md
│
├── scripts/                               # executable tooling
│   ├── ralph.sh                           #   loop controller (simplified)
│   ├── verify.sh                          #   deterministic verifier (fixed)
│   ├── cron-kick.sh                       #   was p1-cron-kick.sh
│   ├── assemble-kick.sh                   #   NEW: shared kick assembly
│   ├── extract-sentinel.py                #   was extract_plan.py (extended)
│   ├── build-verdict.py                   #   was build_verdict.py
│   ├── brainstorm.sh                      #   was p2-brainstorm.sh
│   ├── init.sh                            #   was p12-init.sh
│   ├── init-detect.sh                     #   was P12_DETECT.sh
│   ├── init-collect.sh                    #   was P12_COLLECT.sh
│   ├── init-map.sh                        #   was P12_MAP.sh
│   ├── init-confirm.sh                    #   was P12_CONFIRM.sh
│   ├── init-inject.sh                     #   was P12_INJECT.sh
│   └── budget-check.sh                    #   was p12-budget-check.sh
│
├── tests/
│   ├── fixtures/
│   │   └── sentinels/                     #   golden files for parser tests
│   │       ├── plan-valid.txt
│   │       ├── plan-invalid.txt
│   │       ├── track-valid.txt
│   │       ├── spec-valid.txt
│   │       ├── verdict-valid.txt
│   │       └── qa-review-valid.txt
│   └── results/
│       └── integration-test-results.md
│
├── docs/                                  # design artifacts (not runtime)
│   ├── design/
│   ├── reviews/                           #   was .pipe/reviews/
│   └── analysis/                          #   was .pipe/*-design-*.md files
│
├── POLICY.yaml
├── ROADMAP.md
├── VISION.md
├── METHODOLOGY.md
├── PROMPT_OPTIMIZATION.md
├── README.md
├── llms.txt
├── .mcp.json
├── examples/
│   └── project-structure.md
└── .gitignore
```

**Rationale for `agents/` over `templates/`:**
- GSD uses `agents/` for its worker prompts (gsd-executor.md, gsd-planner.md, etc.)
- These files ARE agent instructions, not passive data templates
- Naming aligns with the mental model: "which agent does this work?"
- The subdirectory structure mirrors pipeline phases (like GSD's stage-based organization)

### A.2 — Target Project `.deadf/` (deployed runtime)

When deadfish deploys to a target project, this is what gets created. Inspired by GSD's `.planning/` (research, plans, summaries per phase) and Conductor's `conductor/` (product context, tracks, metadata).

```
<target-project>/
├── .deadf/                                # EVERYTHING pipeline-related
│   ├── context/                           # ≈ Conductor's product/tech-stack/workflow
│   │   ├── VISION.md                      #   project constitution (rarely changes)
│   │   ├── PROJECT.md                     #   living project context
│   │   ├── REQUIREMENTS.md                #   checkable requirements with IDs
│   │   ├── ROADMAP.md                     #   phases + strategic plan
│   │   └── OPS.md                         #   build/test/run commands (≤60 lines)
│   │
│   ├── docs/                              # ≈ Conductor's product.md + GSD's research/
│   │   ├── TECH_STACK.md                  #   living doc (P12/P9.5)
│   │   ├── PATTERNS.md                    #   living doc
│   │   ├── PITFALLS.md                    #   living doc
│   │   ├── RISKS.md                       #   living doc
│   │   ├── PRODUCT.md                     #   living doc
│   │   ├── WORKFLOW.md                    #   living doc
│   │   ├── GLOSSARY.md                    #   living doc
│   │   └── .scratch.yaml                  #   reflect buffer
│   │
│   ├── tracks/                            # ≈ Conductor's tracks/<id>/
│   │   ├── index.md                       #   ≈ Conductor's tracks.md (all tracks, status)
│   │   └── <track-id>/
│   │       ├── SPEC.md                    #   ≈ Conductor's spec.md
│   │       ├── PLAN.md                    #   ≈ Conductor's plan.md
│   │       ├── metadata.yaml              #   ≈ Conductor's metadata.json (track-level stats)
│   │       └── tasks/
│   │           ├── TASK_001.md
│   │           ├── TASK_002.md
│   │           └── ...
│   │
│   ├── seed/                              # brainstorm/init markers
│   │   └── P2_DONE                        #   marker file
│   │
│   ├── logs/                              # cycle logs + QA warnings
│   │   ├── cycle-<id>.log
│   │   ├── qa_warnings.md                 #   append-only QA findings
│   │   └── mismatch-<cycle_id>.md         #   P10 Tier 2 diagnostics
│   │
│   ├── notifications/                     # event notifications for operator
│   │   ├── track-complete-<ts>.md
│   │   ├── escalation-<ts>.md
│   │   └── complete.md
│   │
│   ├── tooling-repairs/                   # queued parser/tool fixes (from P10 MISMATCH)
│   │   └── repair-<ts>.md
│   │
│   ├── agents/                            # deployed agent templates (copied from repo)
│   │   └── (mirrors repo agents/ structure)
│   │
│   ├── scripts/                           # deployed scripts (copied from repo)
│   │   └── (mirrors repo scripts/ structure)
│   │
│   ├── STATE.yaml                         # authoritative pipeline state
│   ├── STATE.yaml.flock                   # lock file for atomic writes
│   ├── POLICY.yaml                        # mode behavior, thresholds
│   ├── cron.lock                          # process lock
│   ├── ralph.lock                         # ralph instance lock
│   ├── task_list_id                       # Claude Code Task list ID
│   └── task_list_track                    # track rotation detector
```

**Key structural decisions:**

1. **`context/` vs root-level docs:** GSD puts PROJECT.md, REQUIREMENTS.md, ROADMAP.md at project root. Conductor puts product.md, tech-stack.md inside `conductor/`. We follow Fred's directive: everything in `.deadf/`. But we add a `context/` subdirectory to separate "what we're building" from "how we're building it" (tracks, state, logs).

2. **`docs/` for living docs:** These are the P12/P9.5 living docs that evolve with the codebase. Conductor's `product.md` + `product-guidelines.md` + `tech-stack.md` + `code_styleguides/` maps conceptually to our 7 living docs. The key difference: ours are machine-generated and budget-constrained; Conductor's are human-authored. We keep the machine approach but adopt Conductor's "persistent project awareness" philosophy.

3. **`tracks/index.md`:** Directly adopted from Conductor's `tracks.md`. Provides a single-file overview of all tracks (past, current, queued) with status. Currently missing from our system — the orchestrator has to piece together track history from STATE.yaml and git. This file is append-only and updated by the orchestrator at track transitions.

4. **`tracks/<id>/metadata.yaml`:** Adopted from Conductor's `metadata.json`. Contains track-level statistics: start/end timestamps, task count, total diff lines, verify pass/fail counts, QA result. Useful for trends analysis without parsing STATE.yaml history.

5. **`agents/` deployed:** When deadfish initializes a target project, agent templates are copied from the repo into `.deadf/agents/`. This makes the target project self-contained — it doesn't need the deadfish-cli repo at runtime.

---

## B) CLAUDE.md Split Strategy

### B.1 — The Problem

Current CLAUDE.md: 1,240 lines. Every cycle loads ALL of it. At ~4 chars/token, that's ~15K tokens burned on contract text before any work begins.

### B.2 — The Split (GPT-5.2's approach, validated)

**Principle:** `.claude/rules/` for invariants (always needed). `@import` for action-specific specs (loaded by DECIDE step). This mirrors GSD's approach of keeping the orchestrator lean and loading phase-specific context only when needed.

#### CLAUDE.md — Target ≤250 lines

```markdown
# CLAUDE.md — deadf(ish) Iteration Contract v3.0

## Identity (~20 lines)
You are Claude Code (Opus 4.5) — the Orchestrator.
You coordinate workers. You do NOT write code / plan tasks / judge quality / override verdicts.
You DO: read state → decide → dispatch → parse → record → reply.

## Setup: Multi-Model via Codex MCP (~15 lines)
.mcp.json config reference. codex/codex-reply tools. Session continuity.

## Cycle Protocol (~40 lines)
6-step skeleton: LOAD → VALIDATE → DECIDE → EXECUTE → RECORD → REPLY
Brief description of each step (3-5 lines each).
"Before executing action X, @import .claude/imports/actions/X.md"
"When parsing block type Y, @import .claude/imports/grammars/Y.md"

## DECIDE Table (~35 lines)
Full precedence-ordered decision table (14 rows).
This MUST stay in CLAUDE.md — it's the state machine core.

## State Write Authority (~15 lines)
Who can write what to STATE.yaml.

## Model Dispatch Reference (~20 lines)
Purpose → command → model table.

## Quick Reference (~15 lines)
ASCII cycle flow diagram.
Task Management commands table.

## Safety Constraints (~10 lines)
10 numbered rules (same as current).
```

**Total: ~170 lines.** Leaves buffer for formatting/headers to stay ≤250.

#### .claude/rules/ — Auto-loaded (~160 lines total)

| File | Content | Lines |
|------|---------|-------|
| `core.md` | Role boundaries, one-cycle-one-action, no-improvisation, nonce lifecycle | ~40 |
| `state-locking.md` | flock pattern, atomic write template, lock discipline | ~40 |
| `safety.md` | Blocked paths, no-secrets, tool restrictions, sandbox rules | ~35 |
| `output-contract.md` | Last-line token rules, block-only output, no-prose rules | ~25 |

**Why NOT an `imports-index.md` in rules/:** The mapping from action→file is implicit in the directory structure. `seed-docs` action → `actions/seed-docs.md`. No index needed. CLAUDE.md's DECIDE table already names the actions; the import rule says "load the file matching the action name."

#### .claude/imports/ — On-demand (~800 lines total)

Loaded via `@.claude/imports/actions/X.md` when the DECIDE step selects action X.

| Category | Files | Avg Lines | Total |
|----------|-------|-----------|-------|
| `actions/` | 10 files | ~45 | ~450 |
| `grammars/` | 6 files | ~25 | ~150 |
| `integrations/` | 3 files | ~65 | ~200 |

**Token budget per cycle:**
- Always: CLAUDE.md (~250 lines ≈ 3K tokens) + rules/ (~160 lines ≈ 2K tokens) = **~5K tokens**
- Per action: one action spec (~45 lines ≈ 600 tokens) + one grammar (~25 lines ≈ 350 tokens) = **~1K tokens**
- **Total: ~6K tokens** (down from ~15K)

### B.3 — Import Flow (Concrete)

```
Cycle starts → LOAD (reads STATE.yaml, POLICY.yaml, OPS.md, task files)
            → VALIDATE (nonce derivation, budget checks)
            → DECIDE (reads table, determines action = "verify-task")
            → "@import .claude/imports/actions/verify-task.md"
            → (action spec says: parse VERDICT blocks)
            → "@import .claude/imports/grammars/verdict-v1.md"
            → EXECUTE (run verify.sh, dispatch sub-agents, parse verdicts)
            → RECORD (update STATE.yaml)
            → REPLY (CYCLE_OK)
```

---

## C) Semantic Naming

### C.1 — Naming Convention

**Rule:** No P-numbers in file names. Names describe what the thing does, not when it was designed.

**Files use kebab-case.** Directories use kebab-case. YAML/MD content files use UPPER_SNAKE for well-known names (STATE.yaml, POLICY.yaml, VISION.md, etc.).

### C.2 — Complete Mapping

| Old ID | Old Path | New Path (repo) | New Path (deployed .deadf/) |
|--------|----------|-----------------|---------------------------|
| P1 | `.pipe/p1/P1_CYCLE_KICK.md` | `agents/kick/cycle-kick.md` | `.deadf/agents/kick/cycle-kick.md` |
| P1 | `.pipe/p1/p1-cron-kick.sh` | `scripts/cron-kick.sh` | `.deadf/scripts/cron-kick.sh` |
| P2 | `.pipe/p2/P2_MAIN.md` | `agents/research/brainstorm-main.md` | `.deadf/agents/research/brainstorm-main.md` |
| P2 | `.pipe/p2/P2_A.md` | `agents/research/brainstorm-a.md` | (same pattern) |
| P2 | `.pipe/p2/P2_PROJECT_TEMPLATE.md` | `agents/research/templates/project.tmpl.md` | (same pattern) |
| P2 | `.pipe/p2-brainstorm.sh` | `scripts/brainstorm.sh` | `.deadf/scripts/brainstorm.sh` |
| P3 | `.pipe/p3/P3_PICK_TRACK.md` | `agents/select-track/pick-track.md` | `.deadf/agents/select-track/pick-track.md` |
| P4 | `.pipe/p4/P4_CREATE_SPEC.md` | `agents/select-track/create-spec.md` | (same pattern) |
| P5 | `.pipe/p5/P5_CREATE_PLAN.md` | `agents/select-track/create-plan.md` | (same pattern) |
| P6 | `.pipe/p6/P6_GENERATE_TASK.md` | `agents/execute/generate-task.md` | (same pattern) |
| P7 | `.pipe/p7/P7_IMPLEMENT_TASK.md` | `agents/execute/implement-task.md` | (same pattern) |
| P9 | `.pipe/p9/P9_VERIFY_CRITERION.md` | `agents/verify/verify-criterion.md` | (same pattern) |
| P9.5 | `.pipe/p9.5/P9_5_REFLECT.md` | `agents/reflect/reflect.md` | (same pattern) |
| P10 | `.pipe/p10/P10_FORMAT_REPAIR.md` | `agents/repair/format-repair.md` | (same pattern) |
| P10 | `.pipe/p10/P10_AUTO_DIAGNOSE.md` | `agents/repair/auto-diagnose.md` | (same pattern) |
| P11 | `.pipe/p11/P11_QA_REVIEW.md` | `agents/qa/qa-review.md` | (same pattern) |
| P12 | `.pipe/p12-init.sh` | `scripts/init.sh` | `.deadf/scripts/init.sh` |
| P12 | `.pipe/p12/P12_DETECT.sh` | `scripts/init-detect.sh` | (same pattern) |
| P12 | `.pipe/p12/prompts/MAPPER_AGENT.md` | `agents/init/mapper-agent.md` | (same pattern) |
| — | `extract_plan.py` | `scripts/extract-sentinel.py` | `.deadf/scripts/extract-sentinel.py` |
| — | `build_verdict.py` | `scripts/build-verdict.py` | `.deadf/scripts/build-verdict.py` |
| — | `ralph.sh` | `scripts/ralph.sh` | `.deadf/scripts/ralph.sh` |
| — | `verify.sh` | `scripts/verify.sh` | `.deadf/scripts/verify.sh` |

### C.3 — Internal Reference Updates

All references to old paths must be updated. The contract (CLAUDE.md + .claude/) refers to agent templates and scripts by their new paths:

- CLAUDE.md action specs: `agents/select-track/pick-track.md` (not `.pipe/p3/P3_PICK_TRACK.md`)
- verify.sh: `scripts/verify.sh` (not `./verify.sh`)
- Extract sentinel: `scripts/extract-sentinel.py` (not `extract_plan.py`)

**P-numbers preserved ONLY in:** `PROMPT_OPTIMIZATION.md` (historical reference), `docs/` design artifacts, and inline comments for traceability.

### C.4 — Path Resolution Pattern

Agent templates and scripts reference files relative to their deployment location. Two modes:

- **Dev mode** (running from deadfish-cli repo): paths resolve relative to repo root
- **Deployed mode** (running in target project): paths resolve relative to `.deadf/`

Scripts use `DEADF_ROOT` env var (set by ralph/cron-kick) to resolve:
```bash
DEADF_ROOT="${DEADF_ROOT:-$(dirname "$0")/..}"  # .deadf/ in target project
AGENTS_DIR="$DEADF_ROOT/agents"
SCRIPTS_DIR="$DEADF_ROOT/scripts"
```

---

## D) Workflow Mapping

### D.1 — Phase Comparison

| Our Phase | GSD Equivalent | Conductor Equivalent | Notes |
|-----------|---------------|---------------------|-------|
| `research` (P2/P12) | `/gsd:map-codebase` + `/gsd:new-project` | `/conductor:setup` | All three: interactive setup phase that creates foundational docs. GSD: questions→research→requirements→roadmap. Conductor: product→guidelines→tech-stack→workflow. Us: brownfield detect→brainstorm→VISION/PROJECT/REQUIREMENTS/ROADMAP/STATE |
| `select-track` (P3) | Start of `/gsd:plan-phase` | `/conductor:newTrack` | GSD picks next phase; Conductor starts a track. We pick a track within the current roadmap phase. |
| `select-track` (P4) | Part of `/gsd:plan-phase` (research step) | `/conductor:newTrack` (spec generation) | GSD researches then plans. Conductor generates spec.md. We create SPEC.md via JIT spec generation. |
| `select-track` (P5) | Part of `/gsd:plan-phase` (plan step) | `/conductor:newTrack` (plan generation) | GSD creates 2-3 atomic plans. Conductor creates plan.md with phases/tasks. We create PLAN.md with 2-5 tasks. |
| `execute` (P6→P7) | `/gsd:execute-phase` | `/conductor:implement` | GSD: parallel waves, fresh context per plan, atomic commits. Conductor: sequential task execution with TDD. Us: sequential cycle-per-task with codex dispatch. |
| `execute` (P8→P9) | Part of execute (verify steps in XML plans) | `/conductor:review` (post-hoc) | GSD: inline verification in each plan. Conductor: review command after implementation. Us: deterministic verify.sh + LLM sub-agents per criterion. **Our approach is strictly stronger.** |
| `execute` (P9.5) | Summary files (SUMMARY.md) | Context sync on track completion | GSD: per-task summaries. Conductor: syncs product context after track. Us: living docs update + scratch buffer. **Our approach is most sophisticated.** |
| QA Review (P11) | `/gsd:verify-work` (UAT) + `/gsd:audit-milestone` | `/conductor:review` | GSD: human acceptance testing. Conductor: guideline review. Us: automated track-level holistic QA. **We automate what they leave manual.** |
| `complete` | `/gsd:complete-milestone` | Track completion in `tracks.md` | GSD: archive + git tag. Conductor: status update. Us: summary + notification. |

### D.2 — What GSD Does Better (and what we adopt)

1. **`/gsd:discuss-phase` (CONTEXT.md):** GSD has an explicit "capture implementation preferences" step before planning. We don't have this. The brainstorm (P2) captures high-level vision, but there's no per-track "how do you want this implemented?" session.

   **Adoption:** Add optional `CONTEXT.md` to track artifacts. During `create_spec` (P4), if operator is present (interactive/hybrid mode), prompt for implementation preferences before spec generation. In yolo mode, skip (use defaults from living docs).

2. **Fresh 200K context per task:** GSD spawns a fresh agent per plan execution, preventing context rot. Our current system reuses the orchestrator session across cycles.

   **Adoption:** Already partially adopted — we use `codex exec` for implementation (fresh context). But the orchestrator itself accumulates context. GSD's insight: the orchestrator should stay lean. Our `@import` split achieves this by loading only what's needed per cycle.

3. **Parallel execution waves:** GSD groups independent tasks and runs them in parallel.

   **Adoption:** Not applicable to our sequential verify-after-each-task model. Our tasks have implicit dependencies (each builds on the previous commit). However, we CAN parallelize verification sub-agents (already do — up to 7 parallel AC checks).

4. **Research per phase:** GSD has explicit research agents that investigate before planning.

   **Adoption:** Our P4 `create_spec` already does "search first" (Conductor-inspired). Enhance: when creating spec for a complex track, spawn a research sub-agent to investigate related patterns/libraries before the planner runs. Budget: one sub-agent, ≤5K tokens output, saved to `.deadf/tracks/<id>/RESEARCH.md`.

### D.3 — What Conductor Does Better (and what we adopt)

1. **`tracks.md` index file:** Single-file track overview with status, dates, task counts.

   **Adoption:** Add `.deadf/tracks/index.md`. Updated by orchestrator at: track selection (new entry), track completion (status update), QA review (result). Format:
   ```markdown
   # Track Index
   | ID | Name | Phase | Status | Tasks | Started | Completed |
   |----|------|-------|--------|-------|---------|-----------|
   | auth-01 | User Authentication | core | complete | 4/4 | 2026-02-01 | 2026-02-02 |
   | api-02 | REST API Layer | core | in-progress | 2/5 | 2026-02-02 | — |
   ```

2. **`metadata.json` per track:** Machine-readable track statistics.

   **Adoption:** Add `.deadf/tracks/<id>/metadata.yaml`. Written by orchestrator. Contains:
   ```yaml
   track_id: auth-01
   name: User Authentication
   phase: core
   status: complete
   started_at: "2026-02-01T10:00:00Z"
   completed_at: "2026-02-02T15:30:00Z"
   plan_base_commit: abc123
   final_commit: def456
   tasks_total: 4
   tasks_completed: 4
   total_diff_lines: 342
   verify_passes: 4
   verify_failures: 1
   qa_result: PASS
   qa_risk: LOW
   ```

3. **Smart revert:** Conductor's revert understands logical units (tracks, phases, tasks).

   **Adoption:** Our `rollback_and_escalate` already does task-level revert. Enhance: add track-level revert capability. When reverting a track: `git reset --hard <track.plan_base_commit>`, update index.md, clean up track artifacts. Expose via a new `deadf-revert` command (future, not MVP).

4. **Brownfield setup flow:** Conductor's `/conductor:setup` is an interactive session that builds foundational docs for existing codebases.

   **Adoption:** Already implemented as P12 (brownfield mapper). Our approach is more automated (parallel sub-agents scan the codebase). Conductor's is more interactive (questions about product, guidelines, workflow). **Hybrid:** Keep P12's automated scanning, but add Conductor-style prompts for WORKFLOW.md and product preferences during the brainstorm phase. The P12 `CONFIRM` step already does this partially.

### D.4 — What We Keep (Our Unique Strengths)

These are NOT present in GSD or Conductor and represent our competitive advantage:

1. **Deterministic verification (verify.sh):** Neither GSD nor Conductor has a deterministic test/lint/build gate. GSD uses inline `<verify>` tags checked by LLM. Conductor uses `/conductor:review` (LLM-only). Our verify.sh runs actual tests. **Keep as-is, fix tooling bugs.**

2. **Sentinel grammar with nonces:** Neither system has structured LLM output parsing. GSD uses XML (less strict). Conductor uses freeform markdown. Our nonce-bound sentinel blocks prevent cross-contamination and enable deterministic parsing. **Keep as-is.**

3. **3-tier error recovery (P10):** Neither system has systematic parse failure recovery. GSD retries. Conductor doesn't mention it. Our Tier 1→2→3 escalation is methodical. **Keep as-is.**

4. **Conservative verdict logic:** verify.sh FAIL always wins. Neither reference system has this principle. **Keep as-is.**

5. **Multi-model architecture:** GSD uses Claude only. Conductor uses Gemini only. We use Claude (orchestrator) + GPT-5.2 (planner) + GPT-5.2-Codex (implementer). **Keep as-is.**

6. **Living docs with budgets (P9.5):** GSD has no equivalent. Conductor syncs context but doesn't budget-constrain it. Our per-doc token budgets prevent context bloat. **Keep as-is.**

7. **Track-level QA (P11):** GSD has user acceptance testing (manual). Conductor has review (manual). Ours is automated. **Keep as-is.**

### D.5 — What We Design New

1. **`tracks/index.md`** — adopted from Conductor, adapted to our format (see D.3.1)
2. **`tracks/<id>/metadata.yaml`** — adopted from Conductor (see D.3.2)
3. **Optional per-track `CONTEXT.md`** — adopted from GSD's discuss-phase (see D.2.1)
4. **Optional per-track `RESEARCH.md`** — inspired by GSD's research agents (see D.2.4)
5. **`assemble-kick.sh`** — shared kick assembly used by both ralph and cron-kick (see F.3)
6. **`DEADF_ROOT` path resolution** — deployment-aware path resolution (see C.4)

---

## E) Adoption Matrix

### E.1 — Feature-Level Decision Table

| Feature | Source | Decision | Rationale |
|---------|--------|----------|-----------|
| `.planning/` directory | GSD | **Adapt** → `.deadf/` | Same concept, Fred's naming |
| `PROJECT.md` at root | GSD | **Adapt** → `.deadf/context/PROJECT.md` | Keep in .deadf per Fred's directive |
| `REQUIREMENTS.md` at root | GSD | **Adapt** → `.deadf/context/REQUIREMENTS.md` | Same |
| `ROADMAP.md` at root | GSD | **Adapt** → `.deadf/context/ROADMAP.md` | Same |
| `STATE.md` at root | GSD | **Skip** | We use STATE.yaml (machine-readable) |
| `research/` directory | GSD | **Adapt** → optional `RESEARCH.md` per track | We don't need a global research dir |
| Parallel execution waves | GSD | **Skip** | Our tasks are sequential by design |
| Fresh context per task | GSD | **Keep** (already have via codex exec) | Good alignment |
| Plans-as-prompts | GSD | **Keep** (already adopted in P5) | Already superior implementation |
| XML plan format | GSD | **Skip** | Our sentinel grammar is stricter |
| `discuss-phase` (CONTEXT.md) | GSD | **Adopt** | New per-track artifact, optional |
| `quick` mode | GSD | **Defer** | Useful but not MVP |
| `conductor/` directory | Conductor | **Adapt** → `.deadf/` | Same concept |
| `product.md` | Conductor | **Already have** → `.deadf/docs/PRODUCT.md` | Living doc |
| `tech-stack.md` | Conductor | **Already have** → `.deadf/docs/TECH_STACK.md` | Living doc |
| `workflow.md` | Conductor | **Already have** → `.deadf/docs/WORKFLOW.md` | Living doc |
| `product-guidelines.md` | Conductor | **Skip** | Covered by PATTERNS.md + living docs |
| `code_styleguides/` | Conductor | **Skip** | Living docs + linter config sufficient |
| `tracks.md` index | Conductor | **Adopt** → `.deadf/tracks/index.md` | New, valuable for observability |
| `tracks/<id>/metadata.json` | Conductor | **Adopt** → `metadata.yaml` | New, valuable for analytics |
| `tracks/<id>/spec.md` | Conductor | **Already have** → SPEC.md | Same concept |
| `tracks/<id>/plan.md` | Conductor | **Already have** → PLAN.md | Same concept |
| Smart revert | Conductor | **Defer** | Enhancement, not MVP |
| Brownfield setup | Conductor | **Already have** (P12) | Our automated approach is better |
| `.claude/rules/` auto-load | v1 synthesis | **Adopt** | Core invariants only (~160 lines) |
| `.claude/imports/` on-demand | v1 synthesis | **Adopt** | Action specs + grammars |
| `assemble-kick.sh` shared | v1 synthesis | **Adopt** | Unify ralph + cron-kick |
| `extract-sentinel.py` extended | v1 synthesis | **Adopt** | Fix TRACK/SPEC parsing gap |

---

## F) Contract/Tool Reconciliation

### F.1 — verify.sh (PRIORITY 1 — blocks e2e)

**Problems identified by GPT-5.2:**
1. Reads `TASK.md` from project root, but tasks live at `.deadf/tracks/<id>/tasks/TASK_NNN.md`
2. `ESTIMATED_DIFF` parsing doesn't match template format
3. File path extraction patterns don't match template format

**Fixes:**

```bash
# 1. Task file discovery (new)
# Add VERIFY_TASK_FILE env var with STATE.yaml auto-derivation fallback
TASK_FILE="${VERIFY_TASK_FILE:-}"
if [ -z "$TASK_FILE" ] && [ -f "${DEADF_ROOT}/STATE.yaml" ]; then
    TRACK_ID=$(yq '.track.id' "${DEADF_ROOT}/STATE.yaml")
    TASK_NUM=$(printf "%03d" $(yq '.track.task_current' "${DEADF_ROOT}/STATE.yaml"))
    TASK_FILE="${DEADF_ROOT}/tracks/${TRACK_ID}/tasks/TASK_${TASK_NUM}.md"
fi
# Fallback: TASK.md in project root (backward compat)
TASK_FILE="${TASK_FILE:-TASK.md}"

# 2. Dual-pattern ESTIMATED_DIFF parsing
ESTIMATED_DIFF=$(grep -oP '(?:ESTIMATED_DIFF[=:]\s*)(\d+)' "$TASK_FILE" | head -1 | grep -oP '\d+')
# Also try header format: ## ESTIMATED_DIFF\n<number>
if [ -z "$ESTIMATED_DIFF" ]; then
    ESTIMATED_DIFF=$(awk '/^## ESTIMATED_DIFF/{getline; print $1}' "$TASK_FILE")
fi

# 3. Dual-pattern file path extraction
# Pattern A: path=<bare> (current sentinel format)
# Pattern B: - path: <bare> | action: ... (template format)
PLANNED_PATHS=$(grep -oP '(?:path[=:]\s*)([^\s|]+)' "$TASK_FILE" | grep -oP '[^\s|]+$')
```

**Scope:** ~30 lines changed in verify.sh. Non-breaking (fallback preserves current behavior).

### F.2 — extract_plan.py → extract-sentinel.py (PRIORITY 2 — blocks select-track)

**Problems:**
1. Only parses PLAN blocks, not TRACK or SPEC blocks
2. No multi-task PLAN support (`TASK_COUNT` + `TASK[N]:` sections)
3. Name doesn't reflect expanded scope

**Fix strategy:**

```
extract-sentinel.py --block-type plan|track|spec|verdict|reflect|qa-review --nonce <nonce>
```

- Add `--block-type` argument (default: `plan` for backward compat)
- Per-type field validation schemas
- Multi-task PLAN: parse `TASK_COUNT` + iterate `TASK[N]:` sections
- `extract_plan.py` becomes a thin wrapper: `exec extract-sentinel.py --block-type plan "$@"`
- Golden fixture tests in `tests/fixtures/sentinels/`

**Scope:** ~200 lines new code. `extract_plan.py` preserved as deprecated wrapper.

### F.3 — ralph.sh Kick Unification (PRIORITY 3 — correctness)

**Problem:** ralph.sh constructs its own kick message that doesn't match the canonical P1 template.

**Fix:**

1. Extract kick assembly into `scripts/assemble-kick.sh`:
   ```bash
   #!/bin/bash
   # Reads P1 template, substitutes variables, outputs kick message to stdout
   # Used by both ralph.sh and cron-kick.sh
   TEMPLATE="${DEADF_ROOT}/agents/kick/cycle-kick.md"
   # ... substitute CYCLE_ID, PROJECT_PATH, MODE, TASK_LIST_ID
   ```

2. ralph.sh calls `assemble-kick.sh`:
   ```bash
   KICK_MSG=$("${SCRIPTS_DIR}/assemble-kick.sh" "$CYCLE_ID" "$PROJECT_PATH")
   timeout $DISPATCH_TIMEOUT $DISPATCH_CMD "$KICK_MSG"
   ```

3. cron-kick.sh calls `assemble-kick.sh` (same).

4. ralph.sh becomes ONLY: loop wrapper + iteration tracking + timeout detection + backoff.

**Scope:** ~50 lines new (assemble-kick.sh), ~30 lines removed from each of ralph.sh and cron-kick.sh.

### F.4 — POLICY.yaml Cleanup (PRIORITY 4 — cosmetic)

**Problem:** Contains `authority: clawdbot` and other bot-era references.

**Fix:** Search-and-replace. ~5 lines changed.

### F.5 — Path References in Agent Templates (PRIORITY 5 — must follow restructure)

Every agent template that references `.pipe/p<N>/...` must be updated to use the new `agents/...` paths. This is mechanical but touches every template file.

**Strategy:** Single commit with `sed -i` across all template files, then manual review of edge cases.

---

## G) Implementation Plan

### G.0 — Pre-flight

- [ ] Tag current state: `git tag pre-restructure-v2`
- [ ] Run `verify.sh` on a test fixture to establish baseline behavior
- [ ] Document current integration test results in `tests/results/`

### G.1 — Tool Fixes (blocks everything)

**Phase 1a: verify.sh** (~0.5 day)
- Add `VERIFY_TASK_FILE` env var + STATE.yaml auto-derivation
- Add dual-pattern parsing for ESTIMATED_DIFF and file paths
- Add `--task-file` CLI argument
- Test with golden fixtures
- Commit: `fix(verify): task file discovery and dual-pattern parsing`

**Phase 1b: extract-sentinel.py** (~1.5 days)
- Create `scripts/extract-sentinel.py` with `--block-type` support
- Implement TRACK, SPEC, multi-task PLAN parsers
- Create golden fixtures in `tests/fixtures/sentinels/`
- Create backward-compat wrapper `extract_plan.py`
- Commit: `feat(parser): unified sentinel parser with TRACK/SPEC/multi-PLAN support`

### G.2 — Launcher Unification (~0.5 day)

- Create `scripts/assemble-kick.sh`
- Update ralph.sh to call assemble-kick
- Update cron-kick.sh to call assemble-kick
- Test: both launchers produce identical kick messages
- Commit: `refactor(launcher): shared kick assembly via assemble-kick.sh`

### G.3 — CLAUDE.md Split (~1 day)

- Create `.claude/rules/` (4 files, ~160 lines total)
- Create `.claude/imports/actions/` (10 files)
- Create `.claude/imports/grammars/` (6 files)
- Create `.claude/imports/integrations/` (3 files)
- Rewrite CLAUDE.md as lean skeleton (≤250 lines)
- Verify `@import` paths work in Claude Code
- Commit: `refactor(contract): split CLAUDE.md into rules/ + imports/ (250 lines)`

### G.4 — File Restructure (~1 day)

- `git mv` all `.pipe/` files to `agents/` and `scripts/`
- `git mv` `extract_plan.py` → `scripts/extract-sentinel.py` (keep wrapper)
- `git mv` `build_verdict.py` → `scripts/build-verdict.py`
- `git mv` `ralph.sh` → `scripts/ralph.sh`
- `git mv` `verify.sh` → `scripts/verify.sh`
- `git mv` `.pipe/reviews/` → `docs/reviews/`
- `git mv` `.pipe/*-design-*.md` → `docs/analysis/`
- Remove empty `.pipe/` directory
- Commit: `refactor(structure): reorganize into agents/ scripts/ docs/`

### G.5 — Reference Updates (~0.5 day)

- Update all path references in agent templates (`.pipe/pN/` → `agents/...`)
- Update all path references in CLAUDE.md imports (already done in G.3, verify)
- Update all path references in scripts
- Update README.md
- Update PROMPT_OPTIMIZATION.md (add migration note, keep P-numbers for history)
- Commit: `refactor(refs): update all path references to new structure`

### G.6 — New Artifacts + POLICY Cleanup (~0.5 day)

- Create `.deadf/tracks/index.md` template
- Create `.deadf/tracks/<id>/metadata.yaml` template
- Add track index update logic to action specs (pick-track, reflect, qa-review)
- Add metadata.yaml write logic to action specs
- Clean POLICY.yaml of bot-era references
- Commit: `feat(tracks): add index.md and metadata.yaml; clean POLICY.yaml`

### G.7 — Validation (~0.5 day)

Run the full validation checklist:

- [ ] `wc -l CLAUDE.md` ≤ 300
- [ ] `cat .claude/rules/*.md | wc -l` ≤ 200
- [ ] `ls .claude/imports/actions/*.md | wc -l` = 10
- [ ] `ls .claude/imports/grammars/*.md | wc -l` = 6
- [ ] `ls .claude/imports/integrations/*.md | wc -l` = 3
- [ ] `ls agents/**/*.md | wc -l` ≥ 20 (all templates migrated)
- [ ] `ls scripts/*.sh scripts/*.py | wc -l` ≥ 14
- [ ] `grep -rn '\.pipe/' . --include='*.md' --include='*.sh' --include='*.py'` = 0 matches (excluding docs/)
- [ ] `grep -rn 'P[0-9]\+_' agents/ scripts/ .claude/` = 0 matches (no P-numbers in runtime files)
- [ ] `grep -rn 'clawdbot' POLICY.yaml` = 0 matches
- [ ] `python3 scripts/extract-sentinel.py --block-type plan --nonce ABC123 < tests/fixtures/sentinels/plan-valid.txt` succeeds
- [ ] `python3 scripts/extract-sentinel.py --block-type track --nonce ABC123 < tests/fixtures/sentinels/track-valid.txt` succeeds
- [ ] `VERIFY_TASK_FILE=<path> scripts/verify.sh` reads correct file
- [ ] `scripts/assemble-kick.sh <args>` produces valid kick message
- [ ] One simulated cycle completes (dry-run with fixture state)

### Timeline Summary

| Phase | Scope | Risk | Effort | Depends |
|-------|-------|------|--------|---------|
| G.0 | Baseline/tag | — | 0.5h | — |
| G.1a | verify.sh fix | HIGH | 0.5d | G.0 |
| G.1b | extract-sentinel.py | HIGH | 1.5d | G.0 |
| G.2 | Launcher unification | MEDIUM | 0.5d | G.0 |
| G.3 | CLAUDE.md split | LOW | 1d | G.1, G.2 |
| G.4 | File restructure | MEDIUM | 1d | G.3 |
| G.5 | Reference updates | LOW | 0.5d | G.4 |
| G.6 | New artifacts + cleanup | LOW | 0.5d | G.5 |
| G.7 | Validation | — | 0.5d | G.6 |

**Total: ~6 days, 8 commits**

**Key insight (from v1 synthesis, still valid):** Fix tools BEFORE restructuring files. Otherwise you fix tools at old paths then move them = double churn.

**Git strategy:** Short-lived branches per phase. `git mv` for renames (preserves history). Tag milestones.

---

## H) Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `@import` doesn't work as expected in Claude Code | LOW | HIGH | Test in Phase G.3 before committing to the architecture |
| Tool fixes break existing behavior | MEDIUM | HIGH | Golden fixture tests in G.1; backward-compat wrappers |
| Reference update misses a path | MEDIUM | LOW | `grep -rn '.pipe/'` validation in G.7 |
| Agent templates have hardcoded paths | HIGH | LOW | Mechanical `sed` + manual review |
| Deployed `.deadf/` layout confuses existing test projects | LOW | MEDIUM | Version marker in `.deadf/VERSION` (add if needed) |

---

## I) Migration Guide (for existing target projects)

If any target projects already have `.deadf/` directories from the current layout:

1. Back up: `cp -r .deadf .deadf.bak`
2. Run updated `init.sh` which handles migration:
   - Detects old layout (no `context/`, no `agents/`)
   - Moves files to new locations
   - Creates missing directories
   - Preserves STATE.yaml, POLICY.yaml, all track data
3. Verify: `deadf-validate` (new script, checks directory structure)

**Not MVP** — document the expected layout and let projects re-init. The pipeline is pre-production.

---

*Plan v2 — ready for review. Incorporates GSD's context engineering philosophy, Conductor's track/context management patterns, and our unique deterministic verification strengths.*
