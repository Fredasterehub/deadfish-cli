# Batch 3 QA Review — P3/P4/P5 Prompt Files (T07-T09)

**Reviewer:** Opus 4.5 (QA subagent)
**Date:** 2025-07-18
**Sources:** P3_PICK_TRACK.md, P4_CREATE_SPEC.md, P5_CREATE_PLAN.md
**Reviewed against:** p2-p5-restructure-opus.md (sections 6, 7, 8), CLAUDE.md (sentinel DSL, DECIDE table)

---

## T07: P3_PICK_TRACK.md

**Verdict: PASS**

### Checklist

| Check | Status | Notes |
|-------|--------|-------|
| Layered prompt structure (0a-0c / 1 / rules / 999+) | ✅ | All four layers present |
| Reads STATE.yaml | ✅ | 0a reads roadmap.current_phase |
| Reads ROADMAP.md | ✅ | 0b loads phase goal, success_criteria, requirements |
| Reads REQUIREMENTS.md | ✅ | 0c collects status per requirement ID |
| Reads VISION.md + PROJECT.md | ✅ | 0c includes both as optional context |
| TRACK sentinel format matches plan §6 | ✅ | All fields present: TRACK_ID, TRACK_NAME, PHASE, REQUIREMENTS, GOAL, ESTIMATED_TASKS |
| Nonce in sentinel header/footer | ✅ | `<<<TRACK:V1:NONCE={nonce}>>>` / `<<<END_TRACK:NONCE={nonce}>>>` |
| PHASE_COMPLETE signal | ✅ | Defined as sentinel block with PHASE_COMPLETE=true |
| PHASE_BLOCKED signal | ✅ | Defined with PHASE_BLOCKED=true + REASONS |
| Rule: maximize progress on unmet criteria | ✅ | Explicit in rules |
| Rule: prefer unblocked reqs | ✅ | Explicit in rules |
| Rule: 2-5 tasks | ✅ | "target 2–5 tasks per track" in rules + guardrail 9999999 |
| Rule: never outside current phase | ✅ | First rule + guardrail 999999999 |
| Guardrail: output ONLY sentinel | ✅ | Guardrail 99999 |

### Issues

| Severity | Description | Fix Needed |
|----------|-------------|------------|
| LOW | PHASE_COMPLETE/PHASE_BLOCKED use a modified sentinel form (`TRACK sentinel block containing only PHASE_COMPLETE=true`) rather than a dedicated signal keyword. This is slightly different from the plan's prose ("output PHASE_COMPLETE") but functionally equivalent and arguably better (keeps parsing uniform). | No fix required — design improvement over plan |
| LOW | Guardrail numbering uses 99999999 (8 nines) exceeding the typical pattern (99999/999999/9999999). Cosmetic only. | Optional: trim to 3 guardrails matching other files |

---

## T08: P4_CREATE_SPEC.md

**Verdict: NEEDS_FIXES**

### Checklist

| Check | Status | Notes |
|-------|--------|-------|
| Layered prompt structure (0a-0c / 1 / rules / 999+) | ✅ | All layers present |
| Reads STATE.yaml | ✅ | 0a reads track.id, track.name, track.phase, track.requirements, track.spec_path |
| Reads ROADMAP.md | ⚠️ | **NOT explicitly mentioned**. Plan §7 says "ROADMAP.md (current phase success criteria)" should be loaded. 0b reads REQUIREMENTS.md instead. |
| Reads REQUIREMENTS.md | ✅ | 0b extracts full text + acceptance criteria |
| Reads PROJECT.md | ✅ | 0c reads PROJECT.md |
| Reads OPS.md | ✅ | 0c reads OPS.md |
| Codebase search | ✅ | 0c: "Search codebase first (rg/find results provided by the pipeline)" |
| SPEC sentinel format matches plan §7 | ✅ | All fields present and ordered correctly |
| AC→REQ traceability (req=<REQ-ID>) | ✅ | `id=AC<n> req=<REQ-ID> text="..."` |
| DET:/LLM: tagging | ✅ | Rule: "Tag each acceptance criterion with DET: or LLM:" |
| Anti-hallucination guardrails for EXISTING_CODE | ✅ | Dedicated "CODEBASE SEARCH EVIDENCE" section + guardrail 999999 |
| "Spec defines WHAT not HOW" | ✅ | Objective §1 + first rule |
| Scope constraint | ✅ | "<=5 tasks worth of work" |

### Issues

| Severity | Description | Fix Needed |
|----------|-------------|------------|
| MEDIUM | **ROADMAP.md not in loading instructions.** Plan §7 explicitly lists ROADMAP.md as input ("current phase success criteria"). The prompt loads STATE.yaml, REQUIREMENTS.md, PROJECT.md, OPS.md but omits ROADMAP.md. While REQUIREMENTS.md carries the requirement text, the phase-level *success criteria* live in ROADMAP.md and provide important scope context for the spec. | Add to 0a or 0b: "Read ROADMAP.md for current phase success criteria." |
| LOW | Plan §7 says "Keep scope tight: 2-5 tasks worth of work" but the prompt says "<=5 tasks worth of work" (missing the lower bound of 2). Minor wording divergence. | Optional: change to "2-5 tasks worth of work" for consistency with plan |

---

## T09: P5_CREATE_PLAN.md

**Verdict: PASS**

### Checklist

| Check | Status | Notes |
|-------|--------|-------|
| Layered prompt structure (0a-0c / 1 / rules / 999+) | ✅ | All layers present |
| Reads STATE.yaml | ✅ | 0a reads track id, name, phase, spec_path |
| Reads SPEC.md | ✅ | 0b reads SPEC.md at spec_path |
| Reads PROJECT.md | ✅ | 0c reads PROJECT.md |
| Reads OPS.md | ✅ | 0c reads OPS.md |
| PLAN sentinel format matches plan §8 | ✅ | All fields: TRACK_ID, TASK_COUNT, TASK[n] with TASK_ID, TITLE, SUMMARY, FILES, ACCEPTANCE, ESTIMATED_DIFF, DEPENDS_ON |
| Plans-as-prompts (SUMMARY executable by codex) | ✅ | "SUMMARY is the implementers prompt. Write it as imperative instructions, not narrative." |
| Rule: 2-5 tasks | ✅ | "2-5 tasks per track" |
| Rule: ≤200 diff lines | ✅ | "Each task <=200 diff lines" |
| Rule: ≤5 files | ✅ | "<=5 files per task unless strictly necessary" |
| Rule: every SPEC AC in exactly one task | ✅ | "Every SPEC.md acceptance criterion must appear in exactly one task's ACCEPTANCE list (no duplicates, no omissions)" |
| Rule: each task ≥1 DET: criterion | ✅ | "Each task must have >=1 DET: criterion" |
| Guardrails: output ONLY sentinel | ✅ | Guardrail 99999 |
| Guardrails: plans are prompts | ✅ | Guardrail 999999 |
| Guardrails: no vague AC | ✅ | Guardrail 9999999 |

### Issues

| Severity | Description | Fix Needed |
|----------|-------------|------------|
| LOW | Plan §8 says "Each task must have ≥1 DET: criterion (tests pass) and ≥1 meaningful criterion." The prompt says ">=1 DET: criterion" but drops the "and ≥1 meaningful criterion" clause. The next rule ("Use DET: only for verify.sh checks; everything else is LLM:") partially compensates. | Optional: add "and at least one LLM: criterion" for full parity |
| LOW | Plan §8 mentions "Acceptance criteria inherited from SPEC.md, distributed across tasks." The prompt captures the distribution rule ("every SPEC.md AC...") but doesn't use the word "inherited." Functionally equivalent. | No fix required |

---

## Cross-File Consistency

**Verdict: PASS (with one MEDIUM note)**

### Sentinel Chain Logic (P3 → P4 → P5)

| Step | Sentinel | Key Field | Feeds Into |
|------|----------|-----------|------------|
| P3 | TRACK:V1 | TRACK_ID, REQUIREMENTS | P4 reads track.id and track.requirements from STATE.yaml |
| P4 | SPEC:V1 | TRACK_ID, ACCEPTANCE_CRITERIA | P5 reads SPEC.md via track.spec_path |
| P5 | PLAN:V1 | TRACK_ID, TASK[n].ACCEPTANCE | P6 (generate_task) reads individual tasks |

✅ **Chain is logically consistent.** TRACK_ID flows through all three sentinels. Requirements flow from P3 selection → P4 spec (REQUIREMENTS section) → P5 plan (distributed into task ACCEPTANCE).

### Field Name Consistency

- `TRACK_ID` — used consistently across all three sentinels ✅
- `REQUIREMENTS` — P3 uses `REQUIREMENTS=[comma-separated]`, P4 uses `REQUIREMENTS:` list with `id=` entries. Different format but semantically consistent ✅
- `ACCEPTANCE_CRITERIA` (P4) maps to `ACCEPTANCE` (P5 per-task) — name difference is intentional (P4 is full spec, P5 distributes into tasks) ✅
- `NONCE={nonce}` — consistent across all three ✅

### File Loading Patterns

| Phase | STATE.yaml | ROADMAP.md | REQUIREMENTS.md | VISION.md | PROJECT.md | OPS.md | SPEC.md |
|-------|-----------|------------|-----------------|-----------|------------|--------|---------|
| P3 | ✅ | ✅ | ✅ | ✅ | ✅ | — | — |
| P4 | ✅ | ⚠️ missing | ✅ | — | ✅ | ✅ | — |
| P5 | ✅ | — | — | — | ✅ | ✅ | ✅ |

⚠️ **P4 omits ROADMAP.md** — see T08 MEDIUM issue above. Plan §7 and the token budget table (§9) both list ROADMAP for P4.

### Alignment with CLAUDE.md DECIDE Table

| DECIDE Row | Action | Prompt File | Alignment |
|------------|--------|-------------|-----------|
| #7 | `pick_track` | P3_PICK_TRACK.md | ✅ Phase `select-track`, no track selected |
| #8 | `create_spec` | P4_CREATE_SPEC.md | ✅ Track selected, no spec |
| #9 | `create_plan` | P5_CREATE_PLAN.md | ✅ Spec exists, no plan |

✅ The three prompts map cleanly to DECIDE rows 7-9. The flow `select-track` → pick_track → create_spec → create_plan → `execute` is preserved.

**Note:** CLAUDE.md's current action specs for `pick_track`, `create_spec`, `create_plan` (in the Action Specifications section) are still sparse stubs ("Consult GPT-5.2 planner..."). T10 will update these to reference the new prompt files and sentinel formats. This is expected and not a defect in the current batch.

---

## Overall Verdict: **NEEDS_FIXES**

### Summary

| File | Verdict | Critical | High | Medium | Low |
|------|---------|----------|------|--------|-----|
| T07 (P3_PICK_TRACK.md) | PASS | 0 | 0 | 0 | 2 |
| T08 (P4_CREATE_SPEC.md) | NEEDS_FIXES | 0 | 0 | 1 | 1 |
| T09 (P5_CREATE_PLAN.md) | PASS | 0 | 0 | 0 | 2 |
| Cross-file | PASS (with note) | 0 | 0 | 0 | 0 |

### Required Fix (1 item)

1. **T08 MEDIUM — Add ROADMAP.md to P4 loading instructions.**
   In P4_CREATE_SPEC.md, add ROADMAP.md loading to orientation section. Suggested edit to 0a:
   ```
   0a. Read STATE.yaml to identify track.id, track.name, track.phase, track.requirements, track.spec_path.
       Read ROADMAP.md for current phase success_criteria and requirement context.
   ```
   This aligns with plan §7's input list and the token budget analysis in §9.

### Optional Improvements (5 items, all LOW)

1. T07: Normalize guardrail numbering to 3 entries (99999/999999/9999999) matching P4/P5 pattern
2. T08: Change "<=5 tasks" to "2-5 tasks" for consistency with plan wording
3. T09: Add "and at least one LLM: criterion" to the DET rule for full parity with plan §8
4. T07: PHASE_COMPLETE/PHASE_BLOCKED sentinel form could be documented more explicitly (what fields are required vs omitted)
5. T09: Mention that acceptance criteria are "inherited from SPEC.md" for traceability clarity

---

*Review complete. One MEDIUM fix required before merge. All other findings are LOW/optional.*
