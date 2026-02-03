# Batch 1 QA Review: P2 Templates T01–T03

**Reviewer:** Opus 4.5 (subagent)
**Date:** 2025-07-22
**Plan reference:** `.pipe/p2-p5-restructure-opus.md` (Sections 1–5)
**Style reference:** `.pipe/p2/P2_F.md`

---

## T01: P2_PROJECT_TEMPLATE.md

### Schema Fidelity
- YAML schema is **VERBATIM** from Section 1 (`PROJECT.md` block). Every key, order, comment, and placeholder matches exactly.
- No added, removed, or renamed fields.

### Completeness
| Required Guidance | Present? | Notes |
|---|---|---|
| core_value derivation | ✅ | "derive from vision/requirements; one critical workflow; phrased as must-work" |
| constraints[].type enum values | ✅ | "use only tech\|timeline\|budget\|dependency\|compatibility" |
| key_decisions format | ✅ | "list of objects; outcome in pending\|good\|revisit; date YYYY-MM-DD" |
| Update-vs-blank rules | ✅ | "if file exists, update changed facts only, append new constraints/decisions; do not blank fields. For new files, populate all fields; use 'TBD' only if blocked" |

### Style Match
- Line/token limits stated: `<= 80 lines, ~350 tokens` ✅
- Terse bullet format, no verbose prose ✅
- Matches P2_F terseness ✅

### Example Quality
- Realistic (deadfish-cli project) ✅
- All schema fields covered: name, description, core_value, constraints (2 entries with different types), context, key_decisions, assumptions, open_questions ✅
- No schema/example inconsistencies ✅

### Issues
None.

### **Verdict: PASS** ✅

---

## T02: P2_REQUIREMENTS_TEMPLATE.md

### Schema Fidelity
- YAML schema is **VERBATIM** from Section 1 (`REQUIREMENTS.md` block) and Section 3.
- No added, removed, or renamed fields.

### Completeness
| Required Guidance | Present? | Notes |
|---|---|---|
| 5 design principles | ✅ | All 5 listed verbatim under "Key design principles" |
| ID format (CAT-NN) | ✅ | "uppercase CAT, two digits. IDs never reused or renumbered" |
| DET/LLM tagging | ✅ | "acceptance.type is `DET` or `LLM` only; pre-tag at P2; downstream inherits" |
| Traceability | ✅ | "requirement → phase (in REQUIREMENTS.md) AND phase → requirements (in ROADMAP.md)" |
| Coverage audit | ✅ | "total_v1 = count of v1; mapped = v1 with phase; unmapped = total_v1 - mapped" |
| Status lifecycle | ✅ | "pending → in_progress → complete → blocked (only advance on phase start / criteria pass / external block)" |

### Style Match
- Line/token limits stated: `<= 120 lines, ~500 tokens` ✅
- Terse bullet format ✅
- Field notes are comprehensive but not verbose ✅

### Example Quality
- Realistic, covers v1 (2 entries), v2 (1 entry), out_of_scope, coverage ✅
- IDs follow CAT-NN format (CLI-01, PIPE-01, ORCH-01) ✅
- Coverage numbers consistent (total_v1=2, mapped=2, unmapped=0) ✅
- No schema/example inconsistencies ✅

### Issues

| Severity | Issue | Fix Needed |
|---|---|---|
| LOW | Status lifecycle shown as linear chain (`pending → in_progress → complete → blocked`) while restructure plan shows branching (pending→in_progress, then in_progress→complete OR in_progress→blocked). Parenthetical conditions clarify intent, but the arrow notation is slightly misleading. | Cosmetic only — no fix required. Conditions are correctly stated. |

### **Verdict: PASS** ✅

---

## T03: P2_ROADMAP_TEMPLATE.md

### Schema Fidelity
- YAML schema is **VERBATIM** from Section 1/5 (`ROADMAP.md` block). Every key, order, comment, and placeholder matches exactly.
- No added, removed, or renamed fields.

### Completeness
| Required Guidance | Present? | Notes |
|---|---|---|
| Tracks→phases shift explanation | ✅ | "old = tracks with steps/deliverables. new = phases with goals + success_criteria + requirement references. No task-level detail." |
| success_criteria guidance (verify.sh + P9) | ✅ | "observable, testable; feeds verify.sh + P9. avoid subjective phrasing" |
| Requirement cross-refs | ✅ | "must be valid REQUIREMENTS.md IDs; keep bidirectional traceability" |
| depends_on | ✅ | "list earlier phase IDs; keep ordering acyclic and explicit" |
| Progress tracking | ✅ | "total/completed/current reflect real status; update as phases move" |
| No task-level detail | ✅ | "Phase structure: phases only. tracks are JIT later (P3/P4). no steps/tasks/deliverables here." |

### Style Match
- Line/token limits stated: `<= 100 lines, ~400 tokens` ✅
- Terse bullet format ✅
- Matches P2_F terseness ✅

### Example Quality
- Realistic (2 phases: Foundation + Orchestration) ✅
- All schema fields covered including depends_on, requirements, success_criteria, estimated_tracks, status ✅
- Progress numbers consistent (total_phases=2, completed=0, current_phase=1) ✅
- No schema/example inconsistencies ✅

### Issues
None.

### **Verdict: PASS** ✅

---

## Overall Verdict: **CLEAN** ✅

All three templates pass review. Schemas are verbatim from the restructure plan. All required guidance is present. Style matches P2_F terseness. Examples are realistic and consistent with schemas.

One LOW-severity cosmetic note on T02 status lifecycle notation (linear vs branching representation) — no fix required.

**Ready for T04–T06 (integration into P2_E/P2_F/P2_MAIN).**
