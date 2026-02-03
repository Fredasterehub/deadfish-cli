# P9 Implementation Review — Opus 4.5

**Reviewer:** Claude Opus 4.5 (sub-agent)
**Date:** 2026-02-02
**Files reviewed:** P9_VERIFY_CRITERION.md, CLAUDE.md (v2.4.2), p2-codex-prompt.md
**Reviewed against:** synthesis-opus-orchestrator.md (spec), synthesis-review-gpt52-r2.md (required fixes), build_verdict.py (parser)

---

## Overall Verdict: **CLEAN** (with LOW advisories)

All CRITICAL and HIGH items from the GPT-5.2 r2 review have been addressed. The P9 template is spec-compliant and parser-compatible. The only findings are LOW-severity pre-existing divergences in p2-codex-prompt.md that predate this change.

---

## File 1: `.pipe/p9/P9_VERIFY_CRITERION.md`

### Template vs Synthesis Spec — **EXACT MATCH** ✅

The template is a character-perfect copy of the "Final Template (Merged)" section in `synthesis-opus-orchestrator.md`. All elements verified:

| Check | Status |
|-------|--------|
| Three-level verification (Exists → Substantive → Wired) | ✅ Present with concrete checklists |
| Block-only output instruction | ✅ "Output ONLY the verdict block — no other text." |
| Parser-safety: two lines only | ✅ "Output exactly two lines inside the block: ANSWER and REASON." |
| Parser-safety: no extra keys | ✅ "No other keys, no blank lines, no commentary." |
| Parser-safety: no quotes in REASON | ✅ "Do not use double quotes inside REASON" |
| Parser-safety: no backslashes | ✅ "Do not use backslashes — use forward slashes in paths." |
| Parser-safety: no code fences | ✅ "Do not use code fences anywhere in your output." |
| Conservative default | ✅ "If uncertain at any level: NO. False negatives retry; false positives ship broken code." |
| REASON specificity | ✅ "REASON must name the specific file, function, or behavior" |
| Locked rubric framing | ✅ "DECISION RULES (LOCKED RUBRIC)" |
| All placeholders present | ✅ All 12 placeholders accounted for |
| Simpler 5-section structure (not 0a/1/999) | ✅ IDENTITY → CRITERION → DECISION RULES → EVIDENCE BUNDLE → OUTPUT |
| Task context in evidence | ✅ Task id/title/summary + planned FILES |

**Findings: None.**

---

## File 2: `CLAUDE.md` (v2.4.2)

### GPT-5.2 R2 Required Fixes — All Resolved ✅

| R2 Finding | Status | Evidence |
|------------|--------|----------|
| Verdict block format: no more `ANSWER=YES or NO` literal | ✅ FIXED | Shows `ANSWER=YES` as example; rules say "Choose exactly one: `ANSWER=YES` or `ANSWER=NO` (unquoted)." |
| Repair trigger: pre-parse regex, not exit code 1 | ✅ FIXED | "do **not** key retries on exit code (it exits 0 on per-criterion parse errors)." + 3-step pre-parse regex protocol |
| Untagged criteria behavior defined | ✅ FIXED | "Untagged criteria are treated as `LLM:` and MUST emit an orchestrator warning log." (in both verify_task and Sentinel Parsing) |
| DET fast-path documented | ✅ FIXED | Full DET fast-path paragraph in verify_task Stage 2 |
| Evidence bundle composition spec | ✅ FIXED | Detailed 9-item bullet list with mapping heuristic |
| Nonce format constraint | ✅ FIXED | In VALIDATE: "`^[0-9A-F]{6}$`"; In Verdict Block: "Nonce format is strict: `^[0-9A-F]{6}$`" |

### Additional P9 Content — Complete ✅

- verify_task references P9_VERIFY_CRITERION.md ✅
- Sub-agent dispatch via Task tool ✅
- Up to 7 parallel sub-agents ✅
- build_verdict.py stdin format ✅
- Combined verdict logic table (6 rows) ✅
- One retry max per output ✅
- NEEDS_HUMAN → `phase: needs_human` (all modes) ✅

**Findings: None.**

---

## File 3: `.pipe/p2-codex-prompt.md` (consistency mirror)

### P9-Relevant Sections — **MATCH** ✅

The following P9-critical sections in p2-codex-prompt.md's embedded CLAUDE.md are **identical** to CLAUDE.md:

- `verify_task` action spec (all 3 stages, full detail)
- Verdict Block Format (with all parser-safety rules)
- Format-Repair Retry (pre-parse regex, not exit code)
- Acceptance criteria prefix convention (DET/LLM/untagged)
- Nonce format constraint in VALIDATE step

### Pre-Existing Non-P9 Divergences — **LOW** (not caused by this change)

The p2-codex-prompt.md's embedded CLAUDE.md has older wording in several non-P9 sections that predate the Codex P9 implementation run:

| Section | CLAUDE.md (current) | p2-codex-prompt.md | Severity |
|---------|---------------------|--------------------|----|
| Step 5 RECORD | "under the shared `STATE.yaml.flock` lock" + flock pattern | "write to temp file, then rename" | **LOW** |
| Step 6 REPLY | "Ralph does **not** parse stdout tokens; it polls STATE.yaml" | "ralph.sh scans stdout for these tokens" | **LOW** |
| State Write Authority | Full flock pattern with bash example | "Always write to a temp file, then `mv`" | **LOW** |
| `seed_docs` | Full P2-aware spec with P2_DONE check | 3-line simplified version | **LOW** |
| P12 section | Present | Missing | **LOW** |
| `pick_track`/`create_spec`/`create_plan` | Full specs with sentinel formats | Abbreviated | **LOW** |
| `generate_task` | Full 60+ line spec with TASK packet format | Abbreviated (layered prompt reference) | **LOW** |

**Assessment:** These divergences are all **pre-existing** — they were present before the P9 work. The Codex run correctly updated the P9-relevant sections but (appropriately) did not touch unrelated sections. These divergences are LOW severity because p2-codex-prompt.md is a P2 implementation prompt where non-P9 sections serve as context reference only. A full sync should be tracked as a separate task.

---

## Parser Compatibility Check

### build_verdict.py — **COMPATIBLE** ✅

Tested the template's expected output format against `build_verdict.py` with live runs:

| Test Case | Result |
|-----------|--------|
| YES verdict with single-quoted filename in REASON | ✅ Parses, verdict=PASS |
| NO verdict with `insufficient evidence` REASON using single quotes | ✅ Parses, verdict=FAIL |

**Template instructions align with all parser requirements:**

| Parser Requirement | Template Instruction | Match |
|-------------------|---------------------|-------|
| Nonce: `^[0-9A-F]{6}$` | `{nonce}` placeholder (orchestrator provides) | ✅ |
| Exactly one opener/closer | "output ONLY this block" | ✅ |
| ANSWER unquoted, YES or NO | "Choose exactly one: ANSWER=YES … ANSWER=NO" | ✅ |
| REASON quoted, non-empty, ≤500 chars | `REASON="One sentence, ≤500 chars, ..."` | ✅ |
| No `"` inside REASON | "Do not use double quotes inside REASON" | ✅ |
| No `\` (backslash triggers ParseError) | "Do not use backslashes" | ✅ |
| Two payload lines only | "exactly two lines inside the block" | ✅ |
| No code fences wrapping block | "Do not use code fences anywhere" | ✅ |

---

## Summary

| File | Findings | Severity |
|------|----------|----------|
| P9_VERIFY_CRITERION.md | 0 findings — exact match to synthesis spec | — |
| CLAUDE.md | 0 findings — all 6 R2 required fixes applied | — |
| p2-codex-prompt.md | 7 pre-existing non-P9 divergences (not from this change) | LOW |
| Parser compatibility | Fully compatible (live-tested) | — |

**Verdict: CLEAN**

No changes required for the P9 implementation. The pre-existing p2-codex-prompt.md divergences should be tracked for a future sync pass but are out of scope for this review.
