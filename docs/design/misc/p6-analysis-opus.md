# P6 (generate_task) Analysis — Opus 4.5

## Current State

P6 currently lives inline in CLAUDE.md as a layered prompt template. It generates a sentinel PLAN block for a single task. The key question: **should P6 generate from scratch each cycle, or should it mostly extract/transform from the P5 PLAN that already exists?**

## Key Insight: P5 Already Did Most of the Work

With our P5 restructure, PLAN.md already contains:
- `TASK[n]` entries with TASK_ID, TITLE, SUMMARY (executable prompt), FILES, ACCEPTANCE, ESTIMATED_DIFF, DEPENDS_ON
- SUMMARY is already written as a direct gpt-5.2-codex prompt

**This changes P6's role fundamentally.** P6 is NOT "generate a task from scratch" anymore — it's "extract the current task from PLAN.md, enrich it with fresh context, and produce TASK.md."

## What Conductor Teaches Us

### Context Persistence
Conductor's `implement.toml` loads track context (spec + plan + workflow) at the start, then iterates tasks sequentially. Key pattern: **each task inherits the full track context** — it doesn't re-derive it.

### Task Lifecycle
Conductor's workflow defines a strict lifecycle per task:
1. Select task from plan
2. Mark in-progress
3. Write tests (TDD)
4. Implement
5. Refactor
6. Verify
7. Commit
8. Record

### Deviation Rules (Gold)
Conductor doesn't have this, but **GSD does** — and it's critical for P6. When generating a task, we need to account for:
- Previous task results (did something fail? what's the retry context?)
- Codebase changes since the plan was created (what files actually exist now?)
- Stuck detection (are we spinning on the same issue?)

## What GSD Teaches Us

### Plans-as-Prompts (Already Adopted in P5)
GSD's PLAN.md `<action>` field IS the implementation instruction. We've already adopted this in P5's SUMMARY field. P6 should **pass it through**, not regenerate it.

### Task Sizing
GSD recommends 2-3 tasks per plan, ~50% context usage max. Our P5 already constrains to 2-5 tasks, ≤200 diff lines, ≤5 files. Good.

### Goal-Backward Verification (must_haves)
GSD's `must_haves` pattern is interesting — truths, artifacts, key_links defined at plan time and verified after execution. We have this partially via ACCEPTANCE criteria, but GSD's three-level check (exists → substantive → wired) is more rigorous.

### Deviation Rules (Critical for Retry)
GSD's 4-tier deviation rules:
1. Auto-fix bugs (no permission needed)
2. Auto-add missing critical functionality (no permission needed)
3. Auto-fix blocking issues (no permission needed)
4. Ask about architectural changes (stop and escalate)

For our P6, this maps to retry handling:
- If `last_result.ok == false`: P6 should enrich the task with error context
- If `stuck_count > 0`: P6 should consider replanning (already handled by DECIDE table)

### Context Loading (50% Budget Rule)
GSD is aggressive about context budgets: "~50% context usage maximum." Our hot loop budget is ~3,750 tokens for files_to_load. P6 must be disciplined about what it loads.

## Synthesis: P6 Design Recommendation

### P6 Should Be Mostly Mechanical, Not LLM-Heavy

Since P5 already produces executable TASK entries, P6's job is:
1. **Extract** the current task from PLAN.md (using `track.task_current`)
2. **Enrich** with fresh codebase context (files that exist now, OPS.md commands)
3. **Inject retry context** if `last_result.ok == false` (error details, what was tried)
4. **Write TASK.md** in a format P7 (implement_task) can consume directly

### The Question: Does P6 Need GPT-5.2?

**Arguments for GPT-5.2:**
- Can adapt the task if codebase has changed since planning
- Can inject smarter retry strategies
- Can decompose a task further if it's too large
- Can adjust file selection based on current state

**Arguments against:**
- P5 SUMMARY is already an executable prompt — why re-generate?
- Token cost in the hot loop is expensive
- Adds latency to every cycle
- Risk of drift from the plan

**My recommendation:** P6 should be **hybrid**:
- **Normal path (first attempt):** Mostly mechanical extraction from PLAN.md + context enrichment. Light LLM touch for file selection optimization.
- **Retry path:** Full LLM involvement to analyze the error and adapt the approach.
- **Stuck path:** Already handled by replan_task action.

### Proposed TASK.md Format

TASK.md should NOT be a sentinel block — it's a structured markdown file consumed by P7:

```markdown
# TASK — {task_id}

## Meta
- track: {track.id}
- task: {task_current} of {task_count}
- phase: {track.phase}
- depends_on: {from PLAN}
- estimated_diff: {from PLAN}
- attempt: {retry_count + 1}

## Objective
{TITLE from PLAN}

## Implementation Prompt
{SUMMARY from PLAN — passed through verbatim}

## Files
{FILES from PLAN — verified against codebase}
- path: {file} | action: {add|modify|delete} | rationale: {from PLAN}
- [files_to_load for context: up to 3000 tokens]

## Acceptance Criteria
{ACCEPTANCE from PLAN}
- AC1: {DET:|LLM: criterion}
- AC2: ...

## Context
### OPS Commands
{from OPS.md — build, test, lint commands}

### Retry Context (if retry_count > 0)
Previous attempt failed:
- Error: {last_result.details}
- What was tried: {from git log or last_result}
- Suggested adjustment: {LLM-generated if retry}

### Codebase State
{Brief: files that exist at the paths listed in FILES}
```

### Token Budget

| Component | Tokens |
|-----------|--------|
| TASK.md meta + objective | ~100 |
| Implementation prompt (SUMMARY) | ~150-300 |
| Files list + rationale | ~100 |
| Acceptance criteria | ~100 |
| OPS commands | ~100 |
| Retry context (if any) | ~200 |
| **Total TASK.md** | **~650-900** |
| files_to_load (actual file content) | ≤3,000 |
| **Total P7 context** | **~3,650-3,900** |

Well within budget. Leaves plenty of room for CLAUDE.md system prompt.

### Proposed P6 Prompt Template Outline

```
--- ORIENTATION (0a-0c) ---
0a. Read STATE.yaml: track info, task_current, task_count, retry_count, last_result
0b. Read PLAN.md at track.plan_path. Extract TASK[task_current].
0c. Read OPS.md. Verify FILES paths exist in codebase (rg/find).

--- OBJECTIVE (1) ---
1. Generate TASK.md for task {task_current} of {task_count}.
   
   IF first attempt (retry_count == 0):
     Extract task from PLAN.md. Write TASK.md with:
     - SUMMARY passed through verbatim (plans-as-prompts)
     - FILES verified against codebase
     - ACCEPTANCE criteria from PLAN
     - OPS commands from OPS.md
   
   IF retry (retry_count > 0):
     Analyze last_result.details for the failure reason.
     Adapt the implementation approach:
     - If test failure: add specific fix guidance
     - If build failure: identify the build error and suggest resolution
     - If diff too large: suggest splitting
     Keep original ACCEPTANCE criteria (don't weaken them).

   Output: Write TASK.md to .deadf/tracks/{track.id}/tasks/TASK_{NNN}.md

--- RULES ---
- SUMMARY from PLAN is the primary implementation prompt — pass through verbatim on first attempt
- On retry, APPEND retry guidance after the original SUMMARY (don't replace it)
- FILES: verify all modify/delete paths exist; flag missing files as errors
- files_to_load: select the most relevant files, cap at 3000 tokens
- Acceptance criteria are immutable — never weaken them on retry

--- GUARDRAILS (999+) ---
99999. TASK.md must be self-contained — P7 should not need to read PLAN.md or SPEC.md
999999. On retry, include the specific error in retry context — not generic "try again"
```

### Key Differences from Current P6

| Aspect | Current | Proposed |
|--------|---------|----------|
| LLM involvement | Full generation every cycle | Mostly extraction; full LLM on retry only |
| Input | Track spec + plan docs | PLAN.md TASK[n] entry specifically |
| Output | Sentinel PLAN block (re-parsed) | Structured TASK.md (direct write) |
| Retry handling | Same prompt, hope for different result | Error-aware adaptation with specific guidance |
| File verification | "Don't hallucinate" guardrail | Active codebase verification (rg/find) |
| Context budget | Implicit | Explicit 3000-token cap on files_to_load |
| Plans-as-prompts | Partial (SUMMARY exists but gets re-generated) | Full (SUMMARY passed through verbatim) |
