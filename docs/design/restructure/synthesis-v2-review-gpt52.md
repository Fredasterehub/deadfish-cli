# Restructure Synthesis v2 — GPT-5.2 Review

## Verdict: NEEDS_REVISION

## Findings (if any)

### [CRITICAL] Phase 2 depends on Phase 3 (kick template path)
- **Location:** Section F3 (Kick unification), Section G Phase 2 vs Phase 3
- **Issue:** `kick.sh` is specified to read `.deadf/templates/kick/cycle-kick.md`, but Phase 2 (launcher unification) runs before Phase 3 (file layout restructure that moves templates into `.deadf/templates/`). As written, Phase 2 cannot be implemented/tested without either (a) pre-creating that template path or (b) performing template moves early.
- **Fix:** Either reorder phases (do Phase 3 before Phase 2), or explicitly add a Phase 1/2 step: create/move `cycle-kick.md` into `.deadf/templates/kick/` before implementing `kick.sh` and updating launchers.

### [CRITICAL] Sentinel contract set and parser subcommands don’t match (missing `reflect`, inconsistent `qa` naming)
- **Location:** Section A `contracts/sentinel/` (includes `reflect.v1.md`, `qa-review.v1.md`), Section F1 (`parse-blocks.py` subcommands list)
- **Issue:** The contract directory lists 6 grammars including `reflect.v1.md`, but `parse-blocks.py` subcommands omit `reflect`. Also the grammar is named `qa-review.v1.md` while the CLI examples use `parse-blocks.py qa ...` and elsewhere the pipeline uses `qa.review` and `qa-review.md`. This mismatch will cause unclear mapping (which grammar file does `qa` load?) and blocks implementation of the reflect step if it’s meant to be parsed/verified deterministically.
- **Fix:** Make the mapping explicit and consistent:
  - Add `parse-blocks.py reflect` (or declare reflect is not parsed and remove `reflect.v1.md`).
  - Choose one canonical identifier for QA (`qa` vs `qa_review` vs `qa-review`) and align: grammar filename, parser subcommand, DECIDE action, template filename.

### [CRITICAL] “No workflow creep” list contradicts the target layout (planning/runs)
- **Location:** Section A (includes `.deadf/planning/runs/...`), Section H bullet 8 (“planning/runs per-cycle workbench — defer”)
- **Issue:** The layout includes `planning/runs/<cycle-id>/summary.md` while Section H explicitly rejects `planning/runs/` as not MVP.
- **Fix:** Either (a) remove `planning/` from the target layout and all phase tasks, or (b) keep it but move it out of “explicitly don’t do” and clearly mark it as optional debug scaffolding that is not created/enabled in MVP.

### [HIGH] Manifest/update/revert capabilities are specified but the CLI wrapper is explicitly rejected
- **Location:** Section A (`manifest.yaml`), Section F5 (`deadf update` / `deadf revert` described), Section H bullets 5–6 (reject `deadf` CLI wrapper and `deadf revert`)
- **Issue:** The plan claims operational behaviors (`deadf update`, `deadf revert`) enabled by `manifest.yaml`, but the same plan rejects building a CLI wrapper and rejects the revert command. This is both contradictory and an implementation gap (how are update/revert invoked and maintained?).
- **Fix:** Pick one:
  - If CLI is out of scope: rename these to scripts (e.g., `.deadf/bin/update.sh`, `.deadf/bin/revert.sh`) or document manual workflows; keep `manifest.yaml` as a passive artifact only.
  - If `deadf update` is in scope: remove the rejection item and define command surface + entrypoint.
  - If revert is deferred: remove “deadf revert” wording from F5 and describe future intent without implying current behavior.

### [HIGH] Binder “explicit reads, no @import” is not fully specified given auto-loaded `.claude/rules/`
- **Location:** Section B (`.claude/rules/` “auto-loaded invariants”), Section C (“No `@import` anywhere” and “explicit `read` calls”)
- **Issue:** The plan treats `.claude/rules/` as auto-loaded platform behavior while simultaneously making “explicit reads” a binding principle for debuggability and platform-proofing. If the platform doesn’t auto-load (or changes), required invariants may silently disappear, defeating the stated goal.
- **Fix:** Make the contract platform-proof by specifying one of:
  - CLAUDE.md must explicitly instruct the orchestrator to `read` the four `.claude/rules/*.md` files at cycle start (even if they are also auto-loaded).
  - Or, declare `.claude/rules/` as an allowed platform dependency and adjust Principle #3 wording to: “No `@import`; explicit reads for pipeline contracts/templates.”

### [HIGH] State/action taxonomy is internally inconsistent (phase vs action IDs vs verify/repair steps)
- **Location:** Section D “Action IDs”, Section D “STATE.yaml Field Updates”, Section C “DECIDE Table”
- **Issue:** Action IDs are granular (`verify.criteria`, `docs.reflect`, `repair.format`, etc.), but the proposed `phase:` enum in STATE.yaml collapses to `task | qa.review | complete ...` and does not include verify/repair action IDs. It’s unclear whether `phase` stores an action ID, a coarse stage, or both; this ambiguity blocks writing the DECIDE table and reliable resume semantics.
- **Fix:** Define an unambiguous state model, e.g.:
  - `state.current_action: <semantic action id>` (single source of truth)
  - Optional `state.stage: bootstrap|track|task|verify|repair|qa|complete` for grouping
  - Ensure DECIDE table conditions reference the same canonical field(s).

### [MEDIUM] YAML-frontmatter parsing snippet is underspecified/fragile
- **Location:** Section F2 (`verify.sh` parsing snippet)
- **Issue:** The snippet pipes the frontmatter block including the `---` delimiters into `yq` (`sed -n '/^---$/,/^---$/p'`), which many `yq` variants will not parse as valid YAML (because the delimiters are not YAML content). The plan also assumes `yq` is “already available on system” without defining version/variant (mikefarah vs python yq) and behavior.
- **Fix:** Specify the exact `yq` implementation/version the repo supports and a delimiter-stripping extraction method (or implement parsing in `parse-blocks.py` / a small python helper with pinned behavior).

### [MEDIUM] Contract file naming/versioning policy isn’t fully spelled out
- **Location:** Section A `contracts/sentinel/*.v1.md`, Section C binder references
- **Issue:** The plan uses versioned filenames (e.g., `plan.v1.md`) but doesn’t define how upgrades work (v1→v2), how templates declare which version they target, and how the orchestrator chooses which grammar to read.
- **Fix:** Add a simple rule: templates and DECIDE table reference exact versioned grammar paths; upgrades require adding `*.v2.md` and updating DECIDE table/template pointers in one commit.

### [LOW] Dual “docs/” directories may confuse contributors without a guardrail
- **Location:** Section A (`.deadf/docs/` runtime living docs), Section B (`docs/` design artifacts)
- **Issue:** Two `docs/` concepts exist (repo-level `docs/` vs deployed `.deadf/docs/`). This is workable but easy to mis-edit.
- **Fix:** Add one explicit note in README (or `examples/project-structure.md`) clarifying “repo docs” vs “deployed docs”, and which ones are copied to target projects.

## Summary
This synthesis is close, but it contains a few true blockers: phase ordering around `kick.sh` vs template moves, and a mismatched sentinel/parsing contract set (notably `reflect` and QA naming). There are also internal contradictions around the rejected CLI/revert work and the inclusion of `planning/runs/`, plus ambiguity in how STATE.yaml represents actions vs phases. Tightening these points (with consistent identifiers and an explicit, platform-proof binder read sequence) should make the plan implementation-ready without expanding scope.
