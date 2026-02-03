# P10 Format-Repair Implementation Review — Opus 4.5

**Reviewer:** Claude Opus 4.5 (sub-agent)
**Date:** 2026-02-02
**Files Reviewed:**
1. `.pipe/p10/P10_FORMAT_REPAIR.md` — NEW universal format-repair template
2. `CLAUDE.md` — updated format-repair policy (v2.4.2)
3. `.pipe/p2-codex-prompt.md` — consistency mirror

**Reviewed Against:**
1. `.pipe/p10/synthesis-opus-orchestrator.md` — APPROVED design spec
2. `.pipe/p10/synthesis-review-gpt52-r2.md` — final review findings

---

## Verdict: **CLEAN**

All three files faithfully implement the P10 design spec with no regressions.

---

## Check 1: P10_FORMAT_REPAIR.md Template

### Universal Structure ✅
- IDENTITY → TASK → HARD CONSTRAINTS → PARSER ERROR → MICRO_HINT → ORIGINAL OUTPUT → FORMAT CONTRACT → COMMON FIXES → REPAIR CHECKLIST → OUTPUT
- Matches the merged prompt template from synthesis spec exactly in structure.

### All Placeholders ✅
- `{BLOCK_TYPE}`, `{NONCE}`, `{CRITERION_ID}`, `{PARSER_ERROR}`, `{MICRO_HINT}`, `{ORIGINAL_OUTPUT}`, `{FORMAT_CONTRACT}` — all present.

### COMMON FIXES Cookbook ✅
- 16 entries (expanded from spec's 8). Template EXCEEDS spec requirements by covering additional error patterns:
  - Added: `"expected exactly 1"`, `"opener must appear before closer"`, `"criterion mismatch"`, `"ANSWER must be unquoted"`, `"REASON must be quoted"`, `"REASON cannot be empty"`, `"REASON exceeds 500 chars"`, `"REASON must be single-line"`, `"duplicate field"`, `"tab character"`, `"Curly quotes / unicode quotes"`
- All original spec entries preserved; additional entries are strictly additive and correct.

### REPAIR CHECKLIST (9 items) ✅
1. One opener + one closer; opener first ✅
2. Opener/closer matches contract (block name/version/ids/nonce) ✅
3. No text outside block ✅
4. All required keys; no unknown keys ✅
5. Quoting (ASCII `"` only; no internal `"`; escape alternatives) ✅
6. No tabs ✅
7. Per-field length limits ✅
8. Avoid backslashes entirely ✅ (escape guard)
9. No absolute paths / `..` traversal (path guard) ✅

### Block-Only Output Instruction ✅
- "Output ONLY the corrected sentinel block. No prose. No code fences." in both HARD CONSTRAINTS and OUTPUT sections.

### Deviations from Spec Template (All Improvements, Not Regressions)
- Checklist item 2: added "ids" to "(block name/version/ids/nonce)" — correct enhancement for VERDICT blocks which include criterion_id
- Checklist item 5: rephrased escape guidance to be more explicit ("Do not escape quotes. Use single quotes or backticks") — clearer than spec's "Convert curly quotes to ASCII"
- Checklist item 8: separated backslash guard from escape guidance (spec had them combined in item 8) — cleaner separation of concerns
- COMMON FIXES: expanded from 8 to 16 entries — all additions are real parser error patterns; none conflict with spec

---

## Check 2: CLAUDE.md P10 Section

### Per-Block Trigger Table ✅
- 4-row table with columns: Block Type | Validation Mechanism (Current) | Invoke P10 When | After P10 Retry Fails
- PLAN: `extract_plan.py` exit 1 + actionable stderr → parse fails with `ParseError` → `CYCLE_FAIL`
- TRACK/SPEC/multi-PLAN: **not yet supported** → N/A (skip P10 until parser exists) → `CYCLE_FAIL`
- VERDICT: **pre-parse regex/shape validation** (explicit: don't key on `build_verdict.py` exit code) → malformed → `NEEDS_HUMAN`
- REFLECT: grammar validation per P9.5 spec → malformed → Non-fatal degrade (`ACTION=NOP`, log warning)

### Parser Reality Notes ✅
- TRACK/SPEC/multi-PLAN row explicitly states "not yet supported by deterministic parser"
- Standalone parser mismatch warning paragraph below table
- PLAN row specifies "ParseError" (not generic exit code)
- VERDICT row notes "don't key on `build_verdict.py` exit code" — matches synthesis spec finding about exit-0-with-NEEDS_HUMAN

### Empty Output Guard with Per-Block Fallback ✅
- `< 50 chars` → skip P10 → "follow the per-block failure policy"
- Per-block failure policy is defined in the trigger table (PLAN→CYCLE_FAIL, VERDICT→NEEDS_HUMAN, REFLECT→NOP degrade)

### Traceback Detection ✅
- "If the error contains a Python traceback/crash: skip P10; follow the per-block failure policy (tooling bug)."

### P10 Attempt Tracking Separate from retry_count ✅
- "Track P10 attempts separately from `task.retry_count` (policy + metrics/logging only)."

### Reference to Template ✅
- "Template: `.pipe/p10/P10_FORMAT_REPAIR.md`"

### Nonce Lifecycle Table ✅
- Format-repair retry row: "**Same nonce** (same cycle)" — present in Sentinel Parsing section

### Truncation ✅
- "> 8K chars: include first 4K + last 4K with `[...truncated...]`"

---

## Check 3: CLAUDE.md ↔ p2-codex-prompt.md Consistency

### P10 Section ✅
- Byte-for-byte identical between CLAUDE.md lines 788-814 and p2-codex-prompt.md lines 1017-1043 (verified via diff — no output, perfect match).

### Surrounding Context ✅
- Nonce lifecycle table includes format-repair row in both files.
- verify_task pre-parse regex validation section unchanged in both.
- P9.5 reflect section unchanged in both.

---

## Check 4: No Regressions to P7/P9/P9.5 Specs

### P7 (implement_task) ✅
- Template reference (`.pipe/p7/P7_IMPLEMENT_TASK.md`), binding rules, dispatch command — all unchanged.

### P9 (verify_task) ✅
- Three-stage verification intact.
- DET/LLM tagging rules unchanged.
- Per-criterion evidence bundle spec unchanged.
- Pre-parse regex validation still present with its own inline repair retry (the existing P9 "one repair retry" for verdict blocks).
- Combined verdict logic table unchanged.
- `build_verdict.py` stdin format unchanged.

### P9.5 (reflect) ✅
- Part B living docs evaluation fully intact.
- REFLECT sentinel parsing regex unchanged.
- 4-action protocol unchanged.
- Budget enforcement unchanged.
- Non-fatal failure behavior unchanged.

### Interaction between P9 inline retry and P10
- P9's verify_task already had a 1-retry inline repair for verdict blocks (line 420 in CLAUDE.md).
- P10's per-block trigger table adds the universal format-repair template as the mechanism for that retry.
- No conflict: P10 formalizes what P9 described informally. The "one repair retry" policy is consistent.

---

## Review Findings from synthesis-review-gpt52-r2.md: Resolution Status

| Finding | Status |
|---------|--------|
| FORMAT_CONTRACT drift clarification | **ADDRESSED** — trigger table's "parser reality" notes make clear that P10 cannot fix parser-contract mismatches |
| Empty-output guard inconsistency (Opus summary bullet vs detailed section) | **N/A in implementation** — the synthesis doc's summary section isn't carried into CLAUDE.md; only the authoritative "Guards" section is |
| TRACK/SPEC/multi-PLAN wording tightening | **ADDRESSED** — table says "N/A (skip P10 until parser exists)" which is the tightened wording |

---

## Minor Observations (Not Blocking)

1. **COMMON FIXES expanded scope**: Template has 16 entries vs spec's 8. All additions are correct real-world error patterns. This is an improvement, not a deviation.

2. **Checklist item 5 wording divergence**: Template says "Do not escape quotes. Use single quotes or backticks inside quoted strings." Spec says "Convert curly quotes to ASCII." The template's version is more actionable — it covers both the curly-quote case AND the general escape avoidance. Improvement, not regression.

3. **HARD CONSTRAINTS "one closer line" vs "one closer"**: Template adds "line" to "exactly one opener line and one closer line" where spec had "exactly one opener and one closer line." Trivially clearer. No impact.

---

## Summary

All three implementation files are faithful to the approved design spec. The P10_FORMAT_REPAIR.md template exceeds spec requirements with an expanded COMMON FIXES cookbook (16 vs 8 entries) while preserving all required structural elements. CLAUDE.md's P10 section correctly implements per-block trigger policies with parser reality notes, empty output guards, traceback detection, and separate attempt tracking. The p2-codex-prompt.md mirror is byte-identical to CLAUDE.md for the P10 section. No regressions to P7, P9, or P9.5 specs were found.

**Verdict: CLEAN** ✅
