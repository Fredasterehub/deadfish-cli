# P6 Codex Implementation Prompts (Tasks A & B)
> Each section below is a standalone `gpt-5.2-codex` implementation prompt.

---
## Task A — Update `generate_task` in `CLAUDE.md`

You are `gpt-5.2-codex` operating in the repo root.

## Goal
Update **only** the `generate_task` action specification in `CLAUDE.md` to match the new **P6 = JIT task compiler/binder** design (mechanical by default; GPT only on drift/retry).

Additionally, make the **minimal** `create_plan` spec edit needed to add `track.plan_base_commit` to `STATE.yaml` (this field is required by the new P6 drift detection).

## Source-of-truth docs for intent (read these first)
- Pipeline contract to edit: `CLAUDE.md`
- Approved P6 design: `.pipe/p6-gpt52-consultation.md`
- TASK.md format proposal: `.pipe/p6-analysis-opus.md`
- Prior GPT-5.2 analysis + template: `.pipe/p6-analysis-gpt52.md`
- P5 PLAN format (P6 input): `.pipe/p5/P5_CREATE_PLAN.md`
- Style references (layered prompt structure): `.pipe/p3/P3_PICK_TRACK.md`, `.pipe/p4/P4_CREATE_SPEC.md`

## Hard constraints
- Do **not** change the DECIDE table, especially row 10:
  - `| 10 | execute | task.sub_step: null or generate | generate_task |`
- Do **not** change any other action specs (except the single `create_plan` state-update bullet required to add `track.plan_base_commit`).
- Do **not** change any sentinel formats or the Sentinel Parsing section.
- Keep changes in `CLAUDE.md` surgical and localized.

## The exact current `CLAUDE.md` text you must replace (current `generate_task` spec)
Replace this entire section with the new “JIT compiler/binder” `generate_task` spec.

```md
### `generate_task` (execute phase)

Construct the GPT-5.2 planner prompt using the **layered prompt structure**:

```
--- ORIENTATION (0a-0c) ---
0a. Read STATE.yaml: current phase, track, task position, last_result, loop.stuck_count.
0b. Read track spec and existing plan docs. Read OPS.md if present.
0c. Search the codebase (`rg`, `find`) for existing implementations related to this track.
    Do NOT assume functionality is missing — confirm with code search first.

--- OBJECTIVE (1) ---
1. Generate the next task specification for track "{track.name}".
   Output EXACTLY ONE sentinel plan block with nonce {nonce}.
   Follow the <<<PLAN:V1:NONCE={nonce}>>> format precisely.

--- RULES ---
FILES minimization: Prefer ≤5 files unless strictly necessary.
  Every file must have a rationale tied to an acceptance criterion.
Acceptance testability: Each ACn MUST be prefixed:
  - "DET: ..." for criteria covered by verify.sh's 6 checks ONLY (tests pass, lint pass, diff within 3×estimate, no blocked paths, no secrets, git clean)
  - "LLM: ..." for everything else (code quality, design patterns, documentation tone, file existence, specific content, CLI output matching)
ESTIMATED_DIFF calibration: Estimate smallest plausible implementation.
  If estimate >200 lines, split into multiple tasks.

--- GUARDRAILS (999+) ---
99999. Output ONLY the sentinel plan block. No preamble, no explanation.
999999. Do not hallucinate files that don't exist in the codebase.
9999999. Acceptance criteria must be testable — no vague verbs without metrics.
```

Parse output with `extract_plan.py --nonce <nonce>`.

On parse success: write TASK.md from parsed plan, update STATE:
   ```yaml
   task.id: <from plan>
   task.description: <from plan>
   task.sub_step: implement
   task.files_to_load: <from plan FILES>
   ```
On parse failure after retry: `CYCLE_FAIL`
```

## The exact `CLAUDE.md` text you must minimally amend (current `create_plan` state updates)
Add exactly one bullet for `track.plan_base_commit` (and do not otherwise reword or restructure this section).

```md
### `create_plan` (select-track phase)

1. Load `STATE.yaml`, the track `SPEC.md` at `track.spec_path`, `PROJECT.md`, and `OPS.md` (if present).
2. Consult GPT-5.2 planner using `.pipe/p5/P5_CREATE_PLAN.md`.
3. Expect exactly one PLAN sentinel block:
   ```
   <<<PLAN:V1:NONCE={nonce}>>>
   ...
   <<<END_PLAN:NONCE={nonce}>>>
   ```
4. Parse output with `extract_plan.py --nonce <nonce>` (see [Sentinel Parsing](#sentinel-parsing)).
5. Write plan to `.deadf/tracks/{track.id}/PLAN.md`.
6. Update `STATE.yaml`:
   - `track.plan_path: ".deadf/tracks/{track.id}/PLAN.md"`
   - `track.task_count: <from PLAN TASK_COUNT>`
   - `track.task_current: 1`
   - `track.status: in-progress` (keep consistent with pipeline)
   - `phase: execute`
   - `task.sub_step: generate`
```

## Required updates to implement in `CLAUDE.md`

### 1) Rewrite `generate_task` as “JIT task compiler/binder”
Update the action spec to match this contract:

- **Inputs:**
  - `STATE.yaml`
  - `.deadf/tracks/{track.id}/PLAN.md`
  - `OPS.md` (if present)
  - current repo tree at `HEAD`
- **Output file (write):**
  - `.deadf/tracks/{track.id}/tasks/TASK_{NNN}.md` where `NNN` is the 1-based `track.task_current` zero-padded to 3 digits.

Behavior must define three paths:

**Happy path (first attempt, no drift):** *no GPT call*
1. Extract `TASK[{track.task_current}]` from `.deadf/tracks/{track.id}/PLAN.md`.
2. Validate planned file paths against current `HEAD`:
   - For `modify`/`delete`, the target path must exist at `HEAD`.
   - Use deterministic checks (`find`, `test -f`, `rg`) — do not guess.
3. Compute fresh `task.files_to_load` (cap: **≤ 3000 tokens** total content):
   - Start with planned `FILES` paths (especially all `modify`/`delete` targets).
   - Add the minimal set of: relevant tests, configs, and entrypoints/integration points.
4. Copy relevant commands from `OPS.md` into the task packet (tests/lint/build/run).
5. Write `.deadf/tracks/{track.id}/tasks/TASK_{NNN}.md` as **structured markdown** (not sentinel) using the TASK file format spec you add (see below).
6. Update `STATE.yaml` (do not change DECIDE table behavior):
   - `task.id` (from plan task)
   - `task.description` (from plan task; typically `TITLE` or `TITLE + short summary`)
   - `task.sub_step: implement`
   - `task.files_to_load` (the computed context pack paths; not the plan FILES list)

**Drift path (plan_base_commit != HEAD AND bindings need adaptation):**
- Drift detection is based on:
  - `track.plan_base_commit` vs `HEAD` AND
  - evidence that plan file bindings are stale (missing `modify/delete` targets, moved files, integration point no longer present).
- In this case, do a **small GPT call** using `.pipe/p6/P6_GENERATE_TASK.md` to adapt only bindings and context (do not re-plan).
- The output is still a structured markdown task packet written to `.deadf/tracks/{track.id}/tasks/TASK_{NNN}.md`.

**Retry path (`task.retry_count > 0`):**
- Use `.pipe/p6/P6_GENERATE_TASK.md` to package failure context and adapt execution guidance.
- Keep acceptance criteria **immutable**; append retry guidance after the original SUMMARY, never replace it.

### 2) Add `track.plan_base_commit` to `create_plan` state updates (minimal change)
In `create_plan` step 6 (“Update STATE.yaml”), add:
- `track.plan_base_commit: <git rev-parse HEAD>` (recorded at plan creation time)

### 3) Add a TASK file format specification inside `generate_task`
In the rewritten `generate_task` spec, include a concise, explicit TASK packet format spec:
- Structured markdown (no sentinel).
- Optional YAML frontmatter allowed.
- Must carry through (verbatim) the plan task fields:
  - `TASK_ID`, `TITLE`, `SUMMARY`, `FILES`, `ACCEPTANCE`, `ESTIMATED_DIFF`, `DEPENDS_ON`
- Must include:
  - `OPS.md` command list
  - `task.files_to_load` list (ordered; capped; with short “why” per entry)
  - “Hard stop” rules and the `REPLAN_REQUIRED` / “request split” signals.

### 4) Hard stops (must be explicitly specified)
In `generate_task`, document these deterministic stop conditions:
- If any planned `modify/delete` target is missing and cannot be resolved safely → `REPLAN_REQUIRED` (do not guess).
- If plan `ESTIMATED_DIFF` is exceeded by **>3×** in the required change size → request split (do not proceed).

## Done-when checklist
- [ ] `CLAUDE.md` DECIDE table unchanged (row 10 unchanged)
- [ ] `CLAUDE.md` `generate_task` spec matches the new JIT compiler/binder behavior (mechanical happy path; GPT only drift/retry)
- [ ] `CLAUDE.md` `generate_task` spec documents inputs/outputs exactly (PLAN.md → TASK_{NNN}.md)
- [ ] `CLAUDE.md` `generate_task` spec includes a structured TASK packet format spec (markdown + optional YAML frontmatter)
- [ ] `CLAUDE.md` `create_plan` state update list includes `track.plan_base_commit` and nothing else is reworded
- [ ] No other action specs changed

---
## Task B — Create `.pipe/p6/P6_GENERATE_TASK.md`

You are `gpt-5.2-codex` operating in the repo root.

## Goal
Create the GPT-5.2 prompt file used **only** by P6 on **drift** and **retry** paths:
- Create: `.pipe/p6/P6_GENERATE_TASK.md`

This is not used on the happy path (happy path is deterministic extraction/binding without a GPT call).

## References (read for intent/style)
- Design intent: `.pipe/p6-gpt52-consultation.md`
- TASK.md format + drift/retry guidance: `.pipe/p6-analysis-opus.md`, `.pipe/p6-analysis-gpt52.md`
- P5 PLAN task format (input shape): `.pipe/p5/P5_CREATE_PLAN.md`
- Layered style reference: `.pipe/p3/P3_PICK_TRACK.md`, `.pipe/p4/P4_CREATE_SPEC.md`

## Content requirements for `.pipe/p6/P6_GENERATE_TASK.md`
Write a layered prompt template matching the P3/P4/P5 style and incorporating the sections below.

### Must include this layered structure (with these exact section names)

--- ORIENTATION (0a-0c) ---
0a. Read `STATE.yaml`: track info, `task_current`, `task_count`, `retry_count`, `last_result`, `plan_base_commit`.
0b. Read `PLAN.md` at `track.plan_path`. Extract `TASK[task_current]`. If retry, read existing `.deadf/tracks/{track.id}/tasks/TASK_{NNN}.md`.
0c. Read `OPS.md`. Check current `HEAD` vs `plan_base_commit`. Search codebase for planned file paths.

--- OBJECTIVE (1) ---
Produce an adapted execution packet for `TASK[task_current]`.
- If drift: resolve file path changes, update integration points, adjust `files_to_load`.
- If retry: analyze `last_result.details`, add retry context (what failed, what to change, what not to repeat).
- Keep acceptance criteria **IMMUTABLE** — never weaken on retry.
- Keep `SUMMARY` from PLAN as primary prompt — append adaptations, don’t replace.

Output: a structured markdown TASK file (not sentinel).

--- RULES ---
- Pass through `TASK_ID`, `TITLE`, `SUMMARY`, `FILES`, `ACCEPTANCE`, `ESTIMATED_DIFF`, `DEPENDS_ON` from PLAN.
- On drift: update `FILES` paths to current reality; flag any that no longer make sense.
- On retry: append retry guidance **after** the original `SUMMARY`.
- `files_to_load` priority: modify targets → entrypoints → tests → config → style anchors.
- Cap `files_to_load` at **3000 tokens**.
- If modify/delete targets are missing and cannot be resolved → output `REPLAN_REQUIRED` (do not guess).

--- GUARDRAILS (999+) ---
99999. Do not re-plan. Only adapt bindings and context.
999999. Acceptance criteria are immutable.
9999999. If drift is unresolvable, output `REPLAN_REQUIRED` — don’t guess.

### Output format spec (must be explicit in the prompt)
Define the TASK markdown structure the model must emit (matching Task A’s contract):
- Optional YAML frontmatter allowed.
- Must include: Meta (task id, attempt, estimated/max diff), Objective (TITLE), SUMMARY (verbatim + appended guidance), Files (resolved), Acceptance (verbatim), Commands (from OPS.md), Context Pack (`files_to_load` list).
- If emitting `REPLAN_REQUIRED`, require a single short block that starts with `REPLAN_REQUIRED:` and includes the reason(s) (no task packet).

## Done-when checklist
- [ ] `.pipe/p6/P6_GENERATE_TASK.md` exists
- [ ] It matches the layered prompt style of `.pipe/p3/P3_PICK_TRACK.md` / `.pipe/p4/P4_CREATE_SPEC.md`
- [ ] It is explicitly scoped to drift/retry only (no happy-path usage)
- [ ] It enforces “no re-plan” and “acceptance immutable” guardrails
- [ ] It defines the structured markdown TASK output format and the `REPLAN_REQUIRED` signal

