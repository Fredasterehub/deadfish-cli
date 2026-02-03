# Phase 1a Fixes Review — GPT-5.2

## Verdict: CLEAN

## Fix Verification

1. [FIXED] Closure state leak — `make_plan_config()` and `make_spec_config()` no longer capture mutable lists in closures for duplicate-ID checks or warnings. Duplicate-ID checks now run inside `validate_plan()` / `validate_spec()` using the per-parse `sections` dict, and vague-verb warnings are computed fresh per validation call.
2. [FIXED] Verdict ANSWER quoted — `make_verdict_config()` now sets `field_quoted["ANSWER"] = False`, so quoted `ANSWER="YES"` is rejected as required by the contract.
3. [FIXED] Trailing whitespace — all six grammar specs in `.deadf/contracts/sentinel/*.v1.md` include an explicit note that trailing whitespace on delimiter lines is tolerated by the parser.
4. [FIXED] Missing negative fixtures — new fixtures exist in `tests/fixtures/sentinels/` and each targets a distinct constraint:
   - `spec-invalid.txt`: missing required `SCOPE`
   - `verdict-invalid.txt`: invalid enum value `ANSWER=MAYBE`
   - `reflect-invalid.txt`: invalid `doc` value (`INVALID_DOC`)
   - `qa-review-invalid.txt`: `FINDINGS_COUNT` mismatch vs provided `FINDINGS` items

## New Findings (if any)

- None related to the 4 QA findings. (The `warnings` parameter passed through `parse_payload()` remains unused by current validators; this matches the prior INFO note and is still a safe-but-dead plumbing path.)

## Summary

All four Phase 1a QA findings are addressed with structurally correct fixes: state is no longer shared across parses, verdict quoting rules match the contract, specs document the delimiter whitespace tolerance, and negative fixtures now cover the remaining block types with distinct failure modes.
