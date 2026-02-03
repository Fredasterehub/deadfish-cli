# Task Integration — Opus Implementation Review

> **Reviewer:** Claude Opus 4.5 (sub-agent)
> **Date:** 2026-02-02
> **Spec:** `.pipe/task-integration/synthesis-opus-orchestrator.md` (Synthesis v2)
> **R2 Review:** `.pipe/task-integration/synthesis-review-gpt52-r2.md`
> **Commit:** HEAD (6 files changed, 200 insertions, 70 deletions)

---

## Verdict: CLEAN

All six checks pass. Two LOW-severity observations noted below — neither requires a code change before merge.

---

## Check 1: p1-cron-kick.sh ✅ PASS

| Requirement | Status | Notes |
|-------------|--------|-------|
| Validation: non-empty, `[A-Za-z0-9_.-]+`, ≤80 chars | ✅ | `is_valid_task_list_id()` matches spec exactly |
| Rotation: track change OR 7-day age | ✅ | Both triggers present with correct guards (`-n "$prev_track"` prevents false rotation on first run) |
| Atomic write (mktemp + mv) | ✅ | `mktemp "${TASK_LIST_ID_FILE}.tmp.XXXXXX"` → `mv -f` |
| Operator override honored | ✅ | Outer `if [[ -z "${CLAUDE_CODE_TASK_LIST_ID:-}" ]]` skips all logic when pre-set |
| `{TASK_LIST_ID}` substitution in kick message | ✅ | `kick_message=${kick_message//\{TASK_LIST_ID\}/${CLAUDE_CODE_TASK_LIST_ID:-}}` |
| `stat` added to dependency check | ✅ | Required for `stat -c %Y` in age calculation |
| No unrelated changes | ✅ | Only task-list logic + `stat` dep + blank line added |

**Code matches spec §1.3 verbatim** — the implementation is a direct lift of the spec's code block with no deviations.

## Check 2: ralph.sh ✅ PASS

| Requirement | Status | Notes |
|-------------|--------|-------|
| Read-only pass-through (no create, no rotate) | ✅ | Only reads file + exports env var |
| CR/LF stripped | ✅ | `tr -d '\r\n'` |
| Graceful if file missing | ✅ | `if [[ -f "$TASK_LIST_ID_FILE" ]]` guard |
| Placement | ✅ | Before `rotate_logs` / kick cycle, correct location |

Matches spec §1.4. No creation, no rotation, no validation beyond file existence.

## Check 3: P1_CYCLE_KICK.md ✅ PASS

| Requirement | Status | Notes |
|-------------|--------|-------|
| `{TASK_LIST_ID}` in Variables table | ✅ | Type: string, default: empty, description references `CLAUDE_CODE_TASK_LIST_ID` + disabled-mode semantics |
| `task_list_id` line in kick message body | ✅ | `task_list_id: {TASK_LIST_ID}` added after `mode:` line |

## Check 4: CLAUDE.md ✅ PASS (most critical)

| Requirement | Status | Notes |
|-------------|--------|-------|
| Old naming `deadf-{run_id}-{task_id}-{sub_step}` removed | ✅ | `grep` confirms zero hits |
| New naming `deadf/{project_slug}/{track_id}/{task_id}/gen{N}/{action}` | ✅ | §2 with full segment encoding rules |
| Sanitize rules | ✅ | Lowercase, `[^a-z0-9-]` → `-`, collapse, trim, max 40, empty → `_` |
| Launcher ownership corrected | ✅ | Multiple references: "p1-cron-kick.sh manages... ralph.sh passes through" |
| Task list lifecycle subsection | ✅ | Under "Launcher / Concurrency" section — file format, rotation triggers, rotation procedure, reset procedures (soft/hard) |
| `task.replan_generation` in STATE.yaml inventory | ✅ | §3 with YAML example and semantics |
| Cycle protocol expanded (LOAD/VALIDATE/DECIDE/EXECUTE/RECORD/REPLY) | ✅ | Both inline annotations in Steps 1-6 and dedicated §4 |
| AC tasks blocked by `implement_task` NOT `verify_task` (F1 fix) | ✅ | §5: "AC sub-tasks are blocked by `implement_task`, **not** `verify_task`" + EXECUTE text |
| Non-fatal degradation rule | ✅ | §1: "Every Task tool call is try/catch... Zero regression" |
| Mechanical gate rule | ✅ | §1: "Only perform any Task operations if `CLAUDE_CODE_TASK_LIST_ID` is set and non-empty... Never use a default/global task list" |
| Recovery algorithm as binding contract | ✅ | §6: Full 5-step algorithm with STATE.task.sub_step keyed tables (resolves R2 NF1 — both tables use STATE sub_step keys consistently) |
| Quick Reference flow diagram updated | ✅ | Task annotations on each step + launcher ownership note below |
| No stale "ralph.sh sets CLAUDE_CODE_TASK_LIST_ID" text | ✅ | `grep` confirms zero hits; replaced with correct ownership text |
| Old subsections (Session Persistence, Multi-Session, Hybrid State, Sub-Agent MCP) | ✅ | Replaced entirely by new §1-§6 structure |

**R2 finding resolution:**
- F6 (ralph pass-through documented): ✅ Resolved — CLAUDE.md + ralph.sh aligned
- F7 (CLAUDE.md contract applied): ✅ Resolved — all §7.1-§7.8 changes from spec applied
- NF1 (steps_before terminology): ✅ Resolved — both tables keyed by `STATE.task.sub_step` values (`null/generate`, `implement`, `verify`, `reflect`, `qa_review`)
- NF2 (lossy sanitization fallback): ✅ Addressed — empty → `_`, ID constraint documented
- NF3 (mechanical gate): ✅ Addressed — explicit gate rule in §1

## Check 5: Cross-file consistency ✅ PASS

| Item | p1-cron-kick.sh | ralph.sh | CLAUDE.md | P1_CYCLE_KICK.md |
|------|----------------|----------|-----------|------------------|
| Naming convention | N/A | N/A | `deadf/{slug}/{track}/{task}/gen{N}/{action}` | N/A |
| Task list file path | `$DEADF_DIR/task_list_id` | `$PROJECT_PATH/.deadf/task_list_id` | `.deadf/task_list_id` | N/A |
| Env var name | `CLAUDE_CODE_TASK_LIST_ID` | `CLAUDE_CODE_TASK_LIST_ID` | `CLAUDE_CODE_TASK_LIST_ID` | `CLAUDE_CODE_TASK_LIST_ID` |

All paths resolve to the same location. Env var name is identical across all files.

## Check 6: .gitignore ✅ PASS

| Entry | Present |
|-------|---------|
| `.deadf/task_list_id` | ✅ (line 41) |
| `.deadf/task_list_id.prev` | ✅ (line 42) |
| `.deadf/task_list_track` | ✅ (line 43) |

---

## Observations (informational, not blocking)

### OBS-1: .gitignore redundancy — LOW

The existing `.deadf/` wildcard entry (line 40) already ignores everything under `.deadf/`. The three specific entries are technically redundant. **Not a bug** — belt-and-suspenders is fine, and the explicit entries serve as documentation of which runtime files the task integration creates. No change needed.

### OBS-2: Missing blank line before template check — LOW

In `p1-cron-kick.sh`, the closing `fi` of the task list block immediately precedes `if [[ ! -f "$TEMPLATE_FILE" ]]` with no blank separator line. Cosmetic only — readability improvement, not a correctness issue.

---

## Summary

The Codex implementation is a faithful, line-by-line application of Synthesis v2. All spec requirements are met, all R2 findings (F6, F7, NF1-NF3) are resolved in the implementation, the old naming convention and stale ralph ownership text are fully removed, and cross-file consistency is maintained. No blocking issues found.
