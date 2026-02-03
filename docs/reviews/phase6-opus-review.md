# Phase 6 QA Review — Validation Suite

**Reviewer:** opus-subagent  
**Date:** 2026-02-03  
**Verdict:** CLEAN

---

## test-parsers.sh

### Fixture Coverage
All 13 fixtures present and tested:
- 6 valid: `plan-valid`, `track-valid`, `spec-valid`, `verdict-valid`, `reflect-valid`, `qa-review-valid`
- 6 invalid: `plan-invalid`, `track-invalid`, `spec-invalid`, `verdict-invalid`, `reflect-invalid`, `qa-review-invalid`
- 1 multi-task: `plan-multi-task` (contains 2 plan blocks, both parsed independently)

✅ All 13 pass.

### Block Type Mapping
Case statement correctly maps `{type}-*.txt` → block type for all 6 types. Unknown prefixes are caught and reported as FAIL. ✅

### Exit Code Assertions
- `*-valid.txt` → expects exit 0 ✅
- `*-invalid.txt` → expects exit ≠ 0 ✅
- `plan-multi-task.txt` → expects exit 0 ✅
- Default `expect_ok=0` before conditionals is safe since the only paths are valid/invalid/multi-task suffixes.

### Multi-task Splitting
Inline Python splits `plan-multi-task.txt` into individual blocks via opener/closer regex, then validates each through `parse-blocks.py`. Temp directory is cleaned up on both success and failure paths. ✅

### Verdict Criterion Extraction
Uses `rg` to extract `VERDICT:V1:AC1:NONCE=...`, then `cut -d: -f3` to get `AC1`. Verified against fixture content — works correctly. ✅

### Heredoc Escaping
The `<<'PY'` single-quoted heredoc passes content literally to Python. The `\\s` in `r'...'` raw strings becomes `\s` to the regex engine (whitespace metaclass). String `"\\n"` becomes `\n` (newline). All correct. ✅

### Summary Logic
Counters `passed`/`failed`/`total` are incremented correctly in all paths (including early-exit paths for missing nonce / unknown type). Exit 1 on any failure. ✅

### Run Result
```
13 passed, 0 failed, 13 total
```

---

## test-templates.sh

### Lint Check
Runs `lint-templates.py --verbose` and asserts exit 0. ✅

### Manifest Count vs Disk
Parses `manifest.yaml` for file paths, checks each exists on disk, compares counts. Reports missing count on failure. ✅

### Hash Spot-Check
Samples 3 random entries (or fewer if manifest is small), computes `sha256sum` and compares against manifest values. ✅

### Run Result
```
5 passed, 0 failed, 5 total
```

---

## Minor Observations (non-blocking)

1. **Hardcoded absolute path** in `test-templates.sh` — the inline Python uses `/tank/dump/DEV/deadfish-cli/.deadf/manifest.yaml` rather than a relative path. Works in this repo layout but not portable. Low risk since these are project-internal tests.

2. **No per-test timeout** — a hanging `parse-blocks.py` would block the entire runner. Unlikely in practice since the parser operates on small fixture files with no I/O waits.

3. **`expect_ok` default** — if a fixture has an unexpected suffix (neither `-valid.txt`, `-invalid.txt`, nor `plan-multi-task.txt`), it silently defaults to expecting success. The case statement for block-type mapping would likely catch truly anomalous files first, so this is a theoretical gap only.

4. **Random hash sampling** — `shuf -n 3` means different files are checked each run. Good for coverage over time, but a specific regression could pass intermittently. Acceptable trade-off for a spot-check.

---

## Verdict: **CLEAN**

Both test runners are correct, cover all specified fixtures, assert the right exit codes, and produce accurate summaries. The minor observations above are stylistic/hardening concerns, not functional defects. No fixes required.
