# P6 Implementation Review — QA (Opus 4.5)

**Date:** 2025-07-27  
**Reviewer:** Claude Opus 4.5 (QA sub-agent)  
**Scope:** CLAUDE.md Task A (generate_task spec + create_plan amendment) + P6_GENERATE_TASK.md Task B (drift/retry prompt)

---

## File 1: CLAUDE.md — Verdict: **PASS**

### generate_task spec

| Check | Status | Notes |
|-------|--------|-------|
| Three paths defined (happy/drift/retry) | ✅ | Clearly delineated with headers and distinct behavior |
| Happy path: NO GPT call, mechanical extraction | ✅ | "no GPT call" explicitly stated; steps are deterministic (extract, validate, compute, write) |
| Drift path: uses P6_GENERATE_TASK.md | ✅ | References `.pipe/p6/P6_GENERATE_TASK.md`; triggered by plan_base_commit != HEAD + stale bindings |
| Drift detection requires BOTH conditions | ✅ | Explicitly requires plan_base_commit differs AND evidence of stale bindings (missing targets, moved files, etc.) |
| Retry path: uses P6_GENERATE_TASK.md | ✅ | Triggered by `task.retry_count > 0`; packages failure context |
| Inputs correct | ✅ | STATE.yaml, PLAN.md, OPS.md, current repo tree at HEAD |
| Output path correct | ✅ | `.deadf/tracks/{track.id}/tasks/TASK_{NNN}.md` with NNN = task_current zero-padded to 3 digits |
| TASK file format: structured markdown, not sentinel | ✅ | Explicitly states "structured markdown (no sentinel)" with example template |
| Pass-through fields | ✅ | TASK_ID, TITLE, SUMMARY, FILES, ACCEPTANCE, ESTIMATED_DIFF, DEPENDS_ON — all listed as "verbatim from PLAN" |
| Hard stops: REPLAN_REQUIRED | ✅ | "If any planned modify/delete target is missing and cannot be resolved safely → REPLAN_REQUIRED" |
| Hard stops: REQUEST_SPLIT | ✅ | "If required change size exceeds plan ESTIMATED_DIFF by >3× → REQUEST_SPLIT" |
| STATE.yaml updates | ✅ | task.id, task.description, task.sub_step: implement, task.files_to_load |
| files_to_load budget ≤3000 tokens | ✅ | Explicitly stated: "cap: ≤ 3000 tokens total content" |
| files_to_load priority ordering | ✅ | "Start with planned FILES paths (especially modify/delete targets). Add minimal set of relevant tests, configs, and entrypoints/integration points." |
| OPS commands included in packet | ✅ | "Copy relevant commands from OPS.md into the task packet (tests/lint/build/run)" |
| TASK packet minimum sections documented | ✅ | Full example structure provided with all required sections |

### create_plan amendment

| Check | Status | Notes |
|-------|--------|-------|
| Added `track.plan_base_commit: <git rev-parse HEAD>` | ✅ | Present in create_plan STATE.yaml updates |
| Added `task.sub_step: generate` | ⚠️ | Also sets `task.sub_step: generate` — this is correct per the design (ensures DECIDE row 10 triggers generate_task on next cycle). Not an extra change, it's needed for the flow. |
| No other rewording or restructuring | ✅ | The create_plan spec maintains its existing structure. Only additions are `track.plan_base_commit` and `task.sub_step: generate` in the STATE.yaml update block. |

### DECIDE table

| Check | Status | Notes |
|-------|--------|-------|
| Row 10 unchanged | ✅ | `execute` + `task.sub_step: null or generate` → `generate_task` — matches exactly |
| No other rows modified | ✅ | All 14 rows match expected structure; no insertions, deletions, or modifications |

### No other action specs changed

| Check | Status | Notes |
|-------|--------|-------|
| Other action specs untouched | ✅ | seed_docs, pick_track, create_spec, implement_task, verify_task, reflect, retry_task, replan_task, rollback_and_escalate, summarize, escalate — all appear unchanged |

### Minor observations (non-blocking)

1. **TASK packet example uses `## FILES_TO_LOAD`** — The example structure shows `FILES_TO_LOAD` as a section with `path: ... | why: ...` entries. This is good; it provides traceability for why each file was loaded.
2. **HARD STOPS section in packet** — The example includes `REPLAN_REQUIRED: <true|false + reason>` and `REQUEST_SPLIT: <true|false + reason>` inline in the TASK packet itself. This is useful for the implementer to know when to bail out.

---

## File 2: P6_GENERATE_TASK.md — Verdict: **NEEDS_FIXES**

### Structural check

| Check | Status | Notes |
|-------|--------|-------|
| Layered structure (0a-0c / 1 / rules / 999+) | ✅ | Follows the established P3/P4/P5 pattern: ORIENTATION (0a-0c), OBJECTIVE (1), OUTPUT FORMAT (2), RULES, GUARDRAILS (999+) |
| Explicitly scoped to drift/retry only | ✅ | "This prompt is used ONLY on drift or retry paths (no happy-path usage)" — stated in section 1 |
| Orientation reads STATE.yaml | ✅ | 0a reads STATE.yaml: track info, task_current, task_count, retry_count, last_result, plan_base_commit |
| Orientation reads PLAN.md | ✅ | 0b reads PLAN.md, extracts TASK[task_current] |
| Orientation reads OPS.md | ✅ | 0c reads OPS.md |
| Orientation checks HEAD vs plan_base_commit | ✅ | 0c: "Check current HEAD vs plan_base_commit" |
| Objective: adapt bindings (drift) | ✅ | "If drift: resolve file path changes, update integration points, adjust files_to_load" |
| Objective: package failure context (retry) | ✅ | "If retry: analyze last_result.details, add retry context (what failed, what to change, what not to repeat)" |
| Acceptance criteria immutable guardrail | ✅ | "Keep acceptance criteria IMMUTABLE - never weaken on retry" + guardrail 999999 |
| SUMMARY preserved (append, don't replace) | ✅ | "Keep SUMMARY from PLAN as primary prompt - append adaptations, do not replace" in OBJECTIVE; "On retry, append retry guidance AFTER the original SUMMARY (don't replace or edit the SUMMARY)" in RULES |
| REPLAN_REQUIRED signal defined | ✅ | Output option B: "REPLAN_REQUIRED: <short reason(s)>" with "If REPLAN_REQUIRED is emitted, do not output any TASK markdown" |
| No re-planning guardrail | ✅ | Guardrail 99999: "Do not re-plan. Only adapt bindings and context." |

### Issues found

#### Issue 1: files_to_load priority ordering incomplete — Severity: **MEDIUM**

**Problem:** The RULES section says `files_to_load priority: modify targets -> entrypoints -> tests -> config -> style anchors` which is good, but the OUTPUT FORMAT section's Context Pack just lists bare paths with no ordering requirement or "why" annotation.

Compare to CLAUDE.md's TASK packet format which specifies:
```
## FILES_TO_LOAD (ordered, capped)
- path: ... | why: ...
```

The P6_GENERATE_TASK.md output format shows:
```
## Context Pack (files_to_load)
- <path>
- <path>
```

**Fix:** Update the Context Pack section in the output format to include the "why" annotation and an explicit ordering note:

```markdown
## Context Pack (files_to_load, ordered by priority, ≤3000 tokens)
- <path> — <why this file is needed>
- <path> — <why this file is needed>
```

#### Issue 2: 3000-token cap not stated in output format — Severity: **LOW**

**Problem:** The RULES section mentions "Cap files_to_load at 3000 tokens" but the output format template for Context Pack doesn't include the budget constraint visually. CLAUDE.md's example shows `(ordered, capped)`. The prompt template should reinforce this in the output format itself so the LLM sees it at output time.

**Fix:** Add `(≤3000 tokens)` to the Context Pack heading in the output format (as shown in Issue 1 fix above).

#### Issue 3: Missing `REQUEST_SPLIT` signal — Severity: **MEDIUM**

**Problem:** CLAUDE.md's generate_task spec defines two hard stops: `REPLAN_REQUIRED` (missing targets) and `REQUEST_SPLIT` (>3× estimated diff). The P6_GENERATE_TASK.md template only defines `REPLAN_REQUIRED` as an output option. There's no `REQUEST_SPLIT` signal.

While `REQUEST_SPLIT` is primarily a happy-path check (deterministic, before any GPT call), the drift/retry paths could also encounter this condition. The template should at least acknowledge it.

**Fix:** Add REQUEST_SPLIT as an alternative signal output:

```markdown
C) REQUEST_SPLIT signal only:
REQUEST_SPLIT: <short reason why estimated diff would be exceeded by >3×>

If REQUEST_SPLIT is emitted, do not output any TASK markdown.
```

Or add a rule: "If adaptation would cause the task to exceed 3× ESTIMATED_DIFF, output REQUEST_SPLIT instead of TASK markdown."

#### Issue 4: Missing `ESTIMATED_DIFF` / `max_diff` in output Meta section — Severity: **LOW-MEDIUM**

**Problem:** The output format's Meta section includes `estimated_diff` and `max_diff` (good), but the RULES section only mentions pass-through of `ESTIMATED_DIFF` generically. It doesn't explicitly state that `max_diff = 3 * ESTIMATED_DIFF` should be computed. The Meta section shows it but there's no rule enforcing it.

This is minor since the template format itself shows the computation, but adding a rule would be more robust.

**Fix:** Add to RULES: `- max_diff is always 3 × ESTIMATED_DIFF.`

---

## Cross-Consistency Checks

| Check | Status | Notes |
|-------|--------|-------|
| CLAUDE.md references `.pipe/p6/P6_GENERATE_TASK.md` for drift/retry | ✅ | Both drift and retry paths explicitly reference the template path |
| TASK file format consistency | ⚠️ | Minor divergence — see below |
| `plan_base_commit` consistently referenced | ✅ | CLAUDE.md: set in create_plan, checked in generate_task. P6_GENERATE_TASK.md: read in 0a, checked in 0c |
| Flow chain: P5 PLAN → P6 extract → TASK_{NNN}.md → P7 implement | ✅ | P5 writes PLAN.md → P6 extracts/adapts → writes TASK_{NNN}.md → P7 reads task for implementation |

### TASK format divergence detail

CLAUDE.md's example TASK packet uses `## FILES_TO_LOAD (ordered, capped)` with `- path: ... | why: ...` pipe-delimited format.

P6_GENERATE_TASK.md's output uses `## Context Pack (files_to_load)` with bare `- <path>` entries.

These should align. The CLAUDE.md format is richer (includes "why"). **Recommendation:** Update P6_GENERATE_TASK.md to match CLAUDE.md's format, including the section name `FILES_TO_LOAD` (or at minimum keep `Context Pack` but add the `| why: ...` annotations and ordering/cap note).

Additionally, CLAUDE.md's packet shows `## HARD STOPS / SIGNALS` section with inline REPLAN_REQUIRED/REQUEST_SPLIT fields. P6_GENERATE_TASK.md doesn't include this section in its TASK output (it uses REPLAN_REQUIRED as an *alternative* output, not an inline field). This is actually fine architecturally — the happy path writes the inline signals, while P6_GENERATE_TASK.md either outputs a TASK or outputs a signal. No conflict, just different expression.

---

## Summary

| File | Verdict |
|------|---------|
| CLAUDE.md (Task A) | **PASS** |
| P6_GENERATE_TASK.md (Task B) | **NEEDS_FIXES** |

### Overall: **NEEDS_FIXES**

### Required fixes (ordered by severity):

1. **MEDIUM — Issue 1+2:** Update Context Pack output format in P6_GENERATE_TASK.md to include `why` annotations, explicit ordering, and 3000-token cap in the heading. Align with CLAUDE.md's `FILES_TO_LOAD` format.

2. **MEDIUM — Issue 3:** Add `REQUEST_SPLIT` as a recognized output signal in P6_GENERATE_TASK.md (or at minimum a rule that acknowledges the 3× diff budget).

3. **LOW-MEDIUM — Issue 4:** Add explicit `max_diff = 3 × ESTIMATED_DIFF` rule.

All fixes are minor template adjustments — no architectural issues found. The design correctly implements the "JIT task compiler/binder" model from the approved consultation.
