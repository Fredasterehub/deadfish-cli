# T10 — GPT-5.2-Codex Implementation Prompt
You are `gpt-5.2-codex` operating in the repo root.

## Goal
Update **only** the **Action Specifications** section in `CLAUDE.md` to match the new P3–P5 flow and file set.

## Source-of-truth files to consult
- Master plan / design notes: `.pipe/p2-p5-restructure-opus.md` (see T10 + Sections 6–8)
- P3 prompt: `.pipe/p3/P3_PICK_TRACK.md`
- P4 prompt: `.pipe/p4/P4_CREATE_SPEC.md`
- P5 prompt: `.pipe/p5/P5_CREATE_PLAN.md`
- Sentinel parser referenced by specs: `extract_plan.py`

## Hard constraints
- Do **not** modify the **DECIDE** table or any phase/sub_step logic in `CLAUDE.md` (the table under “Step 3: DECIDE” must remain unchanged).
- Do **not** modify any other sections of `CLAUDE.md` beyond what’s necessary inside **Action Specifications**.
- Keep file paths exactly as they exist in this repo (use the paths listed above).

## The exact current `CLAUDE.md` content you must modify (lines 175–225)
Replace/update content **within this section** as required by the tasks below, but do not change unrelated surrounding text.

````md
## Action Specifications

### `seed_docs` (research phase) — P2 Brainstorm Session

This phase is **human-driven**. Claude Code must **NOT** generate seed docs automatically.

Deterministic rule:
1. If `.deadf/seed/P2_DONE` is missing **OR** `VISION.md`/`ROADMAP.md` are missing/empty:
   - set `phase: needs_human`
   - write a notification instructing the operator to run the P2 runner:
     `.pipe/p12-init.sh --project "<project_root>"`
2. If `P2_DONE` exists **and** both docs exist:
   - set `phase: select-track` (do not overwrite docs)

Note: `.deadf/seed/` is the seed docs ledger directory.
Note: P12 writes `.deadf/p12/P12_DONE` when mapping/confirmation completes; treat missing marker as non-fatal and degrade gracefully (never fatal).

### P12: Codebase Mapper / Brownfield Detection
- Runs before P2, outside the cycle loop
- Detects greenfield/brownfield/returning via heuristics
- For brownfield: maps codebase into 7 machine-optimized living docs (<5000 tokens combined): TECH_STACK.md, PATTERNS.md, PITFALLS.md, RISKS.md, WORKFLOW.md, PRODUCT.md, GLOSSARY.md
- Living docs feed into P2 brainstorm as brownfield context
- WORKFLOW.md contains smart loading map (track type → relevant docs subset)
- P12 failure degrades gracefully to greenfield brainstorm
- Entry point: `.pipe/p12-init.sh --project <path>`
- Marker: `.deadf/p12/P12_DONE`

### `pick_track` (select-track phase)

1. Consult GPT-5.2 planner to select next track from `tracks_remaining`
2. Set `track.id`, `track.name`, `track.status: in-progress`
3. Advance sub-step

### `create_spec` / `create_plan` (select-track phase)

1. Consult GPT-5.2 planner for track spec/plan
2. Parse output with `extract_plan.py --nonce <nonce>` (see [Sentinel Parsing](#sentinel-parsing))
3. Update track details
4. On plan complete: set `phase: execute`, `task.sub_step: generate`

### `generate_task` (execute phase)

Construct the GPT-5.2 planner prompt using the **layered prompt structure**:

```
--- ORIENTATION (0a-0c) ---
0a. Read STATE.yaml: current phase, track, task position, last_result, loop.stuck_count.
0b. Read track spec and existing plan docs. Read OPS.md if present.
0c. Search the codebase (`rg`, `find`) for existing implementations related to this track.
    Do NOT assume functionality is missing — confirm with code search first.

```
````

## Required updates (implement all)

### 1) `seed_docs` deterministic rule (human-driven)
Update the deterministic check to require **all five** seed outputs (instead of just VISION/ROADMAP):
- `VISION.md`
- `PROJECT.md`
- `REQUIREMENTS.md`
- `ROADMAP.md`
- `STATE.yaml`

Also update the `P2_DONE`/seed-marker check accordingly:
- If `.deadf/seed/P2_DONE` is missing **OR** any of the five files are missing/empty → `phase: needs_human` and notify operator to run `.pipe/p12-init.sh --project "<project_root>"`.
- If `.deadf/seed/P2_DONE` exists **and** all five files exist and are non-empty → `phase: select-track` (do not overwrite docs).
Keep the explicit “human-driven” nature (Codex must not generate seed docs).

### 2) Replace `pick_track` stub with a full spec
Replace the 3-line stub with a proper action specification that includes:
- A reference to the P3 prompt file: `.pipe/p3/P3_PICK_TRACK.md` (this is the prompt used for the GPT-5.2 planner call).
- Explicit loading requirements: **load** `STATE.yaml`, `ROADMAP.md`, and `REQUIREMENTS.md` (you may also mention `VISION.md`/`PROJECT.md` if useful, but those three are mandatory).
- The TRACK sentinel format (document it verbatim as the opener token):
  - `<<<TRACK:V1:NONCE={nonce}>>>`
  - and the closer `<<<END_TRACK:NONCE={nonce}>>>`
- Mention the two special signals and how the orchestrator should react:
  - `PHASE_COMPLETE=true`
  - `PHASE_BLOCKED=true` (include `REASONS=...`)
- Describe parsing with `extract_plan.py --nonce <nonce>` (same sentinel-parsing flow as other actions).
- Describe **STATE.yaml** updates on success, including (at minimum) `track.id`, `track.name`, plus the additional fields implied by the P3 prompt:
  - `track.phase`
  - `track.requirements`
  - `track.goal`
  - `track.estimated_tasks`
  - `track.status` (keep consistent with the rest of `CLAUDE.md`)
  - `track.spec_path` and `track.plan_path` initialized to null/empty (so DECIDE can route to create_spec/create_plan deterministically).

### 3) Replace `create_spec` stub with a full spec (separate from create_plan)
Split the combined `create_spec` / `create_plan` stub into distinct, properly detailed action specs (separate headings).

For `create_spec`, include:
- A reference to the P4 prompt file: `.pipe/p4/P4_CREATE_SPEC.md`.
- Explicit loading requirements: `STATE.yaml`, `ROADMAP.md`, `REQUIREMENTS.md`, `PROJECT.md`, `OPS.md` (if present), plus **codebase search** (rg/find evidence) before assuming anything is missing.
- The SPEC sentinel format (document the opener token verbatim):
  - `<<<SPEC:V1:NONCE={nonce}>>>`
  - and the closer `<<<END_SPEC:NONCE={nonce}>>>`
- Parse the SPEC output via `extract_plan.py --nonce <nonce>` (reference the Sentinel Parsing section).
- Write the spec to: `.deadf/tracks/{track.id}/SPEC.md`.
- Update `STATE.yaml` (at minimum) to record `track.spec_path` and any track status progression consistent with the pipeline.

### 4) Replace `create_plan` stub with a full spec
For `create_plan`, include:
- A reference to the P5 prompt file: `.pipe/p5/P5_CREATE_PLAN.md`.
- Explicit loading requirements: `STATE.yaml`, the track `SPEC.md`, `PROJECT.md`, `OPS.md` (if present).
- The PLAN sentinel format (document the opener token verbatim):
  - `<<<PLAN:V1:NONCE={nonce}>>>`
  - and the closer `<<<END_PLAN:NONCE={nonce}>>>`
- Parse the PLAN output via `extract_plan.py --nonce <nonce>` (reference the Sentinel Parsing section).
- Write the plan to: `.deadf/tracks/{track.id}/PLAN.md`.
- On plan complete, set:
  - `phase: execute`
  - `task.sub_step: generate`

### 5) Document `.deadf/tracks/` directory structure
Add a concise description (either within Action Specifications or as a small new subsection nearby) documenting the per-track artifact layout:
- `.deadf/tracks/{track.id}/SPEC.md`
- `.deadf/tracks/{track.id}/PLAN.md`
If you mention additional subdirs (e.g., `tasks/`), keep it consistent with the P3–P5 design and avoid inventing paths not used elsewhere.

## Done-when checklist (must all be true)
- [ ] `seed_docs` references all 5 output files (`VISION.md`, `PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.yaml`)
- [ ] `pick_track` references `.pipe/p3/P3_PICK_TRACK.md` and the TRACK sentinel (`<<<TRACK:V1:NONCE={nonce}>>>`)
- [ ] `create_spec` references `.pipe/p4/P4_CREATE_SPEC.md` and the SPEC sentinel (`<<<SPEC:V1:NONCE={nonce}>>>`)
- [ ] `create_plan` references `.pipe/p5/P5_CREATE_PLAN.md` and the PLAN sentinel (`<<<PLAN:V1:NONCE={nonce}>>>`)
- [ ] `.deadf/tracks/{id}/` structure is documented
- [ ] All file paths are consistent with actual repo locations
- [ ] DECIDE table unchanged (phase/sub_step logic same)
- [ ] No other sections of `CLAUDE.md` modified unnecessarily
