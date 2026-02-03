# P2-P5 Restructure Plan — Opus Analysis

> Based on exhaustive reading of all 16 source files: deadfish pipeline (CLAUDE.md, PROMPT_OPTIMIZATION.md, P2_MAIN/F/E, METHODOLOGY, VISION, ROADMAP), GSD templates (project, requirements, roadmap, state), Conductor (newTrack, implement, workflow), and GSD discovery-phase workflow.

---

## 1. P2 Output Restructuring

### Current State
P2 outputs exactly two files:
- `VISION.md` — problem/solution/scope/metrics in YAML-in-codefence
- `ROADMAP.md` — tracks with deliverables, steps, done_when

### Problem
1. **No living product context** — VISION.md conflates "what is this" with "what are we building toward." GSD separates PROJECT.md (living context, core value, constraints, decisions) from requirements.
2. **No checkable requirements** — ROADMAP `done_when` entries are informal. No IDs, no categories, no traceability to phases, no machine-checkable format.
3. **No STATE initialization** — STATE.yaml exists but P2 doesn't initialize it with project semantics. GSD's STATE.md provides human-readable living memory.
4. **ROADMAP is too tactical** — current ROADMAP has `steps` and `deliverables` per track, which belongs in just-in-time specs (P4), not strategic roadmap.

### Proposed P2 Outputs (5 files)

| File | Purpose | Lines | Est. Tokens |
|------|---------|-------|-------------|
| `VISION.md` | Constitution — problem, solution, users, differentiators, MVP scope | ≤80 | ~300 |
| `PROJECT.md` | Living context — core value, constraints, key decisions, context | ≤80 | ~350 |
| `REQUIREMENTS.md` | Checkable requirements with IDs, categories, traceability | ≤120 | ~500 |
| `ROADMAP.md` | Strategic phases with success criteria (no task details) | ≤100 | ~400 |
| `STATE.yaml` | Machine state initialized (+ human-readable header comment) | ≤60 | ~250 |

**Total new budget: ~1,750 tokens** (current VISION+ROADMAP ≈ 650 tokens → net increase ~1,100 tokens)

### Concrete YAML Schemas

#### VISION.md (constitution — rarely changes)
```yaml
# VISION.md — {project_name}
vision:
  problem:
    why: "<why this needs to exist>"
    pain: ["<pain 1>", "<pain 2>"]
  solution:
    what: "<one-sentence pitch>"
    boundaries: "<explicit scope limits>"
  users:
    primary: "<target user>"
    environments: ["<env1>", "<env2>"]
  differentiators:
    - "<differentiator>"
  mvp_scope:
    in: ["<in-scope>"]
    out: ["<out-of-scope>"]
  success_metrics:
    - "<observable, verifiable metric>"
  non_goals:
    - "<specific non-goal>"
```

#### PROJECT.md (living context — updated throughout lifecycle)
```yaml
# PROJECT.md — {project_name}
project:
  name: "<project name>"
  description: "<2-3 sentences, current accurate description>"
  core_value: "<the ONE thing that must work>"

  constraints:
    - type: "<tech|timeline|budget|dependency|compatibility>"
      what: "<constraint>"
      why: "<rationale>"

  context: |
    <Background: tech environment, prior work, known issues.
     Updated as project evolves.>

  key_decisions:
    - decision: "<choice made>"
      rationale: "<why>"
      outcome: "pending|good|revisit"
      date: "<YYYY-MM-DD>"

  assumptions:
    - "<assumption>"
  open_questions:
    - "<unresolved question>"
```

#### REQUIREMENTS.md (checkable — feeds verification pipeline)
```yaml
# REQUIREMENTS.md — {project_name}
requirements:
  defined: "<YYYY-MM-DD>"
  core_value: "<from PROJECT.md>"

  v1:
    - id: "<CAT>-<NN>"
      category: "<category name>"
      text: "<user-centric, testable requirement>"
      phase: <phase_number>
      status: "pending|in_progress|complete|blocked"
      acceptance:
        - type: "DET|LLM"
          criterion: "<testable acceptance criterion>"

  v2:
    - id: "<CAT>-<NN>"
      category: "<category>"
      text: "<deferred requirement>"

  out_of_scope:
    - feature: "<excluded feature>"
      reason: "<why excluded>"

  coverage:
    total_v1: <N>
    mapped: <N>
    unmapped: <N>
```

#### ROADMAP.md (strategic phases — no task-level detail)
```yaml
# ROADMAP.md — {project_name}
roadmap:
  version: "<version>"
  goal: "<strategic goal>"

  phases:
    - id: <N>
      name: "<phase name>"
      goal: "<what this phase delivers>"
      depends_on: [<phase_ids>]
      requirements: ["<REQ-ID>", "<REQ-ID>"]
      success_criteria:
        - "<observable behavior — feeds verify.sh + P9>"
      estimated_tracks: <N>
      status: "not_started|in_progress|complete|deferred"

  progress:
    total_phases: <N>
    completed: <N>
    current_phase: <N>

  risks:
    - "<project-level risk>"

  definition_of_done:
    - "<overall completion criteria>"
```

#### STATE.yaml initialization (P2 adds project header)
```yaml
# STATE.yaml — initialized by P2, managed by orchestrator
project:
  name: "<project name>"
  core_value: "<from PROJECT.md>"
  initialized_at: "<ISO-8601>"

phase: "select-track"
mode: "yolo"

roadmap:
  current_phase: 1
  total_phases: <N>

track:
  id: null
  name: null
  status: null
  spec_path: null
  plan_path: null

task:
  id: null
  description: null
  sub_step: null
  files_to_load: []
  retry_count: 0
  max_retries: 3
  replan_attempted: false

loop:
  iteration: 0
  stuck_count: 0

last_good:
  commit: null
  task_id: null
  timestamp: null

last_result:
  ok: null
  details: null

budget:
  started_at: null

cycle:
  id: null
  nonce: null
  status: null
  started_at: null
  finished_at: null
```

### P2 Phase Flow Changes

P2_E (Crystallize) expands to produce:
1. Vision statement → feeds VISION.md
2. Core value + constraints + decisions → feeds PROJECT.md
3. Success truths → become REQUIREMENTS.md entries (with IDs assigned)
4. Strategic phases → feeds ROADMAP.md (phases only, no tracks/plans)
5. Non-goals/risks → split between VISION.md (non_goals) and ROADMAP.md (risks)

P2_F (Output) expands from 2 templates to 5 templates.

P2_G (Adversarial Review) reviews all 5 docs for consistency.

---

## 2. VISION.md vs PROJECT.md — The Split

### Decision: Keep Both, Clear Separation

| Aspect | VISION.md | PROJECT.md |
|--------|-----------|------------|
| **Purpose** | Constitution — why we exist | Living context — how we work |
| **Changes** | Rarely (pivot = new vision) | Frequently (decisions, context) |
| **Contains** | Problem, solution, users, scope, metrics, non-goals | Core value, constraints, decisions, assumptions, context |
| **Loaded by** | P2 brainstorm, P3 track selection, P6 task generation | P3 track selection, P4 spec creation, P7 implementation |
| **GSD equivalent** | Part of PROJECT.md (but we split it) | Part of PROJECT.md + new |
| **Token cost** | ~250 | ~350 |

### Why Not Merge?
1. **Token efficiency** — VISION.md is loaded less frequently. Only P3 needs both. P6/P7 need only PROJECT.md for constraints/decisions.
2. **Change frequency** — VISION.md is immutable during execution. PROJECT.md accumulates decisions after every track.
3. **Semantic clarity** — "What are we building?" vs "What do we know?" are distinct concerns.

### Migration from Current Format
Current VISION.md splits into:
- `problem`, `solution`, `users`, `differentiators`, `mvp_scope`, `success_metrics`, `non_goals` → stay in VISION.md
- `loop_roles` → moves to PROJECT.md `context`
- `assumptions`, `open_questions` → moves to PROJECT.md
- New: `core_value`, `constraints`, `key_decisions` → PROJECT.md (currently missing entirely)

---

## 3. REQUIREMENTS.md Design

### Verification Pipeline Integration

```
P2 brainstorm
    ↓ success truths
REQUIREMENTS.md (v1 entries with IDs + acceptance criteria)
    ↓ phase mapping
ROADMAP.md (phases reference requirement IDs)
    ↓ track selection (P3)
Track spec (P4) references requirement IDs being addressed
    ↓ plan creation (P5)
Plan tasks reference acceptance criteria (DET:/LLM: tagged)
    ↓ task generation (P6)
TASK.md ACCEPTANCE block uses requirement acceptance criteria
    ↓ verification (P8/P9)
verify.sh checks DET: criteria; LLM sub-agents check LLM: criteria
    ↓ reflect
REQUIREMENTS.md status updated (pending → in_progress → complete)
```

### Key Design Principles

1. **IDs are stable** — `AUTH-01` never changes meaning. New requirements get new IDs.
2. **Categories derived from domain** — P2 brainstorm organizes ideas into themes → themes become categories.
3. **Acceptance criteria are pre-tagged** — DET:/LLM: prefix assigned at P2 time, inherited by all downstream plans.
4. **Traceability is bidirectional** — requirement → phase (in REQUIREMENTS.md) AND phase → requirements (in ROADMAP.md).
5. **Coverage audit** — `coverage` section ensures every v1 requirement maps to a phase. Unmapped = gap.

### How Acceptance Criteria Flow to verify.sh

```
REQUIREMENTS.md:
  - id: CLI-01
    text: "User can run pipeline with single command"
    acceptance:
      - type: DET
        criterion: "ralph.sh exits 0 on successful cycle"
      - type: LLM
        criterion: "Setup-to-first-run takes ≤5 minutes following README"
```

At P5/P6 time, the planner pulls acceptance criteria from requirements and formats them as sentinel DSL:
```
ACCEPTANCE:
- id=AC1 text="DET: ralph.sh exits 0 on successful cycle"
- id=AC2 text="LLM: Setup-to-first-run takes ≤5 minutes following README"
```

This means P9 LLM verifiers can trace back: AC2 → CLI-01 → Phase 1.

### Status Lifecycle
```
pending → in_progress (when phase starts)
       → complete (when all acceptance criteria pass)
       → blocked (when external dependency blocks)
```

The `reflect` action updates REQUIREMENTS.md status when a track completes and all its requirement acceptance criteria have passed.

---

## 4. STATE.yaml vs STATE.md — Coexistence

### The Problem
- **STATE.yaml** exists: machine-readable pipeline state (phase, track, task, cycle, loop counters)
- **GSD STATE.md**: human-readable living memory (position, velocity, decisions, blockers, session continuity)
- We need both functions but can't afford two full files loaded every cycle.

### Decision: Enrich STATE.yaml, Skip STATE.md

**Rationale:**
1. STATE.yaml is already loaded every cycle (mandatory). Adding a second state file doubles state-loading cost.
2. GSD's STATE.md is designed for human-in-the-loop workflows (session continuity, "read first"). deadfish is autonomous — the orchestrator reads STATE.yaml programmatically.
3. The human-readable context GSD puts in STATE.md we can put in PROJECT.md (`key_decisions`, `context`) which is loaded less frequently.
4. Velocity/performance metrics can be computed from git history — no need to persist.

### What STATE.yaml Gains (from GSD STATE.md concepts)

```yaml
# New fields added to STATE.yaml
project:
  name: "<project name>"
  core_value: "<one-liner — quick orientation>"
  initialized_at: "<ISO-8601>"

position:
  phase: <N>
  phase_name: "<human-readable>"
  total_phases: <N>
  progress_pct: <N>  # computed: completed_phases / total_phases * 100

# Existing fields remain unchanged
```

### What We Don't Port
- Performance metrics / velocity → compute from git log on demand
- Session continuity → Claude Code's `--continue` handles this
- Pending todos → we have `.deadf/notifications/` for this
- Progress bar → `progress_pct` field is sufficient

### Relationship Diagram
```
STATE.yaml (loaded every cycle)
  ├── Machine state: phase, track, task, cycle, loop
  ├── Project header: name, core_value (from PROJECT.md at init)
  └── Position: current phase number, progress %

PROJECT.md (loaded at P3/P4/P7)
  ├── Human context: description, constraints, key_decisions
  └── Living memory: assumptions, open_questions (updated by reflect)

REQUIREMENTS.md (loaded at P3/P5/P6, updated by reflect)
  └── Requirement statuses: the "what's done" view
```

---

## 5. ROADMAP.md Restructuring

### Current Problems
1. ROADMAP has `steps` per track — too tactical for a strategic document
2. ROADMAP has `contract_updates` — implementation detail, not strategy
3. Tracks have no success criteria (only `done_when` — informal)
4. No phase grouping — flat list of tracks
5. No plan counts or progress tracking

### New Structure: GSD-Style Phases

```yaml
# ROADMAP.md — {project_name}
roadmap:
  version: "<version>"
  goal: "<strategic goal>"

  phases:
    - id: 1
      name: "Foundation"
      goal: "Core pipeline components in place and operational"
      depends_on: []
      requirements: ["CLI-01", "CLI-02", "PIPE-01"]
      success_criteria:
        - "ralph.sh completes a single cycle with exit 0"
        - "verify.sh produces valid JSON for a sample task"
        - "STATE.yaml updates atomically after each cycle step"
      estimated_tracks: 3
      status: "not_started"

    - id: 2
      name: "Contract & Loop"
      goal: "CLAUDE.md contract operational, ralph.sh driving cycles"
      depends_on: [1]
      requirements: ["ORCH-01", "ORCH-02", "LOOP-01"]
      success_criteria:
        - "Claude Code follows CLAUDE.md contract for all phases"
        - "ralph.sh runs multi-iteration loops with proper state transitions"
        - "Stuck detection triggers replan after threshold"
      estimated_tracks: 2
      status: "not_started"

  progress:
    total_phases: 4
    completed: 0
    current_phase: 1

  risks:
    - "Non-determinism from model variability"
    - "CLI permission differences causing missing artifacts"

  definition_of_done:
    - "All phase success criteria verified"
    - "README quickstart works end-to-end"
```

### Key Differences from Current

| Aspect | Current | New |
|--------|---------|-----|
| Granularity | Tracks with steps | Phases with success criteria |
| Detail level | Implementation steps, deliverables | Strategic goals, requirements |
| Track planning | Pre-planned in ROADMAP | Just-in-time at P3/P4 |
| Progress | None | Phase completion + plan counts |
| Verification link | `done_when` (informal) | `success_criteria` → requirements → acceptance → verify.sh |
| Plan counts | N/A | `estimated_tracks` (refined at P3 time) |

### What Moves Out
- `steps` → P4 spec (just-in-time)
- `deliverables` → P4 spec
- `contract_updates` → P4 spec
- `include` (readme content) → P4 spec
- `test_plan` → P5 plan / P6 task acceptance criteria

---

## 6. P3 (pick_track) Redesign

### Current State
P3 "consults GPT-5.2 planner to select next track from `tracks_remaining`" — but tracks_remaining is a flat list from ROADMAP. No phase awareness.

### New P3: Phase-Aware Track Selection

**Input context loaded:**
- STATE.yaml (current phase, position)
- ROADMAP.md (phases, success criteria, requirements)
- REQUIREMENTS.md (requirement statuses — what's done, what's not)
- VISION.md (strategic direction)
- PROJECT.md (constraints, decisions, context)

**P3 prompt structure (layered):**
```
--- ORIENTATION (0a-0c) ---
0a. Read STATE.yaml: current phase ({phase_id}: {phase_name}), progress.
0b. Read ROADMAP.md: current phase's goal, success criteria, requirements.
0c. Read REQUIREMENTS.md: status of requirements mapped to current phase.
    Which are pending? Which are complete? Which are blocked?

--- OBJECTIVE (1) ---
1. Select the next track to implement within Phase {phase_id}.
   A track is a coherent unit of work (feature, fix, refactor) that
   advances one or more requirements toward completion.

   Output a track selection in this format:
   <<<TRACK:V1:NONCE={nonce}>>>
   TRACK_ID=<bare>
   TRACK_NAME="<quoted>"
   PHASE={phase_id}
   REQUIREMENTS=[<comma-separated REQ IDs>]
   GOAL="<1-2 sentence goal>"
   ESTIMATED_TASKS=<positive integer, 2-5 recommended>
   <<<END_TRACK:NONCE={nonce}>>>

--- RULES ---
- Select work that maximizes progress on unmet success criteria.
- Prefer requirements with no blockers.
- Prefer smaller tracks (2-5 tasks) over large ones.
- If all requirements for current phase are complete, output PHASE_COMPLETE.
- If blocked on all remaining requirements, output PHASE_BLOCKED with reasons.

--- GUARDRAILS (999+) ---
99999. Output ONLY the sentinel track block. No preamble.
999999. Never select work outside current phase unless all phase requirements complete.
```

**Phase transition logic (in orchestrator, not planner):**
- If planner outputs `PHASE_COMPLETE`: verify all success criteria via verify.sh/LLM. If pass → advance `roadmap.current_phase`, update ROADMAP status. If fail → re-enter P3 with "success criteria not yet met" context.
- If planner outputs `PHASE_BLOCKED`: escalate to `needs_human`.

**STATE.yaml updates after P3:**
```yaml
track:
  id: "<TRACK_ID>"
  name: "<TRACK_NAME>"
  phase: <phase_id>
  requirements: ["<REQ-ID>", ...]
  status: "selected"
  spec_path: null
  plan_path: null
```

### Track Storage
Tracks are ephemeral. No tracks directory (unlike Conductor). Track artifacts live in:
```
.deadf/tracks/{track_id}/
├── SPEC.md       # P4 output
├── PLAN.md       # P5 output
└── tasks/        # P6 outputs (one per task)
    ├── TASK_001.md
    └── TASK_002.md
```

On track completion, `reflect` archives to `.deadf/tracks/{track_id}/COMPLETE.md` (summary only, delete spec/plan to save disk).

---

## 7. P4 (create_spec) as Just-in-Time — Conductor Pattern

### Conductor's Key Insight
Conductor generates spec + plan interactively at track start, NOT upfront during roadmap creation. This means:
1. Specs reflect current codebase state (not stale assumptions)
2. Specs can reference actual files, APIs, patterns discovered by searching
3. Context is fresh — no drift between planning and execution

### P4 Prompt Structure

**Input context loaded:**
- STATE.yaml (track info, phase)
- ROADMAP.md (current phase success criteria)
- REQUIREMENTS.md (requirements being addressed by this track)
- PROJECT.md (constraints, decisions, context)
- OPS.md (if exists — build/test/lint commands)
- Codebase search results (rg/find for related code)

```
--- ORIENTATION (0a-0c) ---
0a. Read STATE.yaml: track "{track.name}" targeting requirements [{track.requirements}].
0b. Read REQUIREMENTS.md: full text + acceptance criteria for each targeted requirement.
0c. Search codebase for existing implementations related to this track.
    List what exists. Do NOT assume anything is missing.
    Read OPS.md for build/test/lint commands.

--- OBJECTIVE (1) ---
1. Generate a track specification for "{track.name}".
   This spec defines WHAT to build, not HOW (that's the plan).

   Output format:
   <<<SPEC:V1:NONCE={nonce}>>>
   TRACK_ID={track.id}
   TITLE="<quoted>"
   OVERVIEW=
     <2-space indented: what this track delivers, 3-5 sentences>
   REQUIREMENTS:
   - id=<REQ-ID> text="<requirement text>"
   FUNCTIONAL:
   - id=FR<n> text="<functional requirement>"
   NON_FUNCTIONAL:
   - id=NFR<n> text="<non-functional requirement>"
   ACCEPTANCE_CRITERIA:
   - id=AC<n> req=<REQ-ID> text="<DET:|LLM: testable criterion>"
   OUT_OF_SCOPE:
   - "<what this track does NOT do>"
   EXISTING_CODE:
   - path=<file> relevance="<how it relates>"
   <<<END_SPEC:NONCE={nonce}>>>

--- RULES ---
- Every acceptance criterion must trace to a requirement ID.
- Tag each criterion DET: or LLM: per the convention.
- Include ALL existing code that will be modified or referenced.
- Keep scope tight: 2-5 tasks worth of work.
- Functional requirements should be atomic and testable.

--- GUARDRAILS (999+) ---
99999. Output ONLY the sentinel spec block. No preamble.
999999. Do not hallucinate files that don't exist. Use search results.
9999999. Acceptance criteria must be verifiable — no vague verbs.
```

**Key adaptation from Conductor:**
- Conductor uses interactive Q&A to build spec. We can't (autonomous pipeline).
- Instead, we frontload codebase search (0c) to get the context Conductor gets via questions.
- The planner has full requirement text + acceptance criteria from REQUIREMENTS.md.

**STATE.yaml updates after P4:**
```yaml
track:
  spec_path: ".deadf/tracks/{track_id}/SPEC.md"
  status: "spec-ready"
```

---

## 8. P5 (create_plan) as Plans-as-Prompts — GSD Pattern

### GSD's Core Insight
> "Plans ARE prompts — no transformation step between plan and execution prompt."

This means the plan P5 produces should be directly consumable by P6 (generate_task) and P7 (implement_task) without transformation. Each plan entry is a micro-prompt.

### P5 Prompt Structure

**Input context loaded:**
- STATE.yaml (track info)
- Track SPEC.md (from P4)
- PROJECT.md (constraints)
- OPS.md (build/test commands)

```
--- ORIENTATION (0a-0c) ---
0a. Read STATE.yaml: track "{track.name}", phase {track.phase}.
0b. Read SPEC.md at {track.spec_path}. Understand all acceptance criteria.
0c. Read PROJECT.md constraints. Read OPS.md for build/test/lint commands.

--- OBJECTIVE (1) ---
1. Generate an implementation plan for track "{track.name}".
   The plan is a sequence of 2-5 atomic tasks.
   Each task IS a prompt — it will be fed directly to the implementer.

   Output format:
   <<<PLAN:V1:NONCE={nonce}>>>
   TRACK_ID={track.id}
   TASK_COUNT=<N>

   TASK[1]:
   TASK_ID={track.id}-T01
   TITLE="<quoted>"
   SUMMARY=
     <2-space indented: what to implement, 2-3 sentences>
   FILES:
   - path=<bare> action=<add|modify|delete> rationale="<quoted>"
   ACCEPTANCE:
   - id=AC<n> text="<DET:|LLM: testable criterion>"
   ESTIMATED_DIFF=<positive integer>
   DEPENDS_ON=[]

   TASK[2]:
   TASK_ID={track.id}-T02
   ...

   <<<END_PLAN:NONCE={nonce}>>>

--- RULES ---
- 2-5 tasks per track. Each task ≤200 diff lines.
- Tasks execute sequentially. Later tasks can depend on earlier ones.
- Each task must have ≥1 DET: criterion (tests pass) and ≥1 meaningful criterion.
- FILES ≤5 per task unless strictly necessary.
- SUMMARY is the implementer's prompt. Write it as instructions.
- ESTIMATED_DIFF calibrated to smallest plausible implementation.
- Acceptance criteria inherited from SPEC.md, distributed across tasks.
- Every SPEC.md acceptance criterion must appear in exactly one task.

--- GUARDRAILS (999+) ---
99999. Output ONLY the sentinel plan block. No preamble.
999999. Plans are prompts. SUMMARY must be actionable, not descriptive.
9999999. No vague acceptance criteria. Every AC must have a clear pass/fail.
```

### Plans-as-Prompts: What This Means Concretely

The SUMMARY field in each task IS the implementation prompt. When P6 (generate_task) fires, it wraps this SUMMARY into the layered prompt structure (0a-0c / 1 / 999+) and sends it to the implementer. No transformation needed.

Example SUMMARY that IS a prompt:
```
SUMMARY=
  Implement the CLI entry point at src/cli.py. Create an argparse-based
  CLI that accepts: --project (required, path), --mode (optional, default yolo),
  --max-iterations (optional, default 100). Import and call ralph_loop() from
  src/ralph.py. Add a __main__.py that delegates to cli.main().
  Write pytest tests in tests/test_cli.py covering: missing --project exits 1,
  valid args returns 0, --help prints usage text.
```

This is directly executable by gpt-5.2-codex without any prompt transformation.

### P5 Output Storage
```
.deadf/tracks/{track_id}/PLAN.md   # Full sentinel plan block
.deadf/tracks/{track_id}/tasks/    # Individual TASK.md files extracted by extract_plan.py
```

**STATE.yaml updates after P5:**
```yaml
track:
  plan_path: ".deadf/tracks/{track_id}/PLAN.md"
  status: "planned"
  task_count: <N>
  task_current: 1
phase: "execute"
task:
  sub_step: "generate"
```

---

## 9. Token Budget Analysis

### Current Budget (from CLAUDE.md)
- `task.files_to_load` cap: <3,000 tokens
- OPS.md: <60 lines (~300 tokens)
- STATE.yaml: ~250 tokens
- POLICY.yaml: ~200 tokens
- TASK.md: ~200 tokens
- CLAUDE.md: ~5,000 tokens (loaded implicitly as system prompt)

### Per-Phase Loading Requirements

| Phase | Files Loaded | Est. Tokens |
|-------|-------------|-------------|
| **P3 (pick_track)** | STATE.yaml (250) + ROADMAP (400) + REQUIREMENTS (500) + VISION (250) + PROJECT (350) | **~1,750** |
| **P4 (create_spec)** | STATE.yaml (250) + ROADMAP (200, current phase only) + REQUIREMENTS (300, relevant reqs only) + PROJECT (350) + OPS (300) + codebase search results (~500) | **~1,900** |
| **P5 (create_plan)** | STATE.yaml (250) + SPEC.md (400) + PROJECT (350) + OPS (300) | **~1,300** |
| **P6 (generate_task)** | STATE.yaml (250) + PLAN.md (current task, ~200) + OPS (300) + task.files_to_load (<3000) | **~3,750** |
| **P7 (implement_task)** | STATE.yaml (250) + TASK.md (200) + OPS (300) + task.files_to_load (<3000) | **~3,750** |

### Comparison to Current
Current P3-P5 would load STATE.yaml + ROADMAP + VISION ≈ 900 tokens.
New P3 loads ≈ 1,750 tokens (+850). But P3 runs once per track, not per cycle.

**P6/P7 (the hot loop) are unchanged** — they load TASK.md + files, not the full doc set. This is the critical path for token budget.

### Mitigation Strategies
1. **Selective loading** — P4 loads only the current phase from ROADMAP and relevant requirements from REQUIREMENTS.md, not the full files.
2. **VISION.md loaded only at P3** — not in the hot loop.
3. **PROJECT.md loaded at P3/P4/P7** — but P7 only needs constraints section (~100 tokens).
4. **REQUIREMENTS.md never loaded in hot loop** — only P3 and P4.

### Verdict: Fits Within Budget ✅
The new file set adds ~1,100 tokens to P3 (one-time per track). The hot loop (P6/P7) is **unaffected**. Total context usage stays well under GPT-5.2's window. The key insight: strategic docs are loaded at strategic moments, not every cycle.

---

## 10. Implementation Micro-Tasks

### Task Order (Dependency Chain)

```
T01 → T02 → T03 → T04 → T05 → T06 → T07 → T08 → T09 → T10
```

### T01: Create PROJECT.md Template
**Files:** `.pipe/p2/P2_PROJECT_TEMPLATE.md` (new)
**Action:** Write the PROJECT.md YAML schema template that P2_F will use to generate PROJECT.md. Include field descriptions, constraints, examples.
**Done when:** Template file exists with all fields from Section 1 schema.

### T02: Create REQUIREMENTS.md Template
**Files:** `.pipe/p2/P2_REQUIREMENTS_TEMPLATE.md` (new)
**Action:** Write the REQUIREMENTS.md YAML schema template. Include ID format rules, category derivation guidelines, DET:/LLM: tagging rules, traceability table format.
**Done when:** Template file exists with all fields from Section 3 schema.

### T03: Restructure ROADMAP.md Template
**Files:** `.pipe/p2/P2_ROADMAP_TEMPLATE.md` (new, replaces ROADMAP section in P2_F)
**Action:** Write the new ROADMAP.md template with GSD-style phases, success criteria, requirement references, progress tracking. Remove `steps`, `deliverables`, `contract_updates` fields.
**Done when:** Template reflects Section 5 schema. No track-level detail in roadmap.

### T04: Update P2_E (Crystallize) for New Outputs
**Files:** `.pipe/p2/P2_E.md` (modify)
**Action:** Expand crystallize phase to extract: core value, constraints, key decisions (for PROJECT.md), categorized requirements with IDs (for REQUIREMENTS.md), strategic phases with success criteria (for ROADMAP.md). Current items 1-6 restructured to feed 5 output files.
**Done when:** P2_E produces structured data for all 5 output files.

### T05: Update P2_F (Output Writer) for 5 Files
**Files:** `.pipe/p2/P2_F.md` (modify)
**Action:** Expand P2_F from 2 templates (VISION + ROADMAP) to 5 templates (VISION + PROJECT + REQUIREMENTS + ROADMAP + STATE.yaml init). Include line limits and token budgets for each.
**Done when:** P2_F contains all 5 templates with YAML schemas matching Section 1.

### T06: Update P2_MAIN Flow
**Files:** `.pipe/p2/P2_MAIN.md` (modify)
**Action:** Update Phase 5 (Crystallize) and Phase 6 (Output) references to account for 5 output files. Ensure adversarial review (Phase 7) covers all 5 docs. Update P2_DONE marker creation.
**Done when:** P2_MAIN references all 5 outputs in correct phases.

### T07: Create P3 Track Selection Prompt
**Files:** `.pipe/p3/P3_PICK_TRACK.md` (new)
**Action:** Write the P3 prompt per Section 6 design. Include sentinel TRACK block format, phase-aware selection logic, PHASE_COMPLETE/PHASE_BLOCKED outputs. Add to extract_plan.py the TRACK sentinel parser.
**Done when:** P3 prompt exists with layered structure (0a/1/999+). Sentinel format documented.

### T08: Create P4 Spec Generation Prompt
**Files:** `.pipe/p4/P4_CREATE_SPEC.md` (new)
**Action:** Write the P4 just-in-time spec prompt per Section 7 design. Include sentinel SPEC block format, codebase search instructions, requirement tracing. Add to extract_plan.py the SPEC sentinel parser.
**Done when:** P4 prompt exists. SPEC sentinel format documented and parseable.

### T09: Create P5 Plan Generation Prompt
**Files:** `.pipe/p5/P5_CREATE_PLAN.md` (new)
**Action:** Write the P5 plans-as-prompts prompt per Section 8 design. PLAN sentinel already exists — ensure new format includes TASK_COUNT, DEPENDS_ON, and plans-as-prompts SUMMARY style. Verify backward compatibility with extract_plan.py.
**Done when:** P5 prompt exists. Plan blocks generate directly-executable task summaries.

### T10: Update CLAUDE.md Action Specifications
**Files:** `CLAUDE.md` (modify)
**Action:** Update `seed_docs`, `pick_track`, `create_spec`, `create_plan` action specifications to reference new file paths, sentinel formats, and loading requirements. Update DECIDE table if needed (probably unchanged — phase/sub_step logic is the same). Add `.deadf/tracks/` directory structure.
**Done when:** CLAUDE.md action specs match the new P3-P5 flow. All file paths and sentinel formats consistent.

### Dependency Notes
- T01-T03 are independent (can parallelize)
- T04 depends on T01-T03 (needs templates to reference)
- T05 depends on T01-T03 (needs templates to embed)
- T06 depends on T04-T05
- T07-T09 are independent of T01-T06 (different files) but logically follow
- T10 depends on T07-T09 (needs final sentinel formats)

### Optional Follow-Up Tasks (not blocking)
- **T11:** Update extract_plan.py to parse TRACK and SPEC sentinel blocks
- **T12:** Update PROMPT_OPTIMIZATION.md to reflect new P3-P5 status
- **T13:** Create `.deadf/tracks/` directory structure and .gitkeep
- **T14:** Write migration guide for existing VISION.md/ROADMAP.md → new format
- **T15:** Update METHODOLOGY.md to reference new file set

---

## Summary of Key Decisions

| # | Decision | Rationale |
|---|----------|-----------|
| 1 | Split VISION.md and PROJECT.md (don't merge) | Different change frequencies, different loading moments, clearer semantics |
| 2 | Skip STATE.md, enrich STATE.yaml | Autonomous pipeline doesn't need human-readable state file; avoid duplicate state |
| 3 | ROADMAP.md = phases only, no tracks | Tracks are just-in-time (P3/P4), roadmap stays strategic |
| 4 | REQUIREMENTS.md with DET:/LLM: pre-tagging | Acceptance criteria tagged at P2 time, inherited downstream — no re-classification needed |
| 5 | P3 outputs sentinel TRACK block | Consistent with pipeline's sentinel DSL; parseable by extract_plan.py |
| 6 | P4 = Conductor's newTrack adapted for autonomous use | Codebase search replaces interactive Q&A; requirement tracing replaces user input |
| 7 | P5 SUMMARY = implementation prompt (plans-as-prompts) | GSD's key insight; eliminates transformation step between plan and execution |
| 8 | Track artifacts in `.deadf/tracks/{id}/` | Ephemeral, per-track, archived on completion — not polluting project root |
| 9 | Hot loop (P6/P7) token budget unchanged | New docs loaded at P3/P4 (one-time), not every cycle |
| 10 | 10 micro-tasks, partially parallelizable | T01-T03 parallel, T07-T09 parallel, T04-T06 sequential, T10 last |
