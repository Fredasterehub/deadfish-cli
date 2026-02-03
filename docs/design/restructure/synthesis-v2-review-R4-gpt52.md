# Restructure Synthesis v2 — GPT-5.2 R4 Review

## Verdict: NEEDS_REVISION

## R3 Fix Verification

1. **[VERIFIED] HIGH: Template path derivation conflicts with semantic action IDs**
   - Section C “Cycle Protocol” Step 4 now states the **DECIDE table `Template` column is canonical** and the orchestrator must **not derive** the template path from the action ID: “read the action's template path from the DECIDE table's "Template" column (canonical, exact path — do NOT derive from action ID)”.

2. **[VERIFIED] MEDIUM: Residual `qa` shorthand in bin/ comment**
   - Section A tool list comment for `parse-blocks.py` now enumerates the full set: **`track/spec/plan/verdict/reflect/qa-review`**, removing the ambiguous bare `qa`.

3. **[VERIFIED] MEDIUM: Missing reflect/qa-review in fixtures + validation**
   - Section B fixtures list includes **`reflect-valid.txt`** and **`qa-review-valid.txt`** under `tests/fixtures/sentinels/`.
   - Phase 6 validation checklist includes explicit parser checks for both:
     - `parse-blocks.py reflect --nonce TEST < tests/fixtures/sentinels/reflect-valid.txt`
     - `parse-blocks.py qa-review --nonce TEST < tests/fixtures/sentinels/qa-review-valid.txt`

4. **[VERIFIED] LOW: DECIDE column naming inconsistency**
   - DECIDE table columns are consistently specified as: **Priority | Condition | Action | Template | Output Grammar**, and later text refers to the `Output Grammar` column (not a differently named “Grammar” column).

## New Findings (if any)

1. **[MEDIUM] CLAUDE.md “EXECUTE” step describes a template+worker+sentinel path that doesn’t fit `verify.facts`**
   - The synthesis explicitly defines `verify.facts` as **“(bin/verify.sh — no template)”** (Section D), and Phase 6 expects `verify.sh` to run.
   - But Section C “Cycle Protocol” Step 4 currently describes a single universal flow (“read template path” + “dispatch to worker model” + “parse sentinel output”), which is internally inconsistent for `verify.facts` (no template; output is a schema’d JSON result per `verify-result.v1.json`, not a sentinel block).
   - **Revision needed:** document the `verify.facts` exception in the binder contract (e.g., Template = `N/A`, Output Grammar = `verify-result.v1.json`, execution = run `.deadf/bin/verify.sh`, validation = JSON/schema check), or alternatively provide a dedicated template+sentinel contract for facts verification (but that would contradict the current “no template” statement).

2. **[LOW] Phase 6 “exclude docs/” note doesn’t match the shown grep command**
   - Phase 6 says the `.pipe/` reference grep is “excluding docs/”, but the example command as written does not implement that exclusion, which can cause false failures if archived design docs intentionally mention `.pipe/`.
   - **Revision needed:** either remove the “excluding docs/” parenthetical or adjust the command to actually exclude `docs/`.

## Summary

- All four R3 findings are addressed in `synthesis-v2-final.md` as written.
- Two remaining internal inconsistencies (not stylistic) keep this from being fully implementation-ready: the `verify.facts` execution path vs the universal “EXECUTE” flow, and the Phase 6 grep exclusion mismatch.

