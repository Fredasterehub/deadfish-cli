# Restructure Synthesis v2 — GPT-5.2 R2 Review

## Verdict: NEEDS_REVISION

## R1 Fix Verification

1. **CRITICAL: Phase 2 depends on Phase 3 (kick template path)** — **[FIXED]**
   - Phase 2 now explicitly pre-creates `.deadf/templates/kick/` and moves `cycle-kick.md` there as a Phase 2 pre-req, unblocking `.deadf/bin/kick.sh` without relying on Phase 3.

2. **CRITICAL: Sentinel contract set / parser subcommands mismatch (reflect missing, qa naming)** — **[PARTIALLY_FIXED]**
   - The contract set is corrected: `.deadf/contracts/sentinel/` includes `reflect.v1.md` and `qa-review.v1.md`, and the example parser interface includes `parse-blocks.py reflect` and `parse-blocks.py qa-review`.
   - However, a new internal naming contradiction was introduced: Section F1 claims “`qa-review` everywhere … DECIDE action”, but Section D defines the action ID as `qa.review` (dot) rather than `qa-review` (hyphen). If DECIDE rows/actions are expected to be grep-identical to grammar/template identifiers, this reintroduces drift risk.

3. **CRITICAL: planning/runs contradiction** — **[FIXED]**
   - `planning/runs/` is explicitly deferred/removed from the target layout (Section H + Section K).

4. **HIGH: manifest/CLI contradiction** — **[FIXED]**
   - `manifest.yaml` is explicitly scoped as a passive artifact only (Section F5 + Section K), and Section H explicitly defers CLI commands (`deadf` wrapper, update/revert).

5. **HIGH: .claude/rules/ vs explicit reads** — **[FIXED]**
   - CLAUDE.md LOAD step explicitly lists `.claude/rules/*.md` reads (Section C) while still allowing auto-load as a convenience (Design Principles #3 / Section K).

6. **HIGH: State taxonomy inconsistency** — **[FIXED]**
   - State is now a two-level model (`stage` + `current_action`) with clear intent and examples (Section D), and DECIDE conditions are stated to key off `current_action`.

7. **MEDIUM: yq parsing fragile** — **[FIXED]**
   - The plan pins the implementation to mikefarah/yq v4+ and uses delimiter-stripping extraction (Section F2). The approach avoids parsing the `---` lines as YAML.

8. **MEDIUM: Contract versioning policy missing** — **[FIXED]**
   - Section J defines versioned grammar filenames, template grammar comments, DECIDE table version pointers, and the upgrade/backward-compat rule.

9. **LOW: Dual docs/ confusion** — **[FIXED]**
   - Section K includes an explicit clarification that repo-level `docs/` is design history while deployed `.deadf/docs/` is runtime living docs, and that only `.deadf/docs/` deploys.

## New Findings (if any)

### [HIGH] “qa-review everywhere” contradicts semantic action ID
- **Location:** Section F1 (“Naming convention … `qa-review` everywhere … DECIDE action”) vs Section D (Action IDs table: `qa.review`)
- **Issue:** The plan simultaneously asserts that identifiers are canonical/grep-identical across grammar/parser/template/DECIDE, but then defines the DECIDE/STATE action as `qa.review` (dot) while grammar+parser+template are `qa-review` (hyphen). This is exactly the kind of drift `lint-templates.py` is meant to prevent, but the mismatch is at the *action ID* layer.
- **Fix:** Pick one canonical identifier strategy and apply it consistently:
  - Option A (recommended): keep semantic action IDs dotted (`qa.review`), and **remove/soften** the “qa-review everywhere / DECIDE action” claim; instead specify an explicit mapping column in DECIDE: `Action ID` (dotted) + `Output Grammar` (hyphenated type).
  - Option B: rename the action ID to `qa-review` (hyphen) and update all references (STATE schema examples, DECIDE table, templates) to match.

### [HIGH] Phase 1a subcommand list regresses reflect/qa-review coverage
- **Location:** Section G → Phase 1 → “Implement `parse-blocks.py` with subcommands (track/spec/plan/verdict/qa)”
- **Issue:** This bullet omits both `reflect` and `qa-review`, despite Section F1 and the contracts list clearly requiring them. This can realistically recreate the original “missing reflect” class of mismatch during implementation.
- **Fix:** Update Phase 1a to list the full set explicitly: `track/spec/plan/verdict/reflect/qa-review` (and avoid using `qa` as a shorthand anywhere).

### [MEDIUM] verify.sh task discovery keys may not match the new state model
- **Location:** Section F2 (`TRACK_ID=$(yq '.track.id' STATE.yaml)` and `TASK_NUM=$(yq '.track.task_current' STATE.yaml)`) vs Section D’s state model emphasis (`stage`, `current_action`)
- **Issue:** The new state excerpt does not show whether `.track.id` and `.track.task_current` remain authoritative fields in `state.v2.yaml`. If the schema migration removes/renames these, the “STATE.yaml-based task file auto-discovery” will break or silently misbehave.
- **Fix:** In Section D (or the schema quick reference in Section C), explicitly state the track/task locator fields required by `verify.sh` (e.g., `track.id`, `track.task_current`) and ensure they are part of `state.v2.yaml`. Alternatively, make `verify.sh` derive the active task file from `current_action` + a canonical “active task pointer” field that is guaranteed by schema.

## Summary

- All R1 CRITICAL/HIGH/MEDIUM/LOW items are addressed on paper, and most fixes are correctly applied.
- Two new inconsistencies reintroduce drift risk at the naming/interface boundary: `qa-review` vs `qa.review`, and a Phase 1a parser bullet that drops `reflect`/`qa-review`.
- One schema/interface alignment item needs explicit confirmation: which `STATE.yaml` fields `verify.sh` relies on under `state.v2.yaml`.

