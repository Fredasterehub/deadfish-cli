# P6 Post-Fix Review — QA (Opus 4.5)

**Date:** 2025-07-27  
**Reviewer:** Claude Opus 4.5 (QA sub-agent)  
**Scope:** Verify fixes to P6_GENERATE_TASK.md against original p6-review.md findings + CLAUDE.md spec

---

## Per-Issue Verdicts

### Issue 1+2: FILES_TO_LOAD heading, ordering, ≤3000 cap, `why` annotations — **FIXED** ✅

**Before (from review):** Section was `## Context Pack (files_to_load)` with bare `- <path>` entries, no ordering, no token cap in heading, no `why` annotation.

**After:** Output format now reads:
```
## FILES_TO_LOAD (ordered by priority, ≤3000 tokens)
- <path> | why: <reason>
- <path> | why: <reason>
```

**CLAUDE.md reference:** `## FILES_TO_LOAD (ordered, capped)` with `- path: ... | why: ...`

Match is strong. The P6 version is actually *more specific* than CLAUDE.md's example (adds "by priority" and "≤3000 tokens" vs just "ordered, capped") — this is fine, it's more explicit. The RULES section also retains `files_to_load priority: modify targets -> entrypoints -> tests -> config -> style anchors` and `Cap files_to_load at 3000 tokens`, providing reinforcement.

---

### Issue 3: REQUEST_SPLIT signal as output option C — **FIXED** ✅

**Before:** Only REPLAN_REQUIRED existed as output option B. No REQUEST_SPLIT.

**After:** New output option C:
```
C) REQUEST_SPLIT signal only:
REQUEST_SPLIT: <short reason why adapted task would exceed 3× ESTIMATED_DIFF>

If REQUEST_SPLIT is emitted, do not output any TASK markdown.
```

Plus a new rule: `If adaptation would exceed this, output REQUEST_SPLIT.`

Matches CLAUDE.md's hard stop: "If required change size exceeds plan ESTIMATED_DIFF by >3× → REQUEST_SPLIT."

---

### Issue 4: Explicit `max_diff = 3 × ESTIMATED_DIFF` rule — **FIXED** ✅

**Before:** Meta section showed `max_diff: <3 * ESTIMATED_DIFF>` but no explicit rule enforcing the computation.

**After:** RULES section now includes:
```
- max_diff is always 3 × ESTIMATED_DIFF. If adaptation would exceed this, output REQUEST_SPLIT.
```

And Meta section retains: `- max_diff: <3 * ESTIMATED_DIFF>`

Both the rule and the template reinforce the constraint. Clean fix.

---

## Cross-Check: P6 Output Format vs CLAUDE.md TASK Packet Format

### CLAUDE.md minimum required sections (reference):
```
# TASK — {TASK_ID}
## TITLE
## SUMMARY (verbatim)
## FILES (verbatim)
- path: ... | action: add|modify|delete | rationale: ...
## ACCEPTANCE (verbatim)
## ESTIMATED_DIFF (verbatim)
## DEPENDS_ON (verbatim)
## OPS COMMANDS
## FILES_TO_LOAD (ordered, capped)
- path: ... | why: ...
## HARD STOPS / SIGNALS
```

### P6_GENERATE_TASK.md output format:
```
# TASK - <TASK_ID>
## Meta (consolidated: task_id, attempt, estimated_diff, max_diff, depends_on, track_id, task_index)
## Objective
## Summary
## Files
- path: <resolved path> action: <add|modify|delete> rationale: <from PLAN>
## Acceptance
## Commands
## FILES_TO_LOAD (ordered by priority, ≤3000 tokens)
- <path> | why: <reason>
```

### Remaining Divergences (non-blocking but worth noting)

| # | Divergence | Severity | Notes |
|---|-----------|----------|-------|
| D1 | `# TASK -` (hyphen) vs `# TASK —` (em dash) | **COSMETIC** | No functional impact |
| D2 | Consolidated `## Meta` section vs separate `## TITLE`, `## ESTIMATED_DIFF`, `## DEPENDS_ON` sections | **LOW** | P6 packs more into Meta. All data present; just structured differently. verify.sh parses `ESTIMATED_DIFF` lines — the Meta format `- estimated_diff: <ESTIMATED_DIFF>` may need to match `ESTIMATED_DIFF: <int>` or `ESTIMATED_DIFF=<int>` for verify.sh grep. |
| D3 | `## Objective` vs `## TITLE` | **LOW** | Different name, same concept |
| D4 | Missing `(verbatim)` annotations on Summary, Files, Acceptance headings | **LOW-MEDIUM** | CLAUDE.md uses `(verbatim)` as a guardrail hint. P6's RULES section does say "Pass through... from PLAN" and the OBJECTIVE says "Keep SUMMARY from PLAN as primary prompt" — so the intent is there, but the heading-level annotation is missing. |
| D5 | `## Commands` vs `## OPS COMMANDS` | **LOW** | Different name, same content |
| D6 | Missing `## HARD STOPS / SIGNALS` inline section | **LOW** | P6 uses signals as *alternative outputs* (B/C) rather than inline fields. Original review noted this is architecturally fine — drift/retry paths either emit a TASK or a signal, not both. |
| D7 | Files format: `path: <path> action: <action>` (space-delimited) vs `path: ... \| action: ... \| rationale: ...` (pipe-delimited) | **LOW** | verify.sh extracts via `grep -oP 'path=\\K[^\\s]+'` (equals-delimited). P6 uses `path: <path>` (colon). This *could* cause a parse issue, but since the happy path writes TASK files mechanically (matching verify.sh format exactly), and P6 only fires on drift/retry, the orchestrator can normalize format during write. Still, aligning would be safer. |

**Assessment:** None of these divergences are blocking. D2/D7 are the most noteworthy — if verify.sh needs to parse P6-generated TASK files directly, the `estimated_diff` and `path=` format differences could matter. However, since the orchestrator (Claude Code) writes the final TASK file and can normalize format, this is acceptable.

---

## New Issues Check

| # | Check | Status |
|---|-------|--------|
| N1 | Typos or broken markdown | ✅ None found |
| N2 | Structural consistency (ORIENTATION/OBJECTIVE/OUTPUT/RULES/GUARDRAILS) | ✅ Clean — matches P3/P4/P5 pattern |
| N3 | Rule contradictions | ✅ None — REQUEST_SPLIT rule aligns with output option C |
| N4 | Missing context from original (accidentally deleted content) | ✅ All original content preserved; only additions |
| N5 | Guardrail numbering (99999/999999/9999999) | ✅ Consistent with other P-templates |
| N6 | Drift vs retry path clarity | ✅ Both paths clearly delineated in OBJECTIVE and RULES |

**No new issues introduced by the fixes.**

---

## Summary

| Issue | Verdict |
|-------|---------|
| Issue 1+2: FILES_TO_LOAD format alignment | **FIXED** ✅ |
| Issue 3: REQUEST_SPLIT signal | **FIXED** ✅ |
| Issue 4: max_diff rule | **FIXED** ✅ |
| New issues introduced | **NONE** |
| Cross-format divergences | **Non-blocking** (D1–D7 noted above) |

### Overall Verdict: **PASS** ✅

All three review issues are properly fixed. The template is structurally sound, internally consistent, and aligned with CLAUDE.md's generate_task specification. Minor naming/formatting divergences between P6's output format and CLAUDE.md's example TASK packet exist but are non-blocking — the orchestrator normalizes the final file write.
