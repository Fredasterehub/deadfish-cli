# Phase 1a QA Review — Opus

## Verdict: NEEDS_FIXES

---

## Findings

### [MAJOR] Closure state leak — config reuse causes false duplicate-ID errors

- **Location:** `parse-blocks.py` lines ~420 (`acceptance_items`), ~450 (`warnings`) in `make_plan_config()`, and ~630 (`success_items`) in `make_spec_config()`
- **Issue:** `acceptance_items`, `success_items`, and `warnings` are mutable lists defined inside `make_*_config()` and captured by closures (`parse_acceptance`, `parse_success`). These lists accumulate items across calls to `extract_block()` when the same `BlockConfig` object is reused. On the second parse, duplicate-ID checks fire incorrectly:
  ```
  First parse:  OK (1 AC)
  Second parse: "duplicate acceptance id 'AC1'" — FALSE POSITIVE
  ```
- **Impact:** Safe in the CLI path (one config per process), but a library-level **correctness bug** that will bite anyone importing `parse-blocks.py` as a module or adding batch processing.
- **Fix:** Either (a) reset these lists at the start of each `extract_block` / `parse_payload` call, (b) move them into `parse_payload` and thread them through section parsers, or (c) document configs as single-use. Option (b) is cleanest — add an optional `state` dict to `BlockConfig` that gets cleared per parse.

### [MINOR] Verdict ANSWER field accepts quoted values contrary to spec

- **Location:** `parse-blocks.py` `make_verdict_config()` — `field_quoted` dict; `verdict.v1.md` says type is `enum`
- **Issue:** The `field_quoted` dict for verdict only has `{"REASON": True}`. `ANSWER` is not listed, so `ANSWER="YES"` (quoted) parses successfully as `"YES"` and passes validation. The grammar spec defines ANSWER as an enum (bare value), so quoting should be rejected.
- **Fix:** Add `"ANSWER": False` to `field_quoted` in `make_verdict_config()`.

### [MINOR] Opener/closer regexes allow trailing whitespace not documented in grammar specs

- **Location:** All 6 `make_*_config()` functions — opener/closer regexes end with `\s*$`
- **Issue:** Every grammar spec documents strict regexes like `^<<<PLAN:V1:NONCE=[0-9A-F]{6}>>>$` (no trailing whitespace). The parser adds `\s*` before `$`, silently accepting `<<<PLAN:V1:NONCE=4F2C9A>>>   `. This is pragmatic (LLMs add trailing spaces) but undocumented.
- **Fix:** Either update all 6 grammar spec docs to show `\s*` in the regexes, or add a note: "Trailing whitespace on delimiter lines is tolerated."

### [MINOR] Missing negative-case fixtures for 4 of 6 block types

- **Location:** `tests/fixtures/sentinels/`
- **Issue:** Only `plan` and `track` have `*-invalid.txt` fixtures. Missing:
  - `spec-invalid.txt` (e.g., missing SCOPE, empty SUCCESS_CRITERIA)
  - `verdict-invalid.txt` (e.g., ANSWER=MAYBE, missing REASON)
  - `reflect-invalid.txt` (e.g., invalid doc name, empty SCRATCH)
  - `qa-review-invalid.txt` (e.g., FINDINGS_COUNT mismatch, invalid severity)
- **Impact:** Negative paths are tested implicitly via `plan-invalid.txt` patterns, but block-specific validation logic (enum values, conditional fields, count mismatches) has zero fixture coverage.
- **Fix:** Add at least one `*-invalid.txt` per block type. Suggested coverage: one constraint violation per fixture.

### [INFO] Dead `warnings` parameter in `parse_payload`

- **Location:** `parse-blocks.py` `parse_payload()` — `warnings: list[str] = []` on ~line 207, passed to `config.validator(fields, sections, warnings)`
- **Issue:** The `warnings` list created in `parse_payload` is always empty and passed to validators as a parameter, but `validate_plan` ignores it (`_warnings`) and returns the closure-captured `warnings` instead. The parameter serves no purpose for any block type.
- **Impact:** No functional bug — just dead code that makes the architecture confusing.
- **Fix:** Either remove the `warnings` parameter from the validator signature and `parse_payload`, or route all warnings through it instead of closures.

### [INFO] QA_REVIEW enum fields (VERDICT, RISK, C0–C5) not enforced as bare in `field_quoted`

- **Location:** `make_qa_review_config()` — `field_quoted` has `"VERDICT": False`, `"RISK": False`, `"C0": False` etc. ✓ These are correct.
- **Issue:** Not actually a bug — verified that all enum fields in QA_REVIEW do correctly enforce `False` (unquoted). Included for completeness: verdict block's `ANSWER` field is the only enum missing this enforcement (see finding above).

---

## Cross-Validation Summary

### Parser vs Grammar Specs

| Block | Opener/Closer | Fields | Constraints | Sections | Verdict |
|-------|:---:|:---:|:---:|:---:|:---:|
| plan | ✅¹ | ✅ | ✅ | ✅ | PASS |
| track | ✅¹ | ✅ | ✅ | n/a | PASS |
| spec | ✅¹ | ✅ | ✅ | ✅ | PASS |
| verdict | ✅¹ | ⚠️² | ✅ | n/a | MINOR |
| reflect | ✅¹ | ✅ | ✅ | ✅ | PASS |
| qa-review | ✅¹ | ✅ | ✅ | ✅ | PASS |

¹ Trailing `\s*` not in spec  
² ANSWER not enforced as bare

### Fixtures vs Parser

| Fixture | Expected | Actual | Status |
|---------|----------|--------|:---:|
| plan-valid.txt | exit 0 + JSON | ✅ | PASS |
| plan-invalid.txt | exit 1 (unquoted TITLE) | ✅ | PASS |
| plan-multi-task.txt | exit 1 (2 openers) | ✅ | PASS |
| track-valid.txt | exit 0 + JSON | ✅ | PASS |
| track-invalid.txt | exit 1 (REASONS missing) | ✅ | PASS |
| spec-valid.txt | exit 0 + JSON | ✅ | PASS |
| verdict-valid.txt | exit 0 + JSON | ✅ | PASS |
| reflect-valid.txt | exit 0 + JSON | ✅ | PASS |
| qa-review-valid.txt | exit 0 + JSON | ✅ | PASS |

### Backward-Compat Wrapper (`extract_plan.py`)

- ✅ Correctly delegates to `parse-blocks.py plan`
- ✅ Passes `--nonce` argument
- ✅ Forwards stdout, stderr, and exit code
- ✅ Uses `os.path.dirname(__file__)` for relative path resolution
- ✅ Uses `sys.executable` to ensure same Python interpreter

### Security

- ✅ Path traversal blocked (`..`, absolute paths)
- ✅ Path charset restricted to `[a-zA-Z0-9_./-]`
- ✅ 16KB payload size cap enforced
- ✅ No `eval`, `exec`, `pickle`, or shell invocations in parser
- ✅ No file I/O beyond stdin/stdout/stderr
- ✅ Stdlib-only (no external dependencies)

---

## Summary

The unified parser is well-structured, comprehensive, and functionally correct for the CLI use case. The `BlockConfig` dataclass + closure-based validators pattern is clean and extensible. All 9 fixtures pass/fail as expected, the backward-compat wrapper works, and security posture is solid.

**One major fix needed:** the closure state leak in `acceptance_items`/`success_items`/`warnings` will cause incorrect behavior if configs are reused (library use, batch mode, tests). This should be fixed before Phase 1b to avoid a latent bug in the test harness.

**Three minor fixes:** enforce `ANSWER` as bare in verdict, document trailing-whitespace tolerance in specs, and add negative fixtures for the 4 uncovered block types.

Total: 1 MAJOR, 3 MINOR, 2 INFO.
