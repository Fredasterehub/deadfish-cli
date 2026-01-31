# T10 Review — CLAUDE.md Action Specifications Update

**Reviewer:** Opus subagent  
**Date:** 2025-07-18  
**Commit:** HEAD (after T07-T09 commit `1d8c237`)  
**Verdict:** CLEAN (with minor notes)

---

## Checklist

- [x] `seed_docs` references all 5 output files (VISION.md, PROJECT.md, REQUIREMENTS.md, ROADMAP.md, STATE.yaml)
- [x] `pick_track` references P3_PICK_TRACK.md and TRACK sentinel
- [x] `create_spec` references P4_CREATE_SPEC.md and SPEC sentinel
- [x] `create_plan` references P5_CREATE_PLAN.md and PLAN sentinel
- [x] `.deadf/tracks/{id}/` structure documented (Track artifacts subsection)
- [x] All file paths consistent with actual repo (`.pipe/p3/`, `.pipe/p4/`, `.pipe/p5/` all exist)
- [x] DECIDE table unchanged (rows 7-9 already had `pick_track`, `create_spec`, `create_plan` — no diff in DECIDE section)
- [x] No other sections modified unnecessarily (diff is 65 changed lines, all within Action Specifications)

## Sentinel Format Cross-Reference

| Sentinel | CLAUDE.md | Prompt File | Match? |
|----------|-----------|-------------|--------|
| TRACK | `<<<TRACK:V1:NONCE={nonce}>>>` / `<<<END_TRACK:NONCE={nonce}>>>` | P3_PICK_TRACK.md — same | ✅ |
| SPEC | `<<<SPEC:V1:NONCE={nonce}>>>` / `<<<END_SPEC:NONCE={nonce}>>>` | P4_CREATE_SPEC.md — same | ✅ |
| PLAN | `<<<PLAN:V1:NONCE={nonce}>>>` / `<<<END_PLAN:NONCE={nonce}>>>` | P5_CREATE_PLAN.md — same | ✅ |

## STATE.yaml Field Consistency

| Action | CLAUDE.md fields | Restructure plan fields | Delta |
|--------|-----------------|------------------------|-------|
| `pick_track` | `track.id`, `.name`, `.phase`, `.requirements`, `.goal`, `.estimated_tasks`, `.status: in-progress`, `.spec_path: null`, `.plan_path: null` | Same + `track.status: "selected"` | Status value differs (see note 1) |
| `create_spec` | `track.spec_path`, `track.status: in-progress` | Same + `track.status: "spec-ready"` | Status value differs (see note 1) |
| `create_plan` | `track.plan_path`, `track.status: in-progress`, `phase: execute`, `task.sub_step: generate` | Same + `track.status: "planned"`, `track.task_count`, `track.task_current: 1` | Status value differs; missing `task_count`/`task_current` (see note 2) |

## Notes (non-blocking)

### Note 1: Simplified track.status values
The restructure plan (§6-8) uses granular status values: `selected` → `spec-ready` → `planned`. CLAUDE.md uses `in-progress` for all three. This is acceptable because the DECIDE table (rows 7-9) routes on `spec_path`/`plan_path` presence, NOT on `track.status`. No functional impact.

### Note 2: Missing `task_count` and `task_current` in `create_plan`
The restructure plan §8 specifies setting `track.task_count: <N>` and `track.task_current: 1` after plan creation. CLAUDE.md omits these. Low impact — task sequencing is handled by `extract_plan.py` and PLAN.md content. Could be added later if task-level progress tracking in STATE.yaml is desired.

### Note 3: PHASE_COMPLETE/PHASE_BLOCKED signal format
P3_PICK_TRACK.md specifies these as fields within a TRACK sentinel block (e.g., `PHASE_COMPLETE=true` inside `<<<TRACK:V1:...>>>`). CLAUDE.md's `pick_track` step 5 describes them as signals. Both are consistent — the parsing will extract these from the sentinel block.

## Files Reviewed
- `CLAUDE.md` (full, focus lines 177-260)
- `.pipe/p2-p5-restructure-opus.md` (§6-8, §10 T10)
- `.pipe/p3/P3_PICK_TRACK.md`
- `.pipe/p4/P4_CREATE_SPEC.md`
- `.pipe/p5/P5_CREATE_PLAN.md`
- `git diff HEAD~1 -- CLAUDE.md`

## Conclusion

**CLEAN.** All T10 requirements met. The three non-blocking notes are simplifications that don't affect correctness — the DECIDE table routing logic and sentinel parsing are fully consistent across CLAUDE.md and the P3/P4/P5 prompt files.
