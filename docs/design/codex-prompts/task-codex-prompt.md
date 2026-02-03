# deadf(ish) × Claude Code Tasks — Codex Implementation Prompt

You are **gpt-5.2-codex**. Implement the approved Task Management System integration for the deadf(ish) pipeline exactly as specified by the **Synthesis v2** and the **GPT-5.2 R2 review**.

This repo is already in-progress; do **not** redesign anything. Apply only the changes explicitly listed below.

---

## 1) FILES TO READ FIRST (inputs)

Read these files **in this exact order** before editing anything:

1. `.pipe/task-integration/synthesis-opus-orchestrator.md`  
   - **APPROVED Synthesis v2 — this is the spec**. You must implement it, not reinterpret it.
2. `.pipe/task-integration/synthesis-review-gpt52-r2.md`  
   - R2 review. **F6 + F7 are implementation tasks; CLAUDE.md must be updated.**
3. `CLAUDE.md`  
   - Current binding contract. You must update it to match Synthesis v2 §7 and related sections referenced below.
4. `.pipe/p1/p1-cron-kick.sh`  
   - Current launcher. You must add Task List ID management + rotation from Synthesis v2 §1.3.
5. `.pipe/p1/P1_CYCLE_KICK.md`  
   - Kick template. You must add `{TASK_LIST_ID}` variable.
6. `ralph.sh`  
   - Legacy launcher/loop controller. You must add read-only Task List ID pass-through from Synthesis v2 §1.4.
7. `PROMPT_OPTIMIZATION.md`  
   - Status tracking. You must note Task integration work.

Also read `.gitignore` (deliverable F).

---

## 2) R2 REVIEW FINDINGS TO ADDRESS (F6, F7 specifically — CLAUDE.md must be updated)

Address these **as written** in `.pipe/task-integration/synthesis-review-gpt52-r2.md`:

- **F6 (NOT_RESOLVED):** The binding contract still claims `ralph.sh` sets `CLAUDE_CODE_TASK_LIST_ID` and implies Tasks are always available. This must be corrected.  
  - Implementation source of truth: Synthesis v2 §1.4 and §7.2.
- **F7 (NOT_RESOLVED):** Synthesis v2 §7 lists explicit CLAUDE.md contract changes, but CLAUDE.md still uses the old naming convention and does not include v2 recovery algorithm / `task.replan_generation`. This must be applied.  
  - Implementation source of truth: Synthesis v2 §7 (and the cross-referenced sections §2, §3–§6).

Additionally, ensure the final contract text is **mechanically unambiguous**:
- The recovery/backfill tables and terminology must match Synthesis v2 §6.2 **exactly** (STATE values keyed tables, then action mapping).
- The degraded-mode/mechanical gate rule must be explicit and deterministic (Synthesis v2 “Design Principles” #6 and §7.7).

---

## 3) DELIVERABLES (exact specifications)

### A) Update `.pipe/p1/p1-cron-kick.sh` — add task list ID management + rotation

Implement **Synthesis v2 §1.1–§1.3** in `.pipe/p1/p1-cron-kick.sh`:

1. Insert the **entire** bash block from **Synthesis v2 §1.3**:
   - Insert **after** `$DEADF_DIR` is ensured and writable and `$STATE_FILE` is set
   - Insert **before** the `claude` invocation
2. Requirements you must preserve from Synthesis v2:
   - Task list ID file: `.deadf/task_list_id` (single line, bare string, **no trailing newline**)
   - Track file: `.deadf/task_list_track`
   - Rotation triggers: track change **OR** file age > 7 days via `P1_TASK_LIST_MAX_AGE_S` (default 604800)
   - Operator override: if `CLAUDE_CODE_TASK_LIST_ID` already set, **honor it** (no overwrite)
   - Validation rules: non-empty, `[A-Za-z0-9_.-]+`, ≤80 chars; invalid → warn + regenerate
   - Atomic write: `mktemp` + `mv`
   - Logging: use existing `log_json`
3. Add kick-template substitution for the new variable:
   - Add replacement for `{TASK_LIST_ID}` in the constructed `kick_message`.
   - Value must be `${CLAUDE_CODE_TASK_LIST_ID:-}` (empty string if unset).

Do not change unrelated launcher behavior.

### B) Update `ralph.sh` — add read-only pass-through (§1.4)

Implement **Synthesis v2 §1.4**:

- Before dispatching any cycle kick, read:
  - `TASK_LIST_ID_FILE="$PROJECT_PATH/.deadf/task_list_id"`
  - If present, export `CLAUDE_CODE_TASK_LIST_ID` to the file contents with CR/LF stripped (exact snippet from Synthesis v2 §1.4).
- **Do not** create, rotate, or modify any task-list files in ralph.
- If file does not exist: do nothing (degraded mode is acceptable).

### C) Update `.pipe/p1/P1_CYCLE_KICK.md` — add `{TASK_LIST_ID}` variable

Modify `.pipe/p1/P1_CYCLE_KICK.md`:

1. Add `{TASK_LIST_ID}` to the Variables table:
   - Type: string
   - Default: empty
   - Notes: “From env `CLAUDE_CODE_TASK_LIST_ID` (may be blank; if blank, orchestrator must run with Task features disabled).”
2. Add a line in the kick message body to surface it (recommended placement near `mode:`):
   - `task_list_id: {TASK_LIST_ID}`

### D) Update `CLAUDE.md` — binding contract changes (largest change)

You must apply **every change** listed in **Synthesis v2 §7** and ensure the binding contract is consistent with:
- Task list lifecycle: **Synthesis v2 §1.1–§1.2**
- Naming convention: **Synthesis v2 §2.1–§2.5**
- Cycle protocol + Task operations: **Synthesis v2 §3**
- Sub-step mapping + AC dependency model + failure transitions: **Synthesis v2 §4**
- Sub-agent integration: **Synthesis v2 §5**
- Recovery algorithm: **Synthesis v2 §6.2** (must appear as binding/mechanical text)
- Non-fatal degradation + mechanical gate: **Synthesis v2 Design Principles #2 and #6**
- .gitignore runtime files: **Synthesis v2 §10** (deliverable F)

Implement these CLAUDE.md changes (do not omit any):

1. **Replace task naming convention** (Synthesis v2 §7.1 + §2.1–§2.2):
   - Remove all references to `deadf-{run_id}-{task_id}-{sub_step}`.
   - Add the canonical format: `deadf/{project_slug}/{track_id}/{task_id}/gen{N}/{action}`.
   - Include the **full segment encoding rules** from Synthesis v2 §2.2, including:
     - `sanitize()` definition (lowercase, replace, collapse, trim, max 40, empty → `_`)
     - Fixed action names list (Synthesis v2 §2.2)
     - AC suffix rule `ac-{AC_id}` (Synthesis v2 §2.2)
     - Dedup-by-exact-title rule (Synthesis v2 §2.4)
2. **Fix launcher statements** (Synthesis v2 §7.2 + §1.4):
   - Replace “ralph.sh sets `CLAUDE_CODE_TASK_LIST_ID`” with:
     - `p1-cron-kick.sh` manages `CLAUDE_CODE_TASK_LIST_ID` via `.deadf/task_list_id` (create + rotate).
     - `ralph.sh` only passes through if `.deadf/task_list_id` exists; otherwise Tasks are disabled (non-fatal).
3. **Add Task list lifecycle subsection** under “Cycle Kick / Launcher” (Synthesis v2 §7.3):
   - `.deadf/task_list_id` file format + validation
   - Rotation rules (track change + 7-day max age via `P1_TASK_LIST_MAX_AGE_S`)
   - Reset procedures (soft/hard) and tracking file `.deadf/task_list_track`
4. **Add `task.replan_generation` to STATE.yaml inventory** (Synthesis v2 §7.4 + §2.5):
   - Add YAML snippet and semantics:
     - Default 0, integer
     - Incremented on `replan_task`
     - Used in task titles as `gen{N}` to namespace task chains across replans
5. **Expand Cycle Protocol with Task operations** (Synthesis v2 §7.5 + §3):
   - LOAD: include recovery + backfill behavior
   - VALIDATE: ensure active task exists/`in_progress`
   - DECIDE: explicitly “no Task operations”
   - EXECUTE: chain creation and AC tasks creation rules
   - RECORD: completion/failure/escalation transitions
   - REPLY: optional summary line (must not break last-line token contract)
6. **Update AC task dependency model** (Synthesis v2 §7.6 + §4.2 + §5.1):
   - AC tasks are blocked by `implement_task`, **not** `verify_task`
   - `verify_task` completion is orchestrator-gated after AC aggregation (do not rely on Task graph for this)
7. **Add non-fatal degradation rule** (Synthesis v2 §7.7 + Design Principles #2):
   - All Task tool calls are try/catch (non-fatal); on failure/unavailable: log warning and proceed with STATE.yaml-only behavior (zero regression)
8. **Add mechanical gate rule** (Synthesis v2 Design Principles #6):
   - Only perform any Task operations if `CLAUDE_CODE_TASK_LIST_ID` is set and non-empty (and ideally passes the same validation as the launcher).
   - If unset: skip **all** Task operations for the entire session; do not accidentally use a default/global task list.
9. **Add recovery algorithm as binding contract** (Synthesis v2 §6.2):
   - Copy the recovery algorithm steps and both mapping tables into CLAUDE.md in a “mechanical / verbatim” style.
   - Ensure terminology is deterministic: `STATE.task.sub_step` values are the keys; then map to action suffixes as specified.
10. **Update Quick Reference flow diagram** (Synthesis v2 §7.8):
   - Add Task annotations to the cycle flow.
   - Fix the “Task list ID” line to match the new launcher ownership (p1 manages, ralph pass-through).

Constraints while editing CLAUDE.md:
- Keep the document’s existing “binding contract” voice and structure.
- Do not change unrelated sections; only update/add the contract text required by Synthesis v2.

### E) Update `PROMPT_OPTIMIZATION.md` — note Task integration

Add a short, explicit status note that:
- Task Management Integration (Claude Code Tasks) is being integrated into the deadf(ish) pipeline
- Reference the approved spec location: `.pipe/task-integration/synthesis-opus-orchestrator.md` (Synthesis v2)
- Make it clear this is pipeline-level plumbing, not a new prompt in P1–P12 list (unless you confirm otherwise from the file)

Keep the tone consistent with the file (French is acceptable; match existing style).

### F) Update `.gitignore` — add runtime files

Add the exact ignore entries from **Synthesis v2 §10**:

```
.deadf/task_list_id
.deadf/task_list_id.prev
.deadf/task_list_track
```

Do not remove existing ignores; just add these lines in the deadf runtime section.

---

## 4) GUARDRAILS

1. **Do not paste the Synthesis v2 text into your commit messages** (no commits needed). The synthesis is the spec; your job is to implement.
2. **Do not change unrelated behavior** in scripts or CLAUDE.md.
3. **Match CLAUDE.md voice**: mechanical, binding, deterministic.
4. **Bash strictness**: preserve `set -euo pipefail` semantics; avoid introducing unbound-variable crashes.
5. **No task tool regression**: If Task tooling is unavailable or gated off, behavior must match pre-integration behavior.
6. **Line endings**: `.deadf/task_list_id` must be written with `printf '%s'` (no trailing newline), consistent with Synthesis v2.

---

## 5) VERIFICATION (must run)

After changes:

1. Syntax check:
   - `bash -n .pipe/p1/p1-cron-kick.sh`
   - `bash -n ralph.sh`
2. Grep checks (ensure old claims removed):
   - `rg -n \"deadf-\\{run_id\\}\" CLAUDE.md` → must return no matches
   - `rg -n \"ralph\\.sh\\s+sets\\s+`?CLAUDE_CODE_TASK_LIST_ID`?\" CLAUDE.md` → must reflect new ownership wording
3. Template wiring:
   - `rg -n \"\\{TASK_LIST_ID\\}\" .pipe/p1/P1_CYCLE_KICK.md` → must exist
   - `rg -n \"TASK_LIST_ID\" .pipe/p1/p1-cron-kick.sh` → must exist
4. Smoke test (no real Claude required):
   - Create a temp dir with minimal `STATE.yaml` and `POLICY.yaml`, copy `.pipe/p1/p1-cron-kick.sh` + `.pipe/p1/P1_CYCLE_KICK.md`, and run with `P1_CLAUDE_BIN` pointing to a stub script that exits 0.
   - Verify `.deadf/task_list_id` is created and `CLAUDE_CODE_TASK_LIST_ID` is exported (in the stub’s captured env/args).
   - Verify that setting `CLAUDE_CODE_TASK_LIST_ID` externally prevents regeneration (operator override).

Stop if any verification step fails; fix before finalizing.

