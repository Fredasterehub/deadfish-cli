# Batch 2 Review — P2_E, P2_F, P2_MAIN

**Reviewer:** Opus QA  
**Date:** 2025-07-16  
**Source of truth:** `.pipe/p2-p5-restructure-opus.md`  
**Verdict:** **NEEDS_FIXES** (2 CRITICAL, 2 HIGH, 2 MEDIUM, 1 LOW)

---

## File: P2_E.md (Crystallize)

### Issue E1 — Block 1 (VISION) missing most schema fields [HIGH]

Block 1 asks for:
- "Vision statement (1 paragraph)"
- "Success truths (5-12)"
- "Non-goals (3-7)"
- "Key risks (3-5)"

But VISION.md schema (restructure plan §1) requires structured fields:
`problem.why`, `problem.pain`, `solution.what`, `solution.boundaries`, `users.primary`, `users.environments`, `differentiators`, `mvp_scope.in`, `mvp_scope.out`, `success_metrics`, `non_goals`

"Vision statement (1 paragraph)" is too vague to populate `problem`, `solution`, `users`, `differentiators`, and `mvp_scope` as separate structured fields. The crystallize phase must collect data at the field level, not as a single paragraph.

**Fix:** Replace "Vision statement (1 paragraph)" with explicit sub-items matching VISION schema:
```
- problem.why + problem.pain[]
- solution.what + solution.boundaries
- users.primary + users.environments[]
- differentiators[]
- mvp_scope.in[] + mvp_scope.out[]
- success_metrics[] (observable, verifiable)
- non_goals[]
```

### Issue E2 — Block 1 includes "Key risks" but VISION.md has no risks field [MEDIUM]

VISION.md schema has no `risks` field. Risks belong in ROADMAP.md (Block 4 already covers `risks`). Including risks in Block 1 creates orphaned data with no output target.

**Fix:** Remove "Key risks (3-5)" from Block 1. Block 4 already handles ROADMAP risks.

### Issue E3 — Block 1 "Success truths" naming vs schema "success_metrics" [LOW]

Block 1 calls them "Success truths" but the VISION.md schema field is `success_metrics`. Minor naming inconsistency could confuse the LLM facilitator during output mapping.

**Fix:** Rename to "success_metrics" or "Success metrics" for consistency.

---

## File: P2_F.md (Output Writer)

### Issue F1 — VISION schema root key is `vision_yaml<=300t:` instead of `vision:` [CRITICAL]

P2_F's VISION.md schema uses `vision_yaml<=300t:` as the root YAML key. The restructure plan and all downstream consumers expect `vision:`. This will break any parser or prompt that reads `vision:`.

**Fix:** Change root key from `vision_yaml<=300t:` to `vision:`. Move the token hint to a comment or the line-limit header.

### Issue F2 — VISION schema includes `assumptions` and `open_questions` [CRITICAL]

P2_F's VISION.md schema includes:
```yaml
  assumptions:
    - "<assumption>"
  open_questions:
    - "<unresolved question>"
```

Per the restructure plan §2 ("Migration from Current Format"):
> `assumptions`, `open_questions` → moves to PROJECT.md

These fields already exist in the PROJECT.md schema (both in P2_F and the template). Having them in VISION.md creates field duplication across two docs, breaks the VISION-as-constitution / PROJECT-as-living-context separation, and contradicts the restructure plan.

**Fix:** Remove `assumptions` and `open_questions` from the VISION.md schema in P2_F. They are correctly present in PROJECT.md already.

### Issue F3 — VISION schema says `key_differentiators` vs plan's `differentiators` [MEDIUM]

P2_F uses `key_differentiators` but the restructure plan schema (§1) uses `differentiators`. Field name mismatch between P2_F and the source of truth.

**Fix:** Rename `key_differentiators` to `differentiators` in P2_F's VISION schema.

### Issue F4 — VISION line limit "60-80" vs restructure plan "≤60" [HIGH]

P2_F says "VISION.md (60-80 lines max)". The restructure plan table says VISION.md ≤60 lines, ~250 tokens. After removing `assumptions` and `open_questions` (Issue F2), the schema fits comfortably within 60 lines.

Note: The review task criteria listed "VISION ≤80" but the restructure plan (designated source of truth) says ≤60. If the limit was intentionally raised to ≤80, the restructure plan table should be updated too.

**Fix:** Either change P2_F to "≤60 lines" to match restructure plan, or update the restructure plan table if the limit was intentionally raised. Whichever is chosen, make them consistent.

---

## File: P2_MAIN.md (Main Flow)

### Verdict: CLEAN ✓

P2_MAIN correctly:
- Lists all 5 output docs (VISION.md, PROJECT.md, REQUIREMENTS.md, ROADMAP.md, STATE.yaml) plus brainstorm ledger ✓
- Quick Mode collects: description, core value, key decisions, must-haves (→ categorized v1 requirements with IDs + acceptance criteria), non-goals, constraints, rough strategic phases ✓
- Phase 5 (Crystallize) references all 5 outputs + template paths ✓
- Phase 6 (Output) lists all 5 files + "Use P2_F" ✓
- Phase 7 (Adversarial Review) says "ALL five docs" with cross-doc consistency ✓
- No orphaned references to old 2-doc structure ✓

No issues found.

---

## Cross-Doc Consistency Check

### P2_E → P2_F feed (with fixes applied)

| P2_E Block | P2_F Output | Feed OK? |
|------------|-------------|----------|
| Block 1 (VISION) | VISION.md schema | ⚠️ After E1 fix, yes |
| Block 2 (PROJECT) | PROJECT.md schema | ✅ Clean match |
| Block 3 (REQUIREMENTS) | REQUIREMENTS.md schema | ✅ Clean match |
| Block 4 (ROADMAP) | ROADMAP.md schema | ✅ Clean match |
| Block 5 (STATE) | STATE.yaml schema | ✅ Clean match |

### P2_F schemas vs Templates

| P2_F Schema | Template | Match? |
|-------------|----------|--------|
| PROJECT.md | P2_PROJECT_TEMPLATE.md | ✅ Exact match |
| REQUIREMENTS.md | P2_REQUIREMENTS_TEMPLATE.md | ✅ Exact match |
| ROADMAP.md | P2_ROADMAP_TEMPLATE.md | ✅ Exact match |
| VISION.md | (no separate template) | ⚠️ Needs F1-F3 fixes |
| STATE.yaml | (no separate template) | ✅ Matches restructure plan |

### P2_MAIN → P2_E/P2_F references
- Phase 5 → P2_E ✅
- Phase 6 → P2_F ✅
- Phase 7 → P2_G ✅
- Template paths listed in Phase 5 ✅

---

## Overwrite Flow Check

P2_F correctly includes: "If ANY of VISION.md, PROJECT.md, REQUIREMENTS.md, ROADMAP.md, or STATE.yaml already exist, ask once whether to overwrite or write new drafts before writing." ✅ All 5 files covered in single prompt.

---

## Line Limit Summary

| Doc | Restructure Plan | P2_F States | P2_E States | Status |
|-----|-----------------|-------------|-------------|--------|
| VISION.md | ≤60 | 60-80 | — | ⚠️ F4 |
| PROJECT.md | ≤80 | ≤80 | — | ✅ |
| REQUIREMENTS.md | ≤120 | ≤120 | — | ✅ |
| ROADMAP.md | ≤100 | ≤100 | — | ✅ |
| STATE.yaml | ≤60 | ≤60 | — | ✅ |

---

## Issue Summary

| ID | File | Severity | Summary |
|----|------|----------|---------|
| F1 | P2_F | **CRITICAL** | VISION root key `vision_yaml<=300t:` must be `vision:` |
| F2 | P2_F | **CRITICAL** | VISION schema has `assumptions`/`open_questions` — belong in PROJECT only |
| E1 | P2_E | **HIGH** | Block 1 (VISION) too vague — must list all schema fields explicitly |
| F4 | P2_F | **HIGH** | VISION line limit "60-80" vs restructure plan "≤60" — inconsistent |
| E2 | P2_E | **MEDIUM** | Block 1 includes "Key risks" — no target field in VISION.md |
| F3 | P2_F | **MEDIUM** | `key_differentiators` vs `differentiators` naming mismatch |
| E3 | P2_E | **LOW** | "Success truths" vs `success_metrics` naming inconsistency |

**CRITICALs:** 2 (both in P2_F VISION schema)  
**HIGHs:** 2 (P2_E Block 1 completeness, P2_F line limit)  
**MEDIUMs:** 2 (orphaned risks in P2_E, field naming in P2_F)  
**LOWs:** 1 (naming preference in P2_E)

---

## Re-Review — Batch 2 VISION Fixes

**Reviewer:** Opus QA (re-review)  
**Date:** 2025-07-16  
**Scope:** P2_E Block 1 (VISION) + P2_F VISION schema only  
**Master plan:** `.pipe/p2-p5-restructure-opus.md` §1

---

### Per-Issue Verdicts

#### P2_E Issues

**E1 (HIGH) — Block 1 now collects all VISION.md fields?**  
**Verdict: FIXED** (with caveats → see NEW_ISSUE E5, E6)

Block 1 now explicitly lists: problem (why+pain), solution (pitch+boundaries), users (primary+environments), differentiators, mvp_scope (in+out), success_metrics, non_goals. All ~10 schema fields from the master plan are covered. However, two new issues emerged (see E5, E6 below).

**E2 (MEDIUM) — Key risks moved out of Block 1?**  
**Verdict: FIXED ✅**

Risks are now a note: "Key risks (3-5) are collected in Block 4 (ROADMAP) under roadmap.risks." Clean redirection, no orphaned data.

**E3 (LOW) — Schema field mappings added?**  
**Verdict: FIXED** (but mappings have wrong field names → see NEW_ISSUE E6)

Parenthetical mappings like `(→ vision.problem.why + vision.problem.pain[])` are present on every line. Good structural improvement. However, several mapping names don't match P2_F / master plan (details in E6).

**E4 (LOW) — assumptions/open_questions consistent with P2_F?**  
**Verdict: FIXED ✅**

Neither P2_E Block 1 nor P2_F VISION schema contain assumptions/open_questions. Both are correctly in Block 2 (PROJECT) / PROJECT.md schema only.

#### P2_F Issues

**F1 (CRITICAL) — Root key changed from `vision_yaml<=300t:` to `vision:`?**  
**Verdict: FIXED ✅**

Root key is now `vision:`. Token hint moved to a comment `# Token budget: <=300t` above the codefence.

**F2 (CRITICAL) — `assumptions` and `open_questions` removed from VISION schema?**  
**Verdict: FIXED ✅**

Both fields removed. VISION schema now contains only the fields from the master plan.

**F3 (MEDIUM) — `key_differentiators` renamed to `differentiators`?**  
**Verdict: FIXED ✅**

Field is now `differentiators:`, matching master plan exactly.

**F4 (MEDIUM→HIGH) — Line limit resolved?**  
**Verdict: STILL_BROKEN ⚠️**

P2_F now says `VISION.md (<= 80 lines):`. Master plan table says `VISION.md | ≤60 | ~250`. These are still inconsistent. The limit was raised from "60-80" to "≤80" (a cleanup), but it doesn't match the master plan's ≤60. Either P2_F should say ≤60, or the master plan table needs updating. **Action needed:** Pick one and make them agree.

---

### NEW ISSUES

**E5 (MEDIUM) — "Vision statement (1 paragraph)" has no target field in P2_F**  
**NEW_ISSUE**

P2_E Block 1 line 1: `Vision statement (1 paragraph): constitution-style, what this is and why it matters. (→ vision.statement)`

But P2_F's VISION schema has no `vision.statement` field. The master plan schema also has no `statement` field. This is orphaned data — P2_E collects it but P2_F has nowhere to put it.

**Fix:** Either (a) remove the "Vision statement" line from P2_E Block 1 (the problem/solution/users fields already capture the essence), or (b) add a `statement:` field to P2_F VISION schema (and update master plan). Option (a) is simpler and keeps VISION lean.

**E6 (LOW) — Parenthetical field name mismatches in P2_E mappings**  
**NEW_ISSUE**

The parenthetical mappings added for E3 use wrong field names in several places:

| P2_E mapping says | P2_F / master plan actual |
|---|---|
| `vision.solution.pitch` | `vision.solution.what` |
| `vision.solution.scope_boundaries[]` | `vision.solution.boundaries` |
| `vision.mvp.in_scope[]` | `vision.mvp_scope.in[]` |
| `vision.mvp.out_of_scope[]` | `vision.mvp_scope.out[]` |

These are guidance hints for the LLM facilitator. Wrong field names could cause incorrect YAML output.

**Fix:** Update the parenthetical mappings to match P2_F exactly:
- `→ vision.solution.what + vision.solution.boundaries`
- `→ vision.mvp_scope.in[] + vision.mvp_scope.out[]`

---

### P2_F VISION Schema vs Master Plan — Field-by-Field

| Master Plan (§1) | P2_F Schema | Match |
|---|---|---|
| `vision.problem.why` | `vision.problem.why` | ✅ Exact |
| `vision.problem.pain[]` | `vision.problem.pain[]` | ✅ Exact |
| `vision.solution.what` | `vision.solution.what` | ✅ Exact |
| `vision.solution.boundaries` | `vision.solution.boundaries` | ✅ Exact |
| `vision.users.primary` | `vision.users.primary` | ✅ Exact |
| `vision.users.environments[]` | `vision.users.environments[]` | ✅ Exact |
| `vision.differentiators[]` | `vision.differentiators[]` | ✅ Exact |
| `vision.mvp_scope.in[]` | `vision.mvp_scope.in[]` | ✅ Exact |
| `vision.mvp_scope.out[]` | `vision.mvp_scope.out[]` | ✅ Exact |
| `vision.success_metrics[]` | `vision.success_metrics[]` | ✅ Exact |
| `vision.non_goals[]` | `vision.non_goals[]` | ✅ Exact |
| *(no extra fields)* | *(no extra fields)* | ✅ Clean |

**P2_F VISION schema matches master plan exactly.** ✅

---

### Cross-Check: P2_E Block 1 → P2_F VISION Schema Feed

| P2_E Block 1 Collects | P2_F Target Field | Feed OK? |
|---|---|---|
| Vision statement (1 paragraph) | *(no target)* | ❌ Orphaned (E5) |
| Problem: why + pain points | `vision.problem.why` + `vision.problem.pain[]` | ✅ |
| Solution: pitch + boundaries | `vision.solution.what` + `vision.solution.boundaries` | ✅ (but mapping names wrong, E6) |
| Users: primary + environments | `vision.users.primary` + `vision.users.environments[]` | ✅ |
| Differentiators (3-7) | `vision.differentiators[]` | ✅ |
| MVP scope: in + out | `vision.mvp_scope.in[]` + `vision.mvp_scope.out[]` | ✅ (but mapping names wrong, E6) |
| Success metrics (5-12) | `vision.success_metrics[]` | ✅ |
| Non-goals (3-7) | `vision.non_goals[]` | ✅ |

**Feed is functional** — all P2_F fields have a data source. The orphaned "Vision statement" and wrong mapping names are the only gaps.

---

### Re-Review Issue Summary

| ID | File | Severity | Status | Summary |
|----|------|----------|--------|---------|
| E1 | P2_E | HIGH | **FIXED** | Block 1 now covers all schema fields |
| E2 | P2_E | MEDIUM | **FIXED** | Risks redirected to Block 4 |
| E3 | P2_E | LOW | **FIXED** | Parenthetical mappings added (names wrong → E6) |
| E4 | P2_E | LOW | **FIXED** | assumptions/open_questions consistent |
| F1 | P2_F | CRITICAL | **FIXED** | Root key is now `vision:` |
| F2 | P2_F | CRITICAL | **FIXED** | assumptions/open_questions removed |
| F3 | P2_F | MEDIUM | **FIXED** | `differentiators` naming correct |
| F4 | P2_F | HIGH | **STILL_BROKEN** | Line limit ≤80 vs master plan ≤60 |
| E5 | P2_E | MEDIUM | **NEW_ISSUE** | "Vision statement" line has no P2_F target |
| E6 | P2_E | LOW | **NEW_ISSUE** | 4 parenthetical mappings use wrong field names |

### Overall Verdict: **NEEDS_FIXES**

- 6 of 8 original issues: **FIXED** ✅
- 1 original issue: **STILL_BROKEN** (F4 — line limit inconsistency)
- 2 new issues found (E5 MEDIUM — orphaned vision statement, E6 LOW — mapping names)
- P2_F VISION schema vs master plan: **EXACT MATCH** ✅
- Remaining work is LOW-MEDIUM severity — no CRITICALs or HIGHs remain
