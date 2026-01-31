# Batch 4 QA Review — CLAUDE.md Update (T10)

**Reviewer:** Opus 4.5 (subagent)
**Date:** 2025-07-18
**Verdict:** NEEDS_FIXES
**Overall:** 1 medium issue, 2 low issues

---

## Checklist Results

### seed_docs action ✅ PASS
- [x] References all 5 output files: VISION.md, PROJECT.md, REQUIREMENTS.md, ROADMAP.md, STATE.yaml
- [x] Consistent with P2_F.md's 5-file output (exact match)
- [x] P2_DONE marker check and phase transitions correct

### pick_track action ✅ PASS
- [x] References `.pipe/p3/P3_PICK_TRACK.md`
- [x] Loading: STATE.yaml, ROADMAP.md, REQUIREMENTS.md, VISION.md, PROJECT.md — matches P3 prompt orientation
- [x] TRACK sentinel format: `<<<TRACK:V1:NONCE={nonce}>>>...<<<END_TRACK:NONCE={nonce}>>>` — matches P3
- [x] PHASE_COMPLETE handling documented (verify criteria → advance roadmap.current_phase)
- [x] PHASE_BLOCKED handling documented (set phase: needs_human, surface REASONS)
- [x] STATE.yaml updates: track.id, track.name, track.phase, track.requirements, track.goal, track.estimated_tasks, track.status, track.spec_path=null, track.plan_path=null

### create_spec action ✅ PASS
- [x] References `.pipe/p4/P4_CREATE_SPEC.md`
- [x] Loading: STATE.yaml, ROADMAP.md, REQUIREMENTS.md, PROJECT.md, OPS.md, codebase search — matches P4 prompt
- [x] SPEC sentinel format: `<<<SPEC:V1:NONCE={nonce}>>>...<<<END_SPEC:NONCE={nonce}>>>` — matches P4
- [x] Output path: `.deadf/tracks/{track.id}/SPEC.md`
- [x] Updates track.spec_path in STATE.yaml

### create_plan action ⚠️ NEEDS_FIX
- [x] References `.pipe/p5/P5_CREATE_PLAN.md`
- [x] Loading: STATE.yaml, SPEC.md, PROJECT.md, OPS.md — matches P5 prompt
- [x] PLAN sentinel format: `<<<PLAN:V1:NONCE={nonce}>>>...<<<END_PLAN:NONCE={nonce}>>>` — matches P5
- [x] Output path: `.deadf/tracks/{track.id}/PLAN.md`
- [x] Sets phase→execute, task.sub_step→generate
- [ ] **Missing `track.task_count` and `track.task_current` initialization** (see Issue #1)

### DECIDE table ✅ PASS
- Rows 7-9 unchanged and correct:
  - Row 7: `select-track` + No track selected → `pick_track`
  - Row 8: `select-track` + Track selected, no spec → `create_spec`
  - Row 9: `select-track` + Spec exists, no plan → `create_plan`
- Conditions use track.id/spec_path/plan_path null checks — works correctly with new flow

### Cross-consistency ✅ PASS (with caveats)
- [x] Sentinel formats in CLAUDE.md match P3/P4/P5 prompt files exactly
- [x] File paths consistent: `.pipe/p3/P3_PICK_TRACK.md`, `.pipe/p4/P4_CREATE_SPEC.md`, `.pipe/p5/P5_CREATE_PLAN.md`
- [x] `.deadf/tracks/` directory structure documented (Track artifacts section)
- [ ] tasks/ subdirectory not documented (see Issue #3 — low)

---

## Issues

### Issue #1 — MEDIUM: Missing task_count/task_current in create_plan STATE.yaml updates

**Description:** The master plan (Section 8) specifies that create_plan should initialize `track.task_count: <N>` and `track.task_current: 1` in STATE.yaml. CLAUDE.md's create_plan action omits both fields. The `reflect` action already references `task_current` ("increment `task_current`"), so this field is used downstream but never initialized.

P5's PLAN sentinel includes `TASK_COUNT=<N>`, so the value is available at parse time.

**Impact:** Without task_current, generate_task has no way to know which task in the plan to process next. Without task_count, there's no way to determine track completion.

**Fix:** Add to create_plan's STATE.yaml update list:
```yaml
track.task_count: <from PLAN TASK_COUNT>
track.task_current: 1
```

**Location:** CLAUDE.md, `create_plan` action, step 6 (STATE.yaml updates)

### Issue #2 — LOW: track.status values diverge from master plan

**Description:** Master plan specifies granular status progression: `"selected"` (after pick_track) → `"spec-ready"` (after create_spec) → `"planned"` (after create_plan). CLAUDE.md uses `"in-progress"` uniformly for all three, with comments "(keep consistent with pipeline)".

**Impact:** Cosmetic only. The DECIDE table uses phase + spec_path/plan_path null checks, not track.status, to determine the next action. No functional breakage.

**Fix (optional):** Either adopt the master plan's granular statuses or document the simplification as intentional. Current state is fine but inconsistent with the design doc.

### Issue #3 — LOW: tasks/ subdirectory not in track artifacts

**Description:** Master plan Section 8 documents `.deadf/tracks/{track_id}/tasks/` for individual TASK_xxx.md files extracted from PLAN.md. CLAUDE.md's "Track artifacts" section only lists SPEC.md and PLAN.md.

**Impact:** Minor documentation gap. generate_task currently writes to a single TASK.md in the project root. If/when task extraction from PLAN.md is implemented, this would need updating.

**Fix (optional):** Add to Track artifacts section:
```
- `.deadf/tracks/{track.id}/tasks/` — extracted task files (P6)
```

---

## Summary

The CLAUDE.md T10 changes are well-executed. The four action specs (seed_docs, pick_track, create_spec, create_plan) correctly reference the new P3/P4/P5 prompt files, document the correct sentinel formats, and list accurate loading requirements. Cross-consistency with the actual prompt files is excellent — sentinel formats, file paths, and loading requirements all match.

The one blocking issue is the missing `track.task_count` and `track.task_current` initialization in create_plan, which creates a gap between plan creation and task generation/reflect. The two low-severity items are cosmetic inconsistencies with the master plan that don't affect functionality.
