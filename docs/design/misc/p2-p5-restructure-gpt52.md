# P2→P5 Restructure (deadf(ish) / deadfish-cli) — GPT‑5.2 Planner Design

Goal: extend (not break) the current deadf(ish) pipeline so that:
- **P2** outputs the missing “living product context” artifacts (GSD-style) in a compact, machine-friendly way.
- **ROADMAP stays strategic** (phases/themes + observable success criteria), not an implementation task list.
- **P3–P5 become Conductor‑style** “just‑in‑time track creation”: pick a track, generate a tight track spec, then generate a tight per‑track plan **only when that track is selected**.
- **Token budgets stay tight**: global docs are small; per‑track docs “bundle” only what’s needed so P6/P7 don’t need to reload everything.
- **Plans are prompts**: the per‑track plan is already in “implementer‑ready” task prompt form (Sentinel DSL), minimizing downstream transformation.

This design is based on the current pipeline contract (`CLAUDE.md`), current P2 prompt + formats (`.pipe/p2/*`), deadf(ish) methodology (`METHODOLOGY.md`), the example `VISION.md`/`ROADMAP.md`, GSD templates (PROJECT/REQUIREMENTS/ROADMAP/STATE), and Conductor’s track creation + implement workflow.

---

## 1) What P2 Should Output After Restructuring (Files + Schemas)

### P2 outputs (project root)

P2 should produce **five** project docs plus the existing brainstorm ledger:

1. `VISION.md` *(constitution; rarely changes)* — compact YAML, stable intent
2. `PROJECT.md` *(living product context; changes over time)* — compact YAML, “core value / constraints / decisions”
3. `REQUIREMENTS.md` *(checkable requirements + IDs + traceability)* — compact YAML, requirement registry
4. `ROADMAP.md` *(strategic phases; success criteria; requirement coverage)* — compact YAML, phase map
5. `STATE.md` *(human+LLM “project memory” digest)* — **short markdown** (≤100 lines)
6. `.deadf/seed/P2_BRAINSTORM.md` *(raw ledger; already exists today)*
7. `.deadf/seed/P2_DONE` *(marker; already exists today)*

Why five docs (and not more): each doc has a distinct job, and **P3–P5 can load only what they need**. P6/P7 should not need to load all five.

### VISION.md schema (keep YAML-in-codefence; tighten naming)

`VISION.md` stays a constitution-level statement. It should not accumulate “operational” drift.

```yaml
vision_yaml<=300t:
  problem:
    why: "<why this needs to exist>"
    pain: ["<pain 1>", "<pain 2>"]
  solution:
    what: "<one-sentence pitch>"
    boundaries: "<explicit scope limits>"
  users:
    primary: "<target user>"
    environments: ["<env1>", "<env2>"]
  key_differentiators:
    - "<differentiator>"
  mvp_scope:
    in: ["<in-scope item>"]
    out: ["<explicitly excluded>"]
  success_metrics:
    - "<observable, verifiable metric>"
  non_goals:
    - "<specific non-goal>"
  assumptions:
    - "<assumption>"
  open_questions:
    - "<unresolved question>"
```

Notes:
- The existing deadfish-cli `VISION.md` includes “loop_roles”; that belongs in `PROJECT.md` context, not VISION.

### PROJECT.md schema (YAML-in-codefence; “living context”)

`PROJECT.md` is the GSD “PROJECT.md” equivalent: current product truth + constraints + decisions.

```yaml
project_yaml<=450t:
  name: "<project name>"
  what_this_is: "<2-3 sentences: current accurate description>"
  core_value: "<the ONE thing that must work>"

  constraints:
    - type: "<tech|timeline|budget|dependency|compatibility|security|legal>"
      what: "<constraint>"
      why: "<rationale>"

  context:
    - "<background fact that informs implementation>"
  out_of_scope:
    - "<boundary> — <why>"

  key_decisions:
    - id: "DEC-001"
      decision: "<choice>"
      rationale: "<why>"
      outcome: "pending|good|revisit"
      date: "<YYYY-MM-DD>"

  glossary:
    - term: "<term>"
      meaning: "<1 sentence>"

  open_questions:
    - id: "Q-001"
      question: "<open question>"
      owner: "<human|planner|orchestrator>"
      status: "open|closed"
```

Design intent:
- Keep this “high signal / low drift”: constraints + decisions + glossary + open questions.
- Do **not** put roadmap/phase details here.

### REQUIREMENTS.md schema (YAML-in-codefence; IDs + verification + traceability)

This is the primary missing artifact today: **IDs + checkability + traceability**.

```yaml
requirements_yaml<=700t:
  defined: "<YYYY-MM-DD>"
  project: "<project name>"
  core_value: "<copy from PROJECT.md core_value>"

  id_rules:
    format: "<PREFIX>-<NN>"              # e.g., CLI-01, ORCH-02
    prefixes: ["<PREFIX>", "<PREFIX>"]   # short, stable

  v1:
    - id: "CLI-01"
      title: "<short name>"
      text: "<user-centric, atomic, testable requirement>"
      priority: "must|should|could"
      phase: "P1"                # roadmap phase ID (string to avoid renumber churn)
      status: "pending|in_progress|complete|blocked"
      verification:
        # IMPORTANT: this is NOT the same as DET:/LLM: task acceptance tagging.
        # This is requirement-level “how we know it’s true”.
        signals:
          - kind: "automated_test"
            evidence: "<what passing tests prove>"
          - kind: "cli_output"
            command: "<example command>"
            expect: "<expected output pattern>"
          - kind: "doc"
            path: "<doc path>"
            expect: "<what must be present>"
      notes: "<optional>"

  v2:
    - id: "CLI-90"
      title: "<deferred requirement>"
      text: "<deferred requirement text>"

  out_of_scope:
    - feature: "<excluded thing>"
      reason: "<why>"

  traceability:
    # Bidirectional anchors. Track IDs are generated later (P3).
    # Phase mapping should be complete for v1.
    coverage:
      v1_total: <int>
      v1_mapped_to_phases: <int>
      v1_unmapped: <int>
```

Hard rules:
- IDs are stable; changing meaning requires a new ID.
- Every **v1** requirement must map to exactly one roadmap phase (`phase: "P1"` etc); unmapped = a planning gap.
- Requirement text must be checkable (no “improve”, “optimize”, “user-friendly” without observable criteria).

### ROADMAP.md schema (YAML-in-codefence; phases/themes only)

ROADMAP becomes a strategic phase map. **No “steps”, no “task lists”, no “implementation instructions”.**

```yaml
roadmap_yaml<=550t:
  version: "<semver or date>"
  project: "<project name>"
  goal: "<strategic goal>"

  phases:
    - id: "P1"
      name: "<phase name>"
      goal: "<what this phase delivers>"
      depends_on: []              # ["P0"] etc
      requirement_ids: ["CLI-01", "ORCH-01"]
      success_criteria:
        - "<observable, verifiable statement>"
      risks: ["<risk>"]
      status: "not_started|in_progress|complete|blocked|deferred"

  definition_of_done:
    - "<project-level completion truth>"
```

Important: `success_criteria` must be written so they can be verified by:
- deterministic checks (tests/lint/diff/secrets/git clean) **and/or**
- LLM verifier with evidence bundle **and/or**
- human manual verification (only if mode requires).

### STATE.md schema (short markdown digest; separate from STATE.yaml)

We already have `STATE.yaml` (pipeline machine state). This **STATE.md is not that**.

This is the GSD “living memory” equivalent, but kept extremely small and written for:
- planner/orchestrator quick orientation (especially after context compaction),
- humans when debugging or approving track boundaries.

```markdown
# Project State (Digest)

## References
- Project: PROJECT.md (last updated YYYY-MM-DD)
- Vision: VISION.md (rarely changes)
- Requirements: REQUIREMENTS.md
- Roadmap: ROADMAP.md

## Now
- Current phase: P1 — <phase name>
- Current track: <track_id> — <track name> (status: selected|spec_ready|planned|in_progress|complete)
- Last completed: <track_id> on YYYY-MM-DD

## Decisions (recent)
- DEC-001: <decision summary> (outcome: pending|good|revisit)

## Blockers / Risks (active)
- <one-liner>

## Next
- Next success criteria to satisfy: <1-3 bullets>
```

Strict constraint: keep under 100 lines. It’s a **digest**, not an archive.

---

## 2) How Existing VISION.md Maps to the New Structure

Decision: **keep `VISION.md` and add `PROJECT.md`** (do not merge).

Mapping from current deadfish-cli `VISION.md` fields:
- `problem`, `solution.what`, `users`, `mvp_scope`, `success_metrics`, `non_goals`, `assumptions`, `open_questions`
  - stay in `VISION.md` (same semantics)
- `solution.loop_roles`, and “how this pipeline works” detail
  - move to `PROJECT.md.project.context` (living context)
- `key_differentiators_vs_deadfish_pipeline`
  - split:
    - stable differentiators → `VISION.md.key_differentiators`
    - operational notes → `PROJECT.md.project.context`

Why keep separate:
- `VISION.md` is constitution; `PROJECT.md` is living drift.
- Token budgets: many phases only need `PROJECT.md` + per-track spec; not always VISION.

---

## 3) REQUIREMENTS.md Design (Integration With Verification Pipeline)

### The key integration points

We need traceability and checkability without breaking the existing verifier contract:
- `verify.sh` only evaluates its **6 deterministic checks**.
- task acceptance criteria use **DET:/LLM:** prefixes to control LLM verification.
- requirement completion is a higher-level notion than a single task; it must be **derived** from task/track outcomes and evidence.

### Required cross-links

1. **ROADMAP phase → requirements**
   - `ROADMAP.md.phases[*].requirement_ids[]` references requirement IDs.
2. **Track spec → requirement IDs**
   - P4 spec lists the subset of requirements addressed by the track.
3. **Task plans → requirement IDs**
   - P5 plan ensures every task is linked to requirement IDs it advances.

### How requirements connect to task acceptance criteria (recommended minimal change)

Keep the current Sentinel `PLAN:V1` grammar working; extend it *compatibly*:

Option A (no parser changes; lowest risk):
- Embed requirement references directly in acceptance text:
  - `text="LLM: [REQ CLI-01] CLI help output matches README examples"`

Option B (small parser extension; better automation):
- Add an optional top-level section to task plan blocks:
  - `REQUIREMENTS:`
  - `- id=CLI-01`
  - `- id=ORCH-02`
- Update `extract_plan.py` allowlist to accept `REQUIREMENTS` and parse it into JSON.
- `verify.sh` does **not** need to read this; it remains LLM/planner/orchestrator metadata.

Recommendation: **Option B**, because it enables deterministic doc updates (marking requirement status) without LLM string parsing.

### Requirement status update policy (reflect-time)

On track completion (after all tasks in the track have passed verification):
- Mark each targeted requirement:
  - `pending → in_progress` when the first track touching it starts
  - `in_progress → complete` only when the track’s *track-level* acceptance criteria are satisfied
  - `blocked` only with explicit reason in `STATE.md` + `.deadf/notifications/`

Important: requirement completion should not be inferred from a single task passing unless the track spec explicitly states that requirement is fully covered.

---

## 4) STATE.md vs STATE.yaml (We Already Have STATE.yaml)

### Relationship

- `STATE.yaml`: **pipeline machine state** (phase/sub_step/cycle nonce/task pointers). Always loaded every cycle.
- `STATE.md`: **project digest** (human/LLM “memory”). Loaded only in planning phases (P3–P5) and during track boundary approvals.

### Why both are needed (and how to keep budgets tight)

GSD’s `STATE.md` solves “session continuity”. deadf(ish) already has machine continuity via `STATE.yaml`, but planners still need:
- last decisions,
- current phase intent,
- what success criteria are still unmet,
- what’s blocked (and why).

Keeping `STATE.md` under 100 lines makes it cheap to load, and avoids bloating `STATE.yaml` with human prose.

### Proposed linkage fields (in STATE.yaml)

Add stable pointers so orchestrator/planner know where to look:

```yaml
docs:
  vision: "VISION.md"
  project: "PROJECT.md"
  requirements: "REQUIREMENTS.md"
  roadmap: "ROADMAP.md"
  digest: "STATE.md"
tracks:
  dir: "tracks"    # where per-track artifacts live
```

This is additive: existing pipelines can ignore it.

---

## 5) How P3 (pick_track) Changes

### Today
`pick_track` is described in contract only and assumes `tracks_remaining` exists.

### New behavior
P3 becomes a Conductor-style “select the next unit of work + create a track envelope”.

Inputs P3 must load:
- `STATE.yaml` (current phase; what’s already done; mode)
- `ROADMAP.md` (current phase success criteria + requirement IDs)
- `REQUIREMENTS.md` (statuses + verification hints)
- `PROJECT.md` (constraints and decisions)
- `STATE.md` (digest; optional but recommended)

Outputs P3 must produce (deterministically parseable):
- Track selection record (machine-parsed)
- Track directory skeleton (created by orchestrator scripts, not by LLM)

### P3 output contract (sentinel block)

Introduce a new sentinel block type, parsed by a new tiny parser (`extract_track.py`):

```text
<<<TRACK:V1:NONCE={nonce}>>>
TRACK_ID=<bare>                     # e.g., P1T03
NAME="<quoted>"
PHASE_ID=<bare>                     # e.g., P1
REQUIREMENT_IDS=[CLI-01,ORCH-02]
GOAL="<quoted 1-2 sentences>"
SUCCESS_CRITERIA:
- "<observable criterion>"
- "<observable criterion>"
RISKS:
- "<risk>"
ESTIMATED_TASKS=<int>               # target 2-5
<<<END_TRACK:NONCE={nonce}>>>
```

Decision rules for P3:
- Prefer tracks that satisfy the phase’s remaining `success_criteria`.
- Prefer smaller scopes (2–5 tasks).
- Prefer requirements that are not blocked.
- If all requirements in phase are complete, output a `PHASE_COMPLETE` marker instead of a TRACK block (separate sentinel type or a field).

### Track artifact layout

Use a Conductor-like directory so we can load *track-local* docs later without reloading the global set:

```
tracks/
  P1T03/
    TRACK.md        # brief (output of P3; tight)
    SPEC.md         # just-in-time spec (P4)
    PLAN.md         # just-in-time per-track plan (P5)
    NOTES.md        # optional (operator / orchestrator notes)
```

`TRACK.md` should be short and mostly a pointer:
- selected requirements (copied text snippets),
- which roadmap success criteria it targets,
- constraints that matter.

---

## 6) How P4 (create_spec) Becomes Conductor-Style Just-in-Time Spec

P4 generates `tracks/<track_id>/SPEC.md`.

Inputs P4 must load:
- `tracks/<track_id>/TRACK.md` (selected requirements + intent)
- `PROJECT.md` (constraints/decisions)
- (optional) `REQUIREMENTS.md` entries referenced by TRACK.md (only those IDs, not whole file)
- (optional) targeted code context via search results (the orchestrator can provide a small “evidence bundle”: file list + brief snippets or `rg` hits)

P4 output spec must define **WHAT**, not a task list.

### SPEC.md schema (YAML-in-codefence; track-local, compact)

```yaml
spec_yaml<=650t:
  track:
    id: "<track_id>"
    name: "<track name>"
    phase_id: "<P#>"
    requirement_ids: ["CLI-01", "ORCH-02"]

  problem: "<why this track exists now>"
  in_scope:
    - "<scope item>"
  out_of_scope:
    - "<explicit non-scope item>"

  acceptance_criteria:
    # Track-level acceptance criteria. These are not task ACs; they are end-state truths.
    - id: "TAC-01"
      text: "<observable, verifiable truth>"
      verification_hint: "<tests|cli command|doc check|manual>"

  constraints:
    - "<copied from PROJECT.md if relevant>"

  open_questions:
    - "<question blocking spec completeness>"

  existing_code:
    # Only if relevant; must be grounded in actual search results.
    - path: "<file path>"
      relevance: "<1 line>"
```

Conductor-style “interactive questions” adaptation:
- In `interactive` / `hybrid` modes, if P4 has unresolved questions that materially affect scope, it should emit a small `QUESTIONS` list and the orchestrator should set `phase: needs_human` until answered.
- In `yolo`, P4 must pick defaults, but record assumptions in `SPEC.md.open_questions` (marked as “assumed”).

---

## 7) How P5 (create_plan) Produces Sentinel DSL Plans-as-Prompts

P5 generates `tracks/<track_id>/PLAN.md` as a **sequence of atomic task prompts**, each already in the existing `PLAN:V1` sentinel DSL (one block per task).

This aligns with:
- GSD: plans are prompts (each task plan is the implementer prompt)
- Conductor: per-track plan lives next to per-track spec
- deadf(ish): Sentinel DSL + `extract_plan.py` already exists

### PLAN.md format (multi-block sentinel; requires a small extractor enhancement)

`PLAN.md` contains:
- a small header (non-parsed)
- N repeated `<<<PLAN:V1:NONCE=...>>>` blocks, each representing one commit-sized task

Each task plan block should:
- include only ≤5 files when possible,
- include acceptance criteria (DET:/LLM:),
- include `REQUIREMENTS` references (Option B above) for traceability.

Example task block (one of many in PLAN.md):

```text
<<<PLAN:V1:NONCE={nonce}>>>
TASK_ID=P1T03-T01
TITLE="..."
SUMMARY=
  <this is the implementer prompt; imperative, concrete>
REQUIREMENTS:
- id=CLI-01
FILES:
- path=... action=... rationale="..."
ACCEPTANCE:
- id=AC1 text="DET: All tests pass"
- id=AC2 text="LLM: [REQ CLI-01] ... observable behavior ..."
ESTIMATED_DIFF=120
<<<END_PLAN:NONCE={nonce}>>>
```

### Minimal downstream change to support multi-task PLAN.md

Extend `extract_plan.py` (or add `extract_plan_n.py`) so orchestrator can do:
- “extract the **next** plan block” from `tracks/<track_id>/PLAN.md`,
- write that into `TASK.md`,
- proceed with P7/P8 unchanged.

If we want **zero changes** to `extract_plan.py`, fallback is:
- P5 writes `tracks/<track_id>/tasks/TASK_001.md` etc directly (already in TASK.md format),
- and P6 becomes “select next task file”.
But the request explicitly wants “sentinel DSL plans-as-prompts”, so the multi-block PLAN.md approach is preferred.

---

## 8) Modifications Needed to Existing Files (Contract, Scripts, Prompts)

### `CLAUDE.md` (contract)

Update:
- `seed_docs` success condition: require `PROJECT.md`, `REQUIREMENTS.md`, `STATE.md` in addition to `VISION.md` + `ROADMAP.md`.
- `pick_track`: specify reading ROADMAP phases + REQUIREMENTS statuses, output TRACK sentinel, create `tracks/<track_id>/` envelope.
- `create_spec`: write `tracks/<track_id>/SPEC.md` (track-local) using P4 prompt template.
- `create_plan`: write `tracks/<track_id>/PLAN.md` using P5 prompt template; set `phase: execute` when plan exists.
- Add parsing specs for new sentinel types (`TRACK:V1`), and multi-block plan extraction rules.

### `ralph.sh`

Mostly unchanged (keep Ralph mechanical), but preflight messaging should:
- mention missing doc prerequisites more precisely (if desired),
- avoid making Ralph “smart” (do not auto-run P2/P12); instead rely on orchestrator notifications as contract already intends.

### `.pipe/p2/*` prompts

Update:
- `.pipe/p2/P2_MAIN.md`: Phase 6 “OUTPUT” now writes 5 docs + ledger; Phase 7 review covers all.
- `.pipe/p2/P2_F.md`: expand output templates to include `PROJECT.md`, `REQUIREMENTS.md`, `STATE.md`, and the revised strategic `ROADMAP.md` schema.
- Potentially `.pipe/p2/P2_E.md`: crystallize step must explicitly extract:
  - core value + constraints (PROJECT),
  - requirement list with IDs + verification hints (REQUIREMENTS),
  - phases with success criteria + requirement coverage (ROADMAP),
  - digest content (STATE.md).

### `.pipe/p2-brainstorm.sh`

Update output assertions:
- currently checks only `VISION.md` + `ROADMAP.md`; should also ensure `PROJECT.md`, `REQUIREMENTS.md`, `STATE.md` exist and are non-empty before writing `P2_DONE`.

### New prompt templates

Add:
- `.pipe/p3/P3_PICK_TRACK.md`
- `.pipe/p4/P4_CREATE_SPEC.md`
- `.pipe/p5/P5_CREATE_PLAN.md`

Each should follow the layered structure used elsewhere (0a/1/999+), keep output strictly parseable, and respect the same “don’t assume, search first” discipline where relevant.

### Parsers / helpers

Add:
- `extract_track.py` for `TRACK:V1` blocks (deterministic).
Enhance or add:
- `extract_plan.py` support for multi-block extraction (`--nth` or `--next-from file`), **or** a new script `extract_next_plan.py` that uses the existing grammar to parse one chosen block.

---

## 9) Implementation Micro-Tasks (Atomic, Ordered)

1. Define final schemas for `VISION.md`, `PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md` (this document is the baseline).
2. Update `.pipe/p2/P2_E.md` to explicitly elicit: core value, constraints, requirement IDs, phase success criteria, and digest fields.
3. Update `.pipe/p2/P2_F.md` to write all 5 docs (YAML-in-codefence for 4; short markdown for STATE.md) with strict line caps.
4. Update `.pipe/p2/P2_MAIN.md` so Phase 6 writes the 5 docs and Phase 7 reviews all 5.
5. Update `.pipe/p2-brainstorm.sh` to require the 3 new files before stamping `.deadf/seed/P2_DONE`.
6. Add `.pipe/p3/P3_PICK_TRACK.md` and implement `TRACK:V1` output contract.
7. Add `extract_track.py` and wire `CLAUDE.md` `pick_track` action to use it.
8. Add `.pipe/p4/P4_CREATE_SPEC.md` and update `CLAUDE.md` `create_spec` action to write `tracks/<track_id>/SPEC.md`.
9. Add `.pipe/p5/P5_CREATE_PLAN.md` and update `CLAUDE.md` `create_plan` action to write `tracks/<track_id>/PLAN.md`.
10. Enhance `extract_plan.py` (or add `extract_next_plan.py`) to support multi-block plan extraction from `tracks/<track_id>/PLAN.md`.
11. Update the execute-phase entrypoint (P6 behavior) to prefer “pull next planned task from track PLAN.md” before falling back to generating a fresh task plan (keeps backward compatibility and reduces planner calls).
12. Add reflect-time doc sync rules:
    - update `REQUIREMENTS.md` statuses for requirements covered by the track,
    - append key decisions (if any) to `PROJECT.md.key_decisions`,
    - update `STATE.md` digest.

---

## Summary (The “Why” in One Paragraph)

This restructure keeps deadf(ish) as an autonomous, deterministic loop, but fills the missing GSD artifacts (PROJECT/REQUIREMENTS/STATE digest) and adopts Conductor’s “just-in-time track” discipline. ROADMAP becomes a stable, strategic phase map with observable success criteria. When a track is selected, we generate **track-local spec + plan** that bundle only the necessary context, keeping token budgets tight. Plans become Sentinel DSL task prompts that flow directly into execution with minimal mechanical extraction, preserving what already works (STATE.yaml + verify.sh + sentinel parsing) while extending the pipeline’s planning rigor and traceability.

