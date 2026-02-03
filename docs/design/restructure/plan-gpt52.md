# deadf(ish) CLI Pipeline — Restructuring Plan (GPT‑5.2)

Date: 2026-02-02  
Scope: Major architectural cleanup focused on (1) shrinking `CLAUDE.md`, (2) de-tangling `.pipe/`, (3) semantic naming, and (4) reconciling contracts with tooling (`extract_plan.py`, `verify.sh`, `ralph.sh`).

---

## 0) Non-Negotiables (Claude Code Reality)

1. `CLAUDE.md` is loaded **every session start** → it must be short and stable.
2. `.claude/rules/*.md` are **auto-loaded** → keep them *small* and *invariant-only*.
3. Use `@path/to/import` in `CLAUDE.md` for **on-demand** loading of large action specs and grammars.
4. Use YAML frontmatter `paths:` for **path-scoped rules** (avoid polluting global context).
5. Contracts must be executable: if a template or contract claims “parse with X”, the parser must accept that exact format.

Target outcomes:
- `CLAUDE.md`: **≤ 300 lines** (ideal 200–260).
- `.claude/rules/`: **≤ ~200–300 lines total** across all rule files.
- “One canonical” location for each: prompts/templates, grammars, tooling contracts, launchers.

---

## A) `CLAUDE.md` Split Strategy (to ≤300 lines)

### A1. What stays in `CLAUDE.md` (always-loaded core)

Keep only what must be present for *any* cycle:

1. **Identity + role boundaries** (Orchestrator vs planner/implementer/verifier).
2. **Cycle skeleton** (LOAD → VALIDATE → DECIDE → EXECUTE → RECORD → REPLY).
3. **DECIDE table** (the deterministic routing table is the “brainstem”).
4. **State locking + write authority** (the `STATE.yaml.flock` rule and who can write what).
5. **IO contract** (final token line must be `CYCLE_OK | CYCLE_FAIL | DONE`).
6. **One-paragraph “how to import”**: a deterministic rule for when to `@import` action specs and grammars.

Everything else is either:
- an **action spec** (should be imported only when that action is chosen), or
- a **format grammar** (import only when parsing/validating that block type), or
- an **implementation detail** of tooling (lives with the tool + its contract doc).

### A2. What moves out of `CLAUDE.md`

Move these out (currently dominant bloat):

1. **Action Specifications** (`seed_docs`, `pick_track`, `create_spec`, `create_plan`, `generate_task`, `implement_task`, `verify_task`, `reflect`, `qa_review`, `retry_task`, `replan_task`, `rollback_and_escalate`, `summarize`, `escalate`).
2. **Full sentinel grammars** (TRACK/SPEC/PLAN/VERDICT/QA_REVIEW/REFLECT), including detailed parser-safe constraints.
3. **P10 escalation policy** details (Tier 1/2 prompt text, Tier 3 per-block policy table).
4. **Task Management Integration** details (task naming convention, recovery/backfill algorithm).
5. **Launcher specifics** (full kick template, task list lifecycle, rotation).

### A3. Where it goes (auto-load vs import vs templates)

Because `.claude/rules/*.md` are auto-loaded, **do not put long action specs there**. Use this split:

**Auto-load (`.claude/rules/`) — invariant-only, always-on**
- `core.md`: non-improvisation, “one cycle = one action”, role boundaries.
- `state-locking.md`: lock discipline, atomic write pattern, write authority.
- `output-contract.md`: last-line token, “no prose outside blocks” when required.
- `safety.md`: blocked paths + no-secrets rules (short).
- `imports-index.md`: mapping from action → import path (just a table).

**On-demand imports (`.claude/imports/`) — large, action-specific or grammar-specific**
- `actions/*.md`: the full action specs.
- `grammars/*.md`: authoritative sentinel grammars, with parser-safe constraints.
- `tools/*.md`: tooling contracts that must stay synchronized with scripts.
- `task-system/*.md`: task management integration procedures.

**Templates (`.pipe/runtime/templates/`) — prompt bodies used for model dispatch**
- P3/P4/P5/P6/P7/P9/P9.5/P10/P11 templates live here (canonical).
- Any “dispatch procedure” text that is only needed when calling that prompt lives with the template, not in `CLAUDE.md`.

### A4. Concrete new `CLAUDE.md` shape (suggested TOC)

Goal: ~220–280 lines.

1. Identity (roles + do/don’t)
2. Inputs read in LOAD
3. VALIDATE rules (nonce derivation, budget checks)
4. DECIDE table (unchanged semantics)
5. EXECUTE rule: “Before executing action X: `@import .claude/imports/actions/X.md`”
6. RECORD rules (lock, atomic write pattern, always increment iteration)
7. REPLY rules (token + optional task summary line)
8. Minimal “Formats are elsewhere” note:
   - TRACK grammar: `@import .claude/imports/grammars/track-v1.md`
   - SPEC grammar: `@import .claude/imports/grammars/spec-v1.md`
   - PLAN grammar: `@import .claude/imports/grammars/plan-v1.md`
   - VERDICT grammar: `@import .claude/imports/grammars/verdict-v1.md`
   - QA_REVIEW grammar: `@import .claude/imports/grammars/qa-review-v1.md`
   - REFLECT grammar: `@import .claude/imports/grammars/reflect-v1.md`

### A5. Path-specific rules (YAML frontmatter)

Use path-scoped rules to avoid global bloat, e.g.:
- Shell scripts (`**/*.sh`): strict `set -euo pipefail`, no `cd` in subshells, log-to-stderr discipline.
- Prompt templates (`.pipe/runtime/templates/**/*.md`): forbid prose outside sentinel blocks; forbid changing sentinel grammar without updating parser contracts.
- Tooling (`extract_*.py`, `build_*.py`): parser strictness rules + test requirements.

---

## B) File Structure Reorganization

### B1. Problem recap (current repo)

- `.pipe/` mixes:
  - canonical runtime templates (P3/P6/P7/P9, etc),
  - working notes (plans, synthesis, reviews),
  - “codex prompt” scaffolds,
  - preflight tooling (P12 scripts).
- Root scripts (`verify.sh`, `extract_plan.py`, `ralph.sh`) don’t match the contract formats they claim to consume/emit.

### B2. Proposed clean layout (canonical vs workbench)

Keep `.pipe/` but split into “runtime” vs “workbench”:

```text
.claude/
  rules/                       # auto-loaded; invariant-only
    core.md
    state-locking.md
    output-contract.md
    safety.md
    imports-index.md
  imports/                     # on-demand via @import from CLAUDE.md
    actions/
      seed-docs.md
      pick-track.md
      create-spec.md
      create-plan.md
      generate-task-packet.md
      implement-task.md
      verify-task.md
      reflect.md
      qa-review.md
      retry-task.md
      replan-task.md
      rollback-and-escalate.md
      summarize.md
      escalate.md
    grammars/
      track-v1.md
      spec-v1.md
      plan-v1.md
      task-packet-v1.md
      verdict-v1.md
      qa-review-v1.md
      reflect-v1.md
    tools/
      extract-sentinel.md
      verify-sh.md
      build-verdict.md
      launcher-kick.md

.pipe/
  runtime/
    templates/                 # canonical prompts/templates consumed by pipeline
      cycle-kick.md            # (P1 template body)
      seed-docs.md             # (P2 main entry, if kept as template)
      pick-track.md            # P3
      create-spec.md           # P4
      create-plan.md           # P5
      generate-task-packet.md  # P6
      implement-task.md        # P7
      verify-criterion.md      # P9
      reflect.md               # P9.5
      format-repair.md         # P10 Tier 1
      auto-diagnose.md         # P10 Tier 2
      qa-review.md             # P11
    launchers/
      kick-once.sh             # canonical single-cycle launcher (current p1-cron-kick.sh)
  preflight/
    codebase-map/              # (P12) brownfield/greenfield detection + living-docs generation
      init.sh
      detect.sh
      collect.sh
      map.sh
      confirm.sh
      inject.sh
      prompts/
      templates/
  workbench/                   # NON-canonical: plans, synthesis, reviews, analysis notes
    reviews/
    syntheses/
    plans/
    analysis/
    trackers/
```

### B3. `.pipe/` cleanup mapping (what moves where)

Canonical runtime templates (must be under `.pipe/runtime/templates/`):
- `.pipe/p1/P1_CYCLE_KICK.md` → `.pipe/runtime/templates/cycle-kick.md`
- `.pipe/p3/P3_PICK_TRACK.md` → `.pipe/runtime/templates/pick-track.md`
- `.pipe/p4/P4_CREATE_SPEC.md` → `.pipe/runtime/templates/create-spec.md`
- `.pipe/p5/P5_CREATE_PLAN.md` → `.pipe/runtime/templates/create-plan.md`
- `.pipe/p6/P6_GENERATE_TASK.md` → `.pipe/runtime/templates/generate-task-packet.md`
- `.pipe/p7/P7_IMPLEMENT_TASK.md` → `.pipe/runtime/templates/implement-task.md`
- `.pipe/p9/P9_VERIFY_CRITERION.md` → `.pipe/runtime/templates/verify-criterion.md`
- `.pipe/p9.5/P9_5_REFLECT.md` → `.pipe/runtime/templates/reflect.md`
- `.pipe/p10/P10_FORMAT_REPAIR.md` → `.pipe/runtime/templates/format-repair.md`
- `.pipe/p10/P10_AUTO_DIAGNOSE.md` → `.pipe/runtime/templates/auto-diagnose.md`
- `.pipe/p11/P11_QA_REVIEW.md` → `.pipe/runtime/templates/qa-review.md`

Canonical runtime launcher:
- `.pipe/p1/p1-cron-kick.sh` → `.pipe/runtime/launchers/kick-once.sh`

Preflight tooling (P12):
- `.pipe/p12-init.sh` → `.pipe/preflight/codebase-map/init.sh`
- `.pipe/p12/P12_*.sh` → `.pipe/preflight/codebase-map/*.sh` (semantic names)
- `.pipe/p12/prompts/*` → `.pipe/preflight/codebase-map/prompts/*`
- `.pipe/p12/templates/*` → `.pipe/preflight/codebase-map/templates/*`

Workbench / working artifacts (not used by runtime pipeline):
- `.pipe/*-design-*.md`, `.pipe/*-analysis-*.md`, `.pipe/*-review-*.md` → `.pipe/workbench/analysis/`
- `.pipe/**/plan-*.md`, `.pipe/**/synthesis-*.md`, `.pipe/**/*-codex-prompt.md` → `.pipe/workbench/plans/` and `.pipe/workbench/syntheses/`
- `.pipe/reviews/*` → `.pipe/workbench/reviews/`
- `.pipe/OPTIMIZATION_TRACKER.md` → `.pipe/workbench/trackers/optimization-tracker.md`
- `.pipe/restructure-state.yaml` → `.pipe/workbench/trackers/restructure-state.yaml`

### B4. What stays at repo root (entrypoints)

Keep these at root for ergonomics and to avoid breaking existing scripts:
- `ralph.sh` (but reconcile behavior; see section D)
- `verify.sh` (but reconcile task packet; see section D)
- `extract_plan.py`, `build_verdict.py` (but likely become wrappers around new semantic tool names)

---

## C) Semantic Naming Convention

### C1. Canonical naming scheme

Use “what it does” in names; keep the P-number only as a secondary alias.

**File naming**
- Prompts/templates: `kebab-case.md` (e.g. `create-plan.md`, `verify-criterion.md`)
- Scripts: `kebab-case.sh` / `snake_case.py`
- Prefer directory names that describe the domain: `runtime/templates`, `runtime/launchers`, `preflight/codebase-map`, `workbench/*`.

### C2. P1–P12 (+ P9.5) mapping table

| ID | Current path | New canonical name | New canonical path |
|---:|---|---|---|
| P1 | `.pipe/p1/P1_CYCLE_KICK.md` | cycle kick template | `.pipe/runtime/templates/cycle-kick.md` |
| P1 | `.pipe/p1/p1-cron-kick.sh` | kick once launcher | `.pipe/runtime/launchers/kick-once.sh` |
| P2 | `.pipe/p2/P2_MAIN.md` (+ P2_A..G) | seed docs brainstorm | `.pipe/runtime/templates/seed-docs/` (folder) |
| P3 | `.pipe/p3/P3_PICK_TRACK.md` | pick track | `.pipe/runtime/templates/pick-track.md` |
| P4 | `.pipe/p4/P4_CREATE_SPEC.md` | create spec | `.pipe/runtime/templates/create-spec.md` |
| P5 | `.pipe/p5/P5_CREATE_PLAN.md` | create plan | `.pipe/runtime/templates/create-plan.md` |
| P6 | `.pipe/p6/P6_GENERATE_TASK.md` | generate task packet | `.pipe/runtime/templates/generate-task-packet.md` |
| P7 | `.pipe/p7/P7_IMPLEMENT_TASK.md` | implement task | `.pipe/runtime/templates/implement-task.md` |
| P8 | `verify.sh` | deterministic verify | `verify.sh` (stays root) |
| P9 | `.pipe/p9/P9_VERIFY_CRITERION.md` | verify criterion | `.pipe/runtime/templates/verify-criterion.md` |
| P9.5 | `.pipe/p9.5/P9_5_REFLECT.md` | reflect living docs | `.pipe/runtime/templates/reflect.md` |
| P10 | `.pipe/p10/P10_FORMAT_REPAIR.md` | format repair | `.pipe/runtime/templates/format-repair.md` |
| P10 | `.pipe/p10/P10_AUTO_DIAGNOSE.md` | auto diagnose | `.pipe/runtime/templates/auto-diagnose.md` |
| P11 | `.pipe/p11/P11_QA_REVIEW.md` | qa review | `.pipe/runtime/templates/qa-review.md` |
| P12 | `.pipe/p12-init.sh` + `.pipe/p12/*` | codebase map | `.pipe/preflight/codebase-map/*` |

### C3. Migration path (rename without breaking history)

Recommended 2-step migration to avoid breaking runtime:

1. **Introduce new canonical paths first** (copy files) + update all references to point to the new canonical paths.
2. Convert old paths to **compat shims** for one release window:
   - For shell scripts: old script calls new script and prints a deprecation warning.
   - For templates: keep old file as a byte-for-byte copy (or a symlink if acceptable in your environment).
3. After one full end-to-end green run + one week of usage: remove shims and delete old folders.

Do all moves with `git mv` where possible so history follows the file.

---

## D) Contract/Tool Reconciliation (must match actual formats)

This is the critical unblocker: today, templates and tools disagree.

### D1. Decide the authoritative formats (single source of truth)

Make these files the **only authoritative** grammar references:
- TRACK V1 grammar: `.pipe/runtime/templates/pick-track.md`
- SPEC V1 grammar: `.pipe/runtime/templates/create-spec.md`
- PLAN V1 grammar (multi-task): `.pipe/runtime/templates/create-plan.md`
- TASK packet schema (markdown): `.pipe/runtime/templates/generate-task-packet.md` + one explicit contract doc `.claude/imports/grammars/task-packet-v1.md`
- VERDICT V1 grammar: `.pipe/runtime/templates/verify-criterion.md` + `.claude/imports/grammars/verdict-v1.md`
- QA_REVIEW grammar: `.pipe/runtime/templates/qa-review.md` + `.claude/imports/grammars/qa-review-v1.md`
- REFLECT grammar: `.pipe/runtime/templates/reflect.md` + `.claude/imports/grammars/reflect-v1.md`

Then tooling must be updated to parse *exactly those*.

### D2. Fix `extract_plan.py` (TRACK/SPEC support + multi-task PLAN)

Current reality:
- `extract_plan.py` only recognizes `<<<PLAN:V1...>>>` and only parses a **single-task** payload.
- P3/P4/P5 templates emit TRACK/SPEC and a **multi-task** PLAN format.

Recommended fix (minimal surface area + backward compatibility):

1. Introduce `extract_sentinel.py` (new) with explicit kind:
   - `python3 extract_sentinel.py track --nonce <N>`
   - `python3 extract_sentinel.py spec --nonce <N>`
   - `python3 extract_sentinel.py plan --nonce <N>`
2. `extract_plan.py` becomes a **thin wrapper**:
   - If invoked as today, it calls `extract_sentinel.py plan ...`
3. Output JSON schemas:
   - `track`: `{track_id, track_name, phase, requirements[], goal, estimated_tasks, phase_complete?, phase_blocked?, reasons?}`
   - `spec`: `{track_id, title, overview, requirements[], functional[], non_functional[], acceptance_criteria[], out_of_scope[], existing_code[]}`
   - `plan`: `{track_id, task_count, tasks:[{task_id,title,summary,files[],acceptance[],estimated_diff,depends_on[]}] }`

Acceptance tests (must exist before refactor is considered done):
- Golden fixture inputs in `tests/fixtures/sentinels/` for TRACK/SPEC/PLAN.
- Unit tests assert strict rejection on:
  - wrong nonce
  - multiple openers/closers
  - unknown keys
  - malformed sections

### D3. Fix `verify.sh` (consume real task packet)

Current reality:
- `verify.sh` reads `${PROJECT_DIR}/TASK.md` for `ESTIMATED_DIFF` and `path=...`.
- The pipeline writes task packets to `.deadf/tracks/{track.id}/tasks/TASK_{NNN}.md`.

Recommended fix (retain backward compatibility):

1. Add a “task file selection” precedence:
   1) `--task-file <path>` (new CLI flag)
   2) env `VERIFY_TASK_FILE`
   3) if `STATE.yaml` exists: derive current task packet path from:
      - `track.id`
      - `track.task_current`
      - task file name `TASK_{NNN}.md`
   4) fallback: `TASK.md` (current behavior)
2. Use the selected task file to extract:
   - `ESTIMATED_DIFF`
   - `path=...` tokens (or `- path:` format if you standardize that)
3. Make “out-of-scope edits” policy explicit:
   - Keep WARN-only by default (current behavior)
   - Optional strict mode via env or `POLICY.yaml` to fail when changed files are not in FILES list.

### D4. Align `ralph.sh` with the canonical P1 kick

Current reality:
- `.pipe/p1/p1-cron-kick.sh` + `.pipe/p1/P1_CYCLE_KICK.md` are the canonical launcher/template pair.
- `ralph.sh` builds its own kick message (does not match P1 template fields) and depends on `RALPH_DISPATCH_CMD`.

Recommended end state:

Option (recommended): **make `.pipe/runtime/launchers/kick-once.sh` the canonical spawner** and make `ralph.sh` a loop wrapper around it.

Concrete changes:
1. `ralph.sh` stops assembling `CYCLE_MESSAGE` and stops requiring `RALPH_DISPATCH_CMD`.
2. Each loop iteration calls:
   - `.pipe/runtime/launchers/kick-once.sh` (which builds the canonical kick message from the template and spawns `claude --print ...`)
3. `ralph.sh` becomes responsible only for:
   - max-iterations enforcement
   - time budget enforcement across multiple cycles
   - optional sleeps/backoff between cycles
   - log aggregation (if desired), but not kick-message format

If you need to preserve `RALPH_DISPATCH_CMD` for remote orchestrator execution, keep it as a *non-default* mode:
- `RALPH_MODE=remote` uses dispatch command
- default `RALPH_MODE=local` uses the P1 launcher

Priority note: do **not** shrink `CLAUDE.md` until the kick path is canonical and stable, otherwise “binding contract” references will drift again.

---

## E) Implementation Plan (ordered phases, risks, git strategy, effort)

### E1. Phase order (recommended)

**Phase 0 — Baseline + freeze (0.5 day)**
- Confirm current end-to-end behavior (even if partially broken): document what works.
- Create fixtures for sentinel blocks (TRACK/SPEC/PLAN/VERDICT/QA_REVIEW/REFLECT).

**Phase 1 — Contracts become executable (1–2 days)**
- Implement `extract_sentinel.py` + wrapper compatibility for `extract_plan.py`.
- Update `verify.sh` to support real task packet discovery (`STATE.yaml` → `.deadf/.../TASK_{NNN}.md`).
- Add integration test that runs:
  - parse PLAN output from fixture
  - simulate task packet
  - run `verify.sh` against a tiny git diff fixture

**Phase 2 — Canonical launcher unification (0.5–1 day)**
- Make `ralph.sh` call `.pipe/runtime/launchers/kick-once.sh` (or explicitly choose remote mode).
- Remove duplicate kick-message assembly paths.

**Phase 3 — Restructure `.pipe/` (1 day)**
- Create `.pipe/runtime/`, `.pipe/preflight/`, `.pipe/workbench/`.
- Move files with `git mv`, update references.
- Add compatibility shims for one release window.

**Phase 4 — Shrink `CLAUDE.md` + add `.claude/` rules/imports (1 day)**
- Create `.claude/rules/*` (small).
- Create `.claude/imports/*` (action specs + grammars).
- Rewrite `CLAUDE.md` to ≤300 lines, replacing bulk with `@import` pointers.

**Phase 5 — Deletion/cleanup + documentation (0.5–1 day)**
- Remove deprecated `.pipe/p*` folders after the deprecation window.
- Update `README.md` to declare canonical entrypoints and paths.

### E2. Risk assessment

Top risks and mitigations:

1. **Claude auto-load token blowup** (by moving too much into `.claude/rules/`)
   - Mitigation: keep `.claude/rules/` invariant-only; put bulk in `.claude/imports/`.
2. **Breaking runtime by renaming templates**
   - Mitigation: two-step migration + compatibility shims + one end-to-end green run before deletion.
3. **Parser drift reappears**
   - Mitigation: fixture-based tests are required for each grammar and tool.
4. **Multiple “kick” paths remain**
   - Mitigation: pick one canonical spawner (`kick-once.sh`) and have every other entrypoint call it.

### E3. Git strategy

- Use short-lived branches per phase:
  - `restructure-phase1-parsers`
  - `restructure-phase2-launcher`
  - `restructure-phase3-layout`
  - `restructure-phase4-claude-split`
- Prefer `git mv` for history continuity.
- Require a green “one full cycle” integration test before merging Phase 3+.
- Tag stable milestones:
  - `restructure-m1-contracts-executable`
  - `restructure-m2-launcher-canonical`
  - `restructure-m3-layout-clean`
  - `restructure-m4-claude-slim`

### E4. Effort estimates (rough)

- Phase 1 (parsers + verify.sh): 1–2 days
- Phase 2 (launcher unification): 0.5–1 day
- Phase 3 (layout + rename + shims): 1 day
- Phase 4 (CLAUDE split + .claude rules/imports): 1 day
- Phase 5 (cleanup + docs): 0.5–1 day

Total: ~4–6 focused engineering days.

