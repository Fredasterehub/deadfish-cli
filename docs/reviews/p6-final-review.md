# P6_GENERATE_TASK.md — Final QA Review

**Date:** 2025-07-23
**Reviewer:** Claude Opus 4.5 (subagent)
**File:** `.pipe/p6/P6_GENERATE_TASK.md`
**Reference:** `CLAUDE.md` lines ~310–352 (TASK packet format)

---

## Checklist

| # | Check | Status | Notes |
|---|-------|--------|-------|
| 1 | `# TASK — {TASK_ID}` (em dash) | ✅ PASS | Line uses `# TASK — <TASK_ID>` with em dash |
| 2 | `## TITLE` section (not `## Objective`) | ✅ PASS | `## TITLE` present, no stale `## Objective` |
| 3 | `## SUMMARY (verbatim)` heading | ✅ PASS | Matches CLAUDE.md exactly |
| 4 | `## FILES (verbatim)` with pipe-delimited entries | ✅ PASS | Format: `path: ... \| action: ... \| rationale: ...` matches |
| 5 | `## ACCEPTANCE (verbatim)` heading | ✅ PASS | Matches CLAUDE.md exactly |
| 6 | `## ESTIMATED_DIFF (verbatim)` as own section | ✅ PASS | Standalone section, not inside Meta |
| 7 | `## DEPENDS_ON (verbatim)` as own section | ✅ PASS | Standalone section, not inside Meta |
| 8 | `## OPS COMMANDS` (not `## Commands`) | ✅ PASS | Matches CLAUDE.md exactly |
| 9 | `## FILES_TO_LOAD` heading with `\| why:` entries | ⚠️ MINOR | See note below |
| 10 | `## HARD STOPS / SIGNALS` with REPLAN/SPLIT | ✅ PASS | Both signals present with `<true\|false + reason>` format |

### Structural Integrity

| Check | Status | Notes |
|-------|--------|-------|
| ORIENTATION section intact | ✅ PASS | 0a–0c all present |
| OBJECTIVE section intact | ✅ PASS | Section 1 present with drift/retry guidance |
| RULES section intact | ✅ PASS | All rules present |
| GUARDRAILS section intact | ✅ PASS | 99999, 999999, 9999999 all present |
| Option B (REPLAN_REQUIRED) intact | ✅ PASS | Present and correct |
| Option C (REQUEST_SPLIT) intact | ✅ PASS | Present and correct |
| No accidental deletions | ✅ PASS | All content accounted for |

### Symbol / Formatting Consistency

| Check | Status | Notes |
|-------|--------|-------|
| Multiplication symbol `×` (not `*`) | ❌ **FAIL** | Line 49: `max_diff: <3 * ESTIMATED_DIFF>` uses `*` instead of `×` |

---

## Issues Found

### 1. FAIL — Multiplication symbol on line 49

**Location:** OUTPUT FORMAT → Option A → `## ESTIMATED_DIFF (verbatim)` section
**Current:** `max_diff: <3 * ESTIMATED_DIFF>`
**Expected:** `max_diff: <3 × ESTIMATED_DIFF>`
**Rationale:** CLAUDE.md consistently uses `×` (lines 309, 368, 657). Lines 71 and 81 of P6 already use `×` correctly, but line 49 was missed.

### 2. MINOR — FILES_TO_LOAD heading wording

**P6 says:** `## FILES_TO_LOAD (ordered by priority, ≤3000 tokens)`
**CLAUDE.md says:** `## FILES_TO_LOAD (ordered, capped)`

This is a **minor divergence**, not a failure. P6's version is more explicit and informative — it clarifies *what* "ordered" means (by priority) and *what* "capped" means (≤3000 tokens). Both convey the same intent. CLAUDE.md's version is the minimum-required template; P6 elaborates for the prompt consumer. **Acceptable as-is** but worth noting.

### 3. INFO — `## Meta` section present in P6 but absent from CLAUDE.md template

P6 includes a `## Meta` block (task_id, attempt, track_id, task_index). CLAUDE.md's example template does not include this. This is **additive** (extra metadata for traceability) and does not conflict — CLAUDE.md says "minimum required sections." **Acceptable.**

---

## Overall Verdict

**PASS WITH 1 FIX NEEDED**

The 7 alignment fixes were applied correctly. All major section headings, structure, and format now match CLAUDE.md's TASK packet specification. One minor symbol inconsistency remains (`*` → `×` on line 49) that should be fixed for full consistency.

### Recommended Fix

```
Line 49: max_diff: <3 * ESTIMATED_DIFF>
      →: max_diff: <3 × ESTIMATED_DIFF>
```
