# deadf(ish) CLI Pipeline — Restructuring Plan v2 (GPT‑5.2)

Date: 2026-02-02  
Scope: Define a **new** pipeline structure that (1) deploys cleanly into target projects as `.deadf/`, (2) shrinks `CLAUDE.md` to **≤300 lines**, (3) eliminates P-number naming in the operational surface, and (4) reconciles contracts ↔ templates ↔ tools so the loop is actually executable.

This v2 plan is explicitly inspired by:
- **GSD** (`.planning/` workbench + root project docs + “fresh context per task” posture)
- **Google Conductor** (Track lifecycle: Spec → Plan → Implement; track folder conventions; revert/review ergonomics)

It also preserves our unique strengths (non-negotiable):
- Deterministic verification (`verify.sh` + conservative verdict aggregation)
- Sentinel grammars + nonces
- Three-tier repair escalation (Format Repair → Auto-Diagnose → Escalate)
- Track-level QA review after execution
- Task Management integration (Claude Code Tasks)
- Multi-model roles (Orchestrator + Planner + Implementer)

Fred’s constraints (hard):
- Target projects get a `.deadf/` folder containing **all pipeline runtime** (templates, contracts, tools, logs/locks, metadata).
- `CLAUDE.md` must be **≤300 lines**.
- Semantic naming (no P-numbers in the primary workflow).
- Fix contract/tool mismatches (stop claiming scripts parse formats they don’t).

---

## A) Directory structure (GSD + Conductor inspired)

### A1) Target project layout (what `deadf init` installs)

GSD influence: root-level “project docs” are the public interface; planning artifacts live under a hidden workbench.  
Conductor influence: a single “control plane” folder owns track specs/plans + workflow metadata.

We fuse both by making `.deadf/` the **control plane + workbench**, while still writing human-friendly docs at repo root.

Exact tree (target project):

```text
<project>/
  PROJECT.md
  REQUIREMENTS.md
  ROADMAP.md
  VISION.md
  OPS.md                      # optional, lean; loaded every cycle if present
  POLICY.yaml                 # may be symlinked to .deadf/policy/POLICY.yaml (see F)
  STATE.yaml                  # may be symlinked to .deadf/state/STATE.yaml (see F)

  .deadf/
    VERSION                   # pinned pipeline version
    manifest.yaml             # file list + hashes for safe updates/reverts

    bin/                      # “single entrypoints” (human + orchestrator)
      deadf                   # CLI wrapper (kick/status/track/etc.)
      kick.sh                 # one canonical kick path (see G)
      verify.sh               # deterministic facts-only verifier
      ralph.sh                # loop controller (optional)
      parse_blocks.py         # sentinel parser(s) (track/spec/plan/verdict/qa)
      apply_edits.py          # deterministic edit applier (for reflect/docs)

    contracts/                # single source of truth for formats
      sentinel/
        track.v1.md
        spec.v1.md
        plan.v1.md
        qa_review.v1.md
        verdict.v1.md
      schemas/
        state.v2.yaml
        task_packet.v1.yaml
        verify_result.v1.json
      policy/
        policy.schema.json

    policy/
      POLICY.yaml             # canonical policy (root POLICY.yaml may symlink here)

    state/
      STATE.yaml              # canonical state (root STATE.yaml may symlink here)

    templates/                # model prompt templates (semantic names)
      bootstrap/
        seed_project_docs.md
        map_codebase.md
      track/
        select_track.md
        write_spec.md
        write_plan.md
      task/
        generate_task_packet.md
        implement_task.md
      verify/
        verify_criterion.md
        reflect.md
        qa_review.md
      repair/
        format_repair.md
        auto_diagnose.md
        escalation.md

    docs/                     # living docs (track-end learnings)
      PRODUCT.md
      TECH_STACK.md
      WORKFLOW.md
      PATTERNS.md
      PITFALLS.md
      RISKS.md
      GLOSSARY.md
      .scratch.yaml

    tracks/                   # Conductor-style track folder (execution artifacts)
      <track_id>/
        track.yaml            # metadata: title, status, created_at, base_commit
        spec.md
        plan.md
        tasks/
          001.task.md
          002.task.md
          ...
        qa_review.md

    planning/                 # GSD-style workbench (fresh context per cycle/task)
      runs/
        <cycle_id>/
          inputs/             # snapshots gathered deterministically
          evidence/           # diffs, stats, logs (capped)
          outputs/            # raw model outputs (blocks)
          summary.md

    runtime/                  # purely mechanical, gitignored by default
      locks/
      logs/
      cache/
      task_list_id            # Claude Tasks list id (if enabled)
```

Why this is better than GSD/Conductor alone:
- **Better than GSD:** we keep GSD’s “simple workflow” feel, but enforce deterministic IO with nonce + strict formats + verifier facts, so unattended loops fail safely instead of drifting.
- **Better than Conductor:** we keep Conductor’s track lifecycle, but add deterministic verification + repair escalation + conservative verdict logic as first-class, not ad-hoc.

### A2) deadfish-cli repo layout (what we maintain)

Rule: the repo should contain the deployed tree as **the canonical source**, so installing/updating a target project is a copy of committed files (no hidden generator magic).

Exact tree (repo-side):

```text
deadfish-cli/
  .deadf/                     # canonical deployed layout (copied into target repos)
    ... (exactly as above)

  .planning/                  # GSD-style workbench for *this* repo’s design/reviews
    restructure/
    reviews/
    research/

  CLAUDE.md                   # ≤300-line binder contract (see B)
  README.md
  VISION.md
  ROADMAP.md
  PROMPT_OPTIMIZATION.md      # historical; may reference legacy P-numbers only
  verify.sh                   # optional compatibility shim -> calls .deadf/bin/verify.sh
  ralph.sh                    # optional compatibility shim -> calls .deadf/bin/ralph.sh
  build_verdict.py            # either moved to .deadf/bin/ or wrapped
  extract_plan.py             # either renamed or replaced (see F)
```

Migration note: we can keep `.pipe/` temporarily as the repo’s “workbench”, but v2 standardizes on `.planning/` to match GSD and to stop conflating “runtime pipeline” with “design artifacts”.

---

## B) `CLAUDE.md` split strategy (shrink to ≤300 lines)

Problem today (concrete):
- `CLAUDE.md` is ~1239 lines and includes **action specs + grammars + tool expectations**, which creates drift.
- It claims `extract_plan.py` parses TRACK/SPEC/PLAN, but `extract_plan.py` only parses PLAN blocks.
- It describes task packets under `.deadf/tracks/.../TASK_{NNN}.md`, but `verify.sh` reads `TASK.md` and parses `path=` via grep.

### B1) New shape: “Binder contract” + versioned imports (no magic)

We do **not** rely on “auto-load `.claude/`” or “`@import` works” as platform guarantees.

Instead, `CLAUDE.md` becomes a short binder that mandates a deterministic LOAD step:

- Always read (in order):
  1. `STATE.yaml` (or `.deadf/state/STATE.yaml`), `POLICY.yaml`, `OPS.md` (if present)
  2. `.deadf/contracts/schemas/state.v2.yaml` (schema constraints)
  3. `.deadf/contracts/sentinel/*.v1.md` (only when parsing that block type)
  4. `.deadf/templates/<area>/<action>.md` (only when executing that action)

`CLAUDE.md` contains:
- Roles + write authority boundaries (Orchestrator vs Planner vs Implementer vs Verifier)
- Deterministic cycle skeleton (LOAD → VALIDATE → DECIDE → EXECUTE → RECORD → REPLY)
- The DECIDE table (semantic phase/sub_step names; see C)
- State locking rules (atomic write under `STATE.yaml.flock`)
- Nonce derivation rules
- “How to load the right files” rules (explicit `read` requirements, not `@import`)
- Final-line token contract (`CYCLE_OK|CYCLE_FAIL|DONE`)

Everything else moves into `.deadf/`:
- Sentinel grammars → `.deadf/contracts/sentinel/*`
- Action specs → `.deadf/templates/**` (as the single canonical prompt bodies)
- Tool contracts (verify/parse outputs) → `.deadf/contracts/schemas/**`
- Repair escalation policy → `.deadf/templates/repair/**`
- Task Management integration rules → `.deadf/templates/**` + `.deadf/contracts/schemas/state.v2.yaml`

### B2) Concrete line budget (enforced by structure)

Target: 220–280 lines total in `CLAUDE.md`.
- 40 lines: identity/roles/authority
- 80 lines: cycle skeleton + deterministic rules
- 80 lines: DECIDE table + state transitions (semantic)
- 20 lines: output contract + failure modes

Rule: if content is only needed for **one** action (e.g., QA review formatting), it cannot live in `CLAUDE.md`.

---

## C) Semantic naming (no P-numbers)

### C1) Replace phase/sub_step vocabulary

Replace legacy P-number labels with semantic names in **state**, **templates**, **docs**, and **scripts**.

Canonical action IDs (stable, grep-friendly):
- `bootstrap.seed_project_docs`
- `bootstrap.map_codebase`
- `track.select`
- `track.write_spec`
- `track.write_plan`
- `task.generate_packet`
- `task.implement`
- `verify.facts` (deterministic script)
- `verify.criteria` (LLM, strict verdict grammar)
- `docs.reflect` (post-task, living docs)
- `repair.format`
- `repair.auto_diagnose`
- `repair.escalate`
- `qa.review`

Canonical STATE fields (example):
```yaml
phase: track.select | track.write_spec | track.write_plan | task.generate_packet | task.implement | verify.criteria | docs.reflect | qa.review | complete | needs_human
task:
  sub_step: null | generate_packet | implement | verify_criteria | reflect | qa_review
```

### C2) Keep legacy labels only as history

Allowed legacy references:
- `PROMPT_OPTIMIZATION.md` (explicitly labeled “legacy mapping”)
- `.planning/` design/review artifacts

Not allowed:
- filenames, directories, template IDs, or state transitions using `p1`, `p10`, etc.

---

## D) Workflow mapping (ours ↔ GSD ↔ Conductor)

### D1) Concept mapping table

```text
Our v2                         GSD                         Conductor
--------------------------------------------------------------------------------
bootstrap.seed_project_docs     /gsd:new-project            /conductor:setup
bootstrap.map_codebase          /gsd:map-codebase           (setup support)

track.select                    /gsd:discuss-phase          /conductor:newTrack (select)
track.write_spec                /gsd:discuss-phase          tracks/<id>/spec.md
track.write_plan                /gsd:plan-phase             tracks/<id>/plan.md

task.generate_packet            (task breakdown)            implement (tasking inside track)
task.implement                  /gsd:execute-phase          /conductor:implement

verify.facts + verify.criteria  /gsd:verify-work            review/status (tooling)
docs.reflect                    (GSD summaries)             (team context sharing)
qa.review                       /gsd:complete-milestone     /conductor:review

repair.*                        (implicit in GSD)           /conductor:revert (+ ours)
```

### D2) Where we intentionally diverge (and why we’re better)

- **Nonce + strict grammars**: neither GSD nor Conductor enforces parser-safe outputs; we do, because it’s the only reliable way to automate multi-agent work.
- **Deterministic facts verifier**: we keep `verify.sh` as the “objective reality” layer so the LLM cannot grade its own homework.
- **Three-tier repair escalation**: we keep it because strict formats + multi-model handoffs will fail; the key is failing deterministically, then repairing deterministically.
- **Track-level QA**: we keep this because “task pass” ≠ “track-quality ship”; Conductor has review, but we make it a first-class, grammar-validated step.

---

## E) Adopt vs keep vs design new (explicit)

### E1) Adopt from GSD

- A hidden **workbench** folder concept → `.deadf/planning/` (per-cycle context bundles; reduces context rot).
- Root-level “project docs” as the stable interface (`PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `VISION.md`).
- “Complexity in the system, not the workflow” → our workflow stays simple (select → spec → plan → task loop), while determinism lives in contracts/tools.

### E2) Adopt from Conductor

- Track folder lifecycle as the primary unit of work (`.deadf/tracks/<id>/spec.md`, `plan.md`, tasks).
- “Implement/status/revert/review” ergonomics → add explicit `deadf status` + `deadf revert` behaviors backed by manifest + git.
- Brownfield support as a first-class track pre-step (we keep and formalize our mapper).

### E3) Keep (our unique strengths)

- `verify.sh` facts-only JSON output and conservative gating (if facts fail → no LLM verify).
- Nonce derivation and sentinel-block validation.
- Repair escalation ladder.
- QA review gate after last task.
- Task Management integration (degrades gracefully when unavailable).
- Multi-model roles + conservative verdict logic.

### E4) Design new (v2-only)

- **One source of truth** per contract:
  - Grammar specs in `.deadf/contracts/`
  - Template prompts in `.deadf/templates/`
  - Parsers/verifiers in `.deadf/bin/`
  - Tests enforce alignment (see G)
- **Update/revert mechanics** for `.deadf/` using `manifest.yaml` hashes (Conductor-inspired “smart revert”, but deterministic).
- **Task packet schema** as YAML-frontmatter + markdown body (`task_packet.v1.yaml`) so both humans and tools parse it reliably (replaces brittle grep parsing).

---

## F) Contract/tool reconciliation (stop the drift)

This section is the “make it actually run” work.

### F1) Current mismatches (must eliminate)

1. `CLAUDE.md` says `extract_plan.py` parses TRACK/SPEC/PLAN; reality: `extract_plan.py` parses PLAN only.
2. `CLAUDE.md` writes task packets to `.deadf/tracks/.../tasks/TASK_{NNN}.md`; reality: `verify.sh` reads `TASK.md` and expects `path=` tokens.
3. Multiple kick paths exist (`.pipe/p1/p1-cron-kick.sh`, `ralph.sh`); ownership and invariants differ.
4. Format specs live in prose (contract) while parsers are hardcoded; there is no single versioned “source of truth” enforced by tests.

### F2) v2 reconciliation rules (authoritative)

**Rule 1: “Spec lives with the parser.”**  
For every strict format, ship:
- a human-readable spec in `.deadf/contracts/**`
- a parser in `.deadf/bin/**`
- golden tests in `tests/**` that prove accept/reject

**Rule 2: “Templates must be lintable.”**  
Add a deterministic linter (`.deadf/bin/lint_templates.py`) that checks:
- sentinel open/close strings exactly match the contract files
- required fields appear in the required order
- no disallowed whitespace/tabs/blank lines in strict blocks

**Rule 3: “Tool inputs are machine-readable.”**  
Task packets become YAML-frontmatter with a schema, so:
- `verify.sh` (or its helper) reads `estimated_diff` and `files[].path` via `yq`
- no regex-based parsing of “contracts”

### F3) Specific decisions (resolve the known conflicts)

- Replace `extract_plan.py` with `parse_blocks.py` (or rename + split):
  - `parse_blocks.py track` parses `<<<TRACK:V1...>>>` blocks
  - `parse_blocks.py spec` parses `<<<SPEC:V1...>>>` blocks
  - `parse_blocks.py plan` parses `<<<PLAN:V1...>>>` blocks
  - `parse_blocks.py qa_review` parses `<<<QA_REVIEW:V1...>>>` blocks
  - `build_verdict.py` becomes `parse_blocks.py verdict` (or is wrapped), so the surface is unified.

- Task file path contract:
  - Canonical task path: `.deadf/tracks/<track_id>/tasks/<nnn>.task.md`
  - `STATE.yaml` stores `task.packet_path`.
  - Verifier reads `task.packet_path` (via yq) and verifies against that file.
  - Optional compatibility: write/refresh `<project>/TASK.md` as a symlink to the canonical path (only if the platform supports symlinks), otherwise copy.

- Kick path contract:
  - Canonical entrypoint: `.deadf/bin/kick.sh`
  - `ralph.sh` becomes a thin wrapper calling `.deadf/bin/ralph.sh` (optional).
  - Repo-side scripts may remain as shims for a deprecation window only.

---

## G) Implementation plan (staged, with executable checkpoints)

This is ordered to avoid breaking the pipeline mid-migration.

### Stage 0 — Freeze vocabulary + add mapping

1. Add a single “legacy → v2 semantic name” mapping doc under `.planning/restructure/legacy-mapping.md`.
2. Update `PROMPT_OPTIMIZATION.md` to explicitly label P-numbers as legacy and point to the new semantic IDs.

Checkpoint: a reader can name the v2 actions without reading P-number docs.

### Stage 1 — Establish `.deadf/` as the canonical deployed tree

1. Create the v2 `.deadf/` directories (A1) in this repo.
2. Copy existing prompt templates from `.pipe/p*/` into `.deadf/templates/**` with semantic filenames.
3. Copy/port scripts into `.deadf/bin/**` (initially wrappers are fine).

Checkpoint: `find .deadf -type f` shows a coherent, self-contained runtime.

### Stage 2 — Fix the contract/tool mismatches (before deleting anything)

1. Implement `parse_blocks.py` (or refactor existing parsers) to cover TRACK/SPEC/PLAN/QA_REVIEW in addition to VERDICT.
2. Define `task_packet.v1.yaml` and migrate the task packet writer templates to emit YAML-frontmatter.
3. Update verifier to read from `STATE.yaml.task.packet_path` and parse YAML-frontmatter (no grep contracts).

Checkpoint: end-to-end “parse output → write artifacts → verify facts” can run on a fixture repo.

### Stage 3 — Shrink `CLAUDE.md` to a binder (≤300 lines)

1. Move strict grammars into `.deadf/contracts/sentinel/*`.
2. Move action prompt bodies into `.deadf/templates/**`.
3. Rewrite `CLAUDE.md` to:
   - keep cycle skeleton + DECIDE table + atomic state rules + nonce rules
   - require explicit reads of `.deadf/` contract/template files when needed

Checkpoint: `wc -l CLAUDE.md` ≤ 300 and the binder still fully specifies the deterministic loop.

### Stage 4 — Add drift-proofing (tests + linters)

1. Add golden fixtures for each sentinel block type under `tests/fixtures/`.
2. Add a test runner that:
   - validates parsers accept valid fixtures and reject invalid ones
   - validates template lint rules against `.deadf/templates/**`
3. Add a smoke test for `verify.sh` output JSON shape vs `verify_result.v1.json`.

Checkpoint: CI/local run catches contract drift before release.

### Stage 5 — Migrate repository workbench (`.pipe/` → `.planning/`)

1. Move design/review artifacts into `.planning/` (keep history; don’t rewrite content).
2. Keep `.pipe/` only as compatibility during transition; eventually delete or archive.

Checkpoint: runtime files live in `.deadf/`; planning files live in `.planning/`.

### Stage 6 — Provide deployment/update/revert commands (Conductor-inspired, deterministic)

1. Implement `deadf update`:
   - computes diffs vs `manifest.yaml`
   - applies file updates atomically
   - writes rollback data under `.deadf/runtime/` and supports `deadf revert`
2. Implement `deadf status`:
   - reads `STATE.yaml`, active track/task, last verifier results

Checkpoint: target projects can safely pin, update, and revert the pipeline without manual copy errors.

---

## Success criteria (definition of “done” for the restructure)

1. `CLAUDE.md` ≤ 300 lines and contains no full grammars/prompt bodies.
2. `.deadf/` in a target project contains all pipeline runtime (templates/contracts/tools/runtime dirs).
3. Parsers and verifier match contracts (no known mismatches like `extract_plan.py` vs TRACK/SPEC).
4. Semantic naming is the primary surface; P-numbers remain only as explicitly-labeled history.
5. A minimal fixture repo can run: kick → select track → spec → plan → generate task → implement (stub) → verify facts → verify criteria (stub) without breaking formats.
