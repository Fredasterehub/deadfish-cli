# Batch 3 Review — T07/T08/T09 (P3-P5 Prompts)

**Reviewer:** Claude Opus 4.5 (subagent)
**Date:** 2025-07-19
**Overall verdict:** CLEAN

---

## Per-File Verdicts

| File | Task | Verdict |
|------|------|---------|
| `P3_PICK_TRACK.md` | T07 | ✅ CLEAN |
| `P4_CREATE_SPEC.md` | T08 | ✅ CLEAN (1 LOW) |
| `P5_CREATE_PLAN.md` | T09 | ✅ CLEAN |

---

## P3_PICK_TRACK.md (T07 — Track Selection)

### Checklist

| # | Check | Status | Notes |
|---|-------|--------|-------|
| 1 | Layered structure (0a-0c / 1 / RULES / 999+) | ✅ | All four sections present with correct headers |
| 2 | Sentinel TRACK format verbatim | ✅ | Matches restructure plan §6 exactly |
| 3 | Input files per restructure plan | ✅ | STATE.yaml (0a), ROADMAP.md (0b), REQUIREMENTS.md (0c), VISION.md + PROJECT.md (0c) |
| 4 | Rules completeness | ✅ | All 6 rules from §6 present: maximize progress, prefer unblocked, prefer smaller, never outside phase, PHASE_COMPLETE, PHASE_BLOCKED |
| 5 | Guardrails | ✅ | Output-only sentinel (99999), no invented IDs (999999), ESTIMATED_TASKS 2-5 (9999999), no outside-phase work (99999999) |
| 6 | Signal outputs | ✅ | PHASE_COMPLETE=true with PHASE={phase_id}; PHASE_BLOCKED=true with PHASE + REASONS |

### Issues

None.

### Notes

- Signal output definitions are embedded in RULES rather than as a separate section, which is fine — they're clearly specified with exact field lists and "omit all other track fields" instruction.
- Guardrail numbering follows escalating 9s pattern consistent with CLAUDE.md convention.

---

## P4_CREATE_SPEC.md (T08 — JIT Spec)

### Checklist

| # | Check | Status | Notes |
|---|-------|--------|-------|
| 1 | Layered structure (0a-0c / 1 / RULES / 999+) | ✅ | All four sections present, plus bonus CODEBASE SEARCH EVIDENCE section |
| 2 | Sentinel SPEC format verbatim | ✅ | Matches restructure plan §7 exactly |
| 3 | Input files per restructure plan | ✅ | STATE.yaml + ROADMAP.md (0a), REQUIREMENTS.md (0b), codebase search + PROJECT.md + OPS.md (0c) |
| 4 | Rules completeness | ✅ | All rules present: AC→REQ tracing, DET:/LLM: tagging, existing code inclusion, scope, WHAT-not-HOW, atomic FRs |
| 5 | Guardrails | ✅ | Output-only (99999), no hallucination (999999), verifiable ACs (9999999) |
| 7 | AC traceability | ✅ | `req=<REQ-ID>` in sentinel format, DET:/LLM: tagging rule explicit |

### Issues

| # | Severity | Issue | Location |
|---|----------|-------|----------|
| 1 | LOW | Scope sizing says "<=5 tasks" where restructure plan §7 says "2-5 tasks" | RULES, line "Keep scope tight" |

**Detail:** The restructure plan §7 says "Keep scope tight: 2-5 tasks worth of work." P4 says "<=5 tasks worth of work." The missing lower bound of 2 is cosmetic — a 1-task spec would just be very small and wouldn't cause problems. The Codex prompt T08 itself also says "≤5 tasks" so P4 is consistent with its generation prompt.

**Fix (optional):** Change "<=5 tasks" to "2-5 tasks" for consistency with the restructure plan. Not blocking.

### Notes

- The CODEBASE SEARCH EVIDENCE section after RULES is a good addition — it explicitly handles the "no search evidence provided" edge case per the Codex prompt T08 requirement.
- The `(preserve DET/LLM tagging as defined there)` note in 0b is a valuable addition beyond the restructure plan spec.

---

## P5_CREATE_PLAN.md (T09 — Plans-as-Prompts)

### Checklist

| # | Check | Status | Notes |
|---|-------|--------|-------|
| 1 | Layered structure (0a-0c / 1 / RULES / 999+) | ✅ | All four sections present |
| 2 | Sentinel PLAN format verbatim | ✅ | Matches restructure plan §8 exactly including TASK_COUNT and DEPENDS_ON |
| 3 | Input files per restructure plan | ✅ | STATE.yaml (0a), SPEC.md (0b), PROJECT.md + OPS.md (0c) |
| 4 | Rules completeness | ✅ | All rules present: 2-5 tasks, ≤200 lines, ≤5 files, sequential execution, DEPENDS_ON, imperative SUMMARY, ESTIMATED_DIFF, exact AC coverage |
| 5 | Guardrails | ✅ | Output-only (99999), no hallucinated files (999999), implementation-ready (9999999), no vague ACs (99999999) |
| 8 | Plans-as-prompts | ✅ | SUMMARY described as "imperative, directly executable by gpt-5.2-codex", concrete instructions requirement, OPS.md commands inclusion |

### Issues

None.

### Notes

- P5 adds a valuable DET:/LLM: clarification rule: "DET: only for verify.sh checks (tests, lint, diff within 3x, path safety, no secrets, git clean). All other criteria must be LLM:." This goes beyond the restructure plan §8 which just says "≥1 DET: criterion" — the added specificity aligns with CLAUDE.md's DET:/LLM: convention and will reduce misclassification.
- The "actual diff should stay within 3x" note on ESTIMATED_DIFF is a helpful addition.
- Exact AC coverage rule is clearly stated: "Every acceptance criterion from SPEC.md must appear in exactly one task's ACCEPTANCE list (no duplicates, no omissions)."

---

## Codex Done-When Checklist Verification

### T07 (P3_PICK_TRACK.md)
- [x] File exists with layered (0a/1/rules/999+) structure
- [x] Instructs reading STATE.yaml, ROADMAP.md, REQUIREMENTS.md, VISION.md, PROJECT.md
- [x] Includes TRACK sentinel format verbatim
- [x] Defines PHASE_COMPLETE=true and PHASE_BLOCKED=true signal outputs
- [x] Guardrails forbid selecting work outside current phase

### T08 (P4_CREATE_SPEC.md)
- [x] File exists with layered (0a/1/rules/999+) structure
- [x] Instructs loading STATE.yaml, ROADMAP.md, REQUIREMENTS.md, PROJECT.md, OPS.md + codebase search
- [x] Includes SPEC sentinel format verbatim
- [x] Requires AC→REQ traceability and DET:/LLM: tagging
- [x] Contains anti-hallucination guardrails for EXISTING_CODE

### T09 (P5_CREATE_PLAN.md)
- [x] File exists with layered (0a/1/rules/999+) structure
- [x] Instructs loading STATE.yaml, SPEC.md, PROJECT.md, OPS.md
- [x] Includes PLAN sentinel format verbatim
- [x] Enforces 2-5 tasks, ≤200 lines/task, ≤5 files/task
- [x] Enforces exact coverage: every SPEC AC in exactly one task
- [x] Defines SUMMARY as direct gpt-5.2-codex implementation prompt (imperative, actionable)

---

## Summary

All three prompt files are well-constructed and faithfully implement the restructure plan specifications. The single LOW-severity finding (P4 scope sizing "≤5" vs "2-5") is cosmetic and consistent with the Codex prompt that generated it. No CRITICAL or HIGH issues found. No fixes required.
