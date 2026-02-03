# Restructure Synthesis v2 — GPT-5.2 R3 Review

## Verdict: NEEDS_REVISION

## R2 Fix Verification

1. **[FIXED] HIGH: qa-review vs qa.review naming drift**
   - The two-layer naming convention is now explicit in Section F1: dotted **Action IDs** (e.g., `qa.review`) vs hyphenated **file identifiers** (e.g., `qa-review`), with an explicit DECIDE-table mapping column from action ID → grammar file → parser subcommand.
   - Caveat: there is still a stray `qa` shorthand mention elsewhere (see New Findings), but the core `qa.review` ↔ `qa-review` mapping drift is resolved.

2. **[FIXED] HIGH: Phase 1a parser list dropped reflect/qa-review**
   - Phase 1a now lists the full subcommand set explicitly: `track/spec/plan/verdict/reflect/qa-review`.

3. **[FIXED] MEDIUM: verify.sh STATE.yaml field alignment**
   - Section D now explicitly declares `track.id`, `track.task_current`, and `track.packet_path` as guaranteed fields (and notes they coexist with `stage`/`current_action`), aligning the `verify.sh` auto-discovery snippet with the state model.

## New Findings (if any)

### [HIGH] Template path derivation in the binder contract conflicts with semantic action IDs
- **Where:** Section C “Cycle Protocol” Step 4: “read the action's template from `.deadf/templates/<phase>/<action>.md`”.
- **Issue:** Action IDs are defined as dotted/underscored (e.g., `track.write_spec`), while template filenames are hyphenated (e.g., `write-spec.md`). As written, Step 4 implies the template path can be computed from the selected action, but no deterministic mapping function is specified (and naive substitution will fail).
- **Why it matters:** This is a real implementation trap: an orchestrator coded to derive paths from `current_action` will not reliably find templates.
- **Fix:** Make the “Template” column in the DECIDE table explicitly canonical (“read the exact path from the row”), or define a single deterministic transform from action ID → template path and use it consistently (and update the example “Before executing action …” wording to match).

### [MEDIUM] Residual `qa` shorthand contradicts the “never use bare qa” rule and omits reflect
- **Where:** Section A tool list: `parse-blocks.py # unified sentinel parser (track/spec/plan/verdict/qa)`, vs Section F1 “Never use bare `qa` as a shorthand anywhere.”
- **Issue:** This reintroduces ambiguity about whether the parser has a `qa` subcommand (it should be `qa-review`) and also repeats the earlier “reflect omitted” pattern (even if only in a comment).
- **Fix:** Update the parenthetical to `track/spec/plan/verdict/reflect/qa-review`, or drop the parenthetical entirely to avoid it drifting again.

### [MEDIUM] Reflect/qa-review coverage is still incomplete in fixtures + validation checklist
- **Where:** Section B sentinel fixtures list omits any `reflect-*.txt`, and Phase 6 validation only lists parser checks for `plan` and `track`.
- **Issue:** The plan now correctly specifies `reflect` and `qa-review` in the parser interface, but the validation plan doesn’t force them to stay working.
- **Fix:** Add `tests/fixtures/sentinels/reflect-valid.txt` (and optionally an invalid fixture) and extend the Phase 6 checklist to run `parse-blocks.py reflect …` and `parse-blocks.py qa-review …`.

### [LOW] DECIDE table column naming is inconsistent (“Output Grammar” vs “Grammar”)
- **Where:** Section C lists DECIDE columns ending with “Output Grammar”; Section F1 calls it an explicit “Grammar” column.
- **Issue:** Minor, but it’s an avoidable ambiguity in a document that’s trying to be drift-proof.
- **Fix:** Pick one label and use it consistently (e.g., “Output Grammar” everywhere).

## Summary

- All three R2 findings are addressed in the v2 text, and the state/schema alignment for `verify.sh` is now explicit.
- R1 #2 is improved but still not “fully resolved” due to remaining internal contradictions and missing validation coverage for `reflect`/`qa-review`.
- With the binder Step 4 template-path rule clarified and the remaining `qa` shorthand + validation gaps closed, this synthesis should be genuinely implementation-ready.

