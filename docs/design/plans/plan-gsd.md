# P7 Plan: GSD Implementation Prompt for gpt-5.2-codex

> Status: PLAN (not yet implemented)
> Author: prompt-engineering subagent
> Date: 2025-07-25

---

## 1. Design Philosophy

Three governing principles, derived from OpenAI's Codex Prompting Guide and pipeline experience:

1. **No preambles, no planning directives.** Codex has internal reasoning. Asking it to "plan first" causes premature stops and wastes the context window. The TASK packet IS the plan — Codex just executes.

2. **GSD = Do → Verify → Next.** Each logical unit of change gets implemented then validated before moving on. Not "implement everything then test" — that's how you get 14-file OOM disasters.

3. **Scope is sacred.** The ESTIMATED_DIFF budget and FILES list are hard boundaries. Every guardrail exists to prevent the agent from wandering.

---

## 2. Proposed P7 Prompt Structure

The prompt is assembled by the orchestrator (Claude Opus 4.5) from the TASK packet. It has **4 sections** in this exact order:

```
┌─────────────────────────────────────┐
│  SECTION 0: TASK CONTEXT            │  ← Injected verbatim from TASK_{NNN}.md
│  (task ID, title, files, ACs, etc.) │
├─────────────────────────────────────┤
│  SECTION 1: RETRY CONTEXT           │  ← Only present on retry (attempt > 1)
│  (what failed, what to avoid)       │
├─────────────────────────────────────┤
│  SECTION 2: ORIENTATION + OBJECTIVE │  ← The "do this" instructions
│  (read, search, implement, verify)  │
├─────────────────────────────────────┤
│  SECTION 3: GUARDRAILS              │  ← Hard stops, numbered 999+
│  (scope, paths, secrets, commit)    │
└─────────────────────────────────────┘
```

### Why this ordering

- **Context first, instructions second.** Codex performs better when it reads the problem space before receiving directives. Putting TASK CONTEXT at the top lets the model absorb scope, files, and criteria before it encounters any action verbs.
- **Retry context before instructions** so the agent knows what failed before it starts reading "how to implement."
- **Guardrails last** because they're negative constraints — they anchor the tail of the prompt and benefit from recency bias during generation.

---

## 3. Section-by-Section Specification

### SECTION 0: TASK CONTEXT

Injected **verbatim** from the TASK packet. No reformatting, no summarization.

```markdown
# TASK — {TASK_ID}
Attempt: {attempt} of {max_retries + 1}
Track: {track_id} | Task {task_index} of {task_count}

## TITLE
{TITLE}

## SUMMARY
{SUMMARY verbatim from PLAN, plus any P6 adaptation paragraph}

## FILES
{FILES list verbatim — path | action | rationale}

## ACCEPTANCE CRITERIA
{ACCEPTANCE list verbatim — AC1: DET/LLM: ...}

## ESTIMATED_DIFF
{ESTIMATED_DIFF} lines (hard cap: {ESTIMATED_DIFF × 3} lines)

## OPS COMMANDS
{test, lint, build, run commands from OPS.md}

## FILES_TO_LOAD
{ordered list with "why" annotations}
```

**Field mapping from TASK packet:**

| TASK Packet Field | P7 Location | Treatment |
|---|---|---|
| `task_id` | Header + commit msg template | Verbatim |
| `attempt` | Header (attempt N of M) | Computed: `retry_count + 1` |
| `track_id`, `task_index`, `task_count` | Header metadata | Verbatim |
| `TITLE` | Section 0 | Verbatim |
| `SUMMARY` | Section 0 | Verbatim (includes P6 adaptation if any) |
| `FILES` | Section 0 + Guardrail anchor | Verbatim; also referenced in guardrails |
| `ACCEPTANCE` | Section 0 + Orientation self-check | Verbatim |
| `ESTIMATED_DIFF` | Section 0 + Guardrail budget | Verbatim; 3× cap computed |
| `OPS COMMANDS` | Section 0 + Objective verification | Verbatim |
| `FILES_TO_LOAD` | Section 0 + Orientation read list | Verbatim; defines the ONLY files to read |
| `HARD STOPS` | Not injected (already handled by orchestrator before dispatch) | Omitted |
| `DEPENDS_ON` | Not injected (dependency already satisfied by task ordering) | Omitted |

### SECTION 1: RETRY CONTEXT (conditional)

Only present when `attempt > 1`. P6 packages this as an "Adaptations" paragraph appended to SUMMARY, but we also surface it as a dedicated block for clarity:

```markdown
## PREVIOUS ATTEMPT FAILED
Attempt {N-1} failed. Here is what went wrong:
{last_result.details from STATE.yaml — error output, test failures, etc.}

Key guidance:
- {P6's retry-specific instructions, extracted from SUMMARY adaptations}
- Do NOT repeat: {specific anti-pattern from previous failure}
```

**Why a separate section (not just in SUMMARY)?** Codex agents tend to skim long SUMMARY blocks. A visually distinct "PREVIOUS ATTEMPT FAILED" header forces attention. The SUMMARY adaptation paragraph is still there for completeness, but this section is the "you MUST read this" version.

### SECTION 2: ORIENTATION + OBJECTIVE

This is the core instruction set. Lean, imperative, no planning directives.

```markdown
## INSTRUCTIONS

Read all files in FILES_TO_LOAD now (batch them in parallel tool calls).
Then search (rg) for key symbols, types, and function signatures referenced in FILES before writing any code.

Implement the change set described in SUMMARY and FILES.
- Work through FILES in dependency order (imports before consumers).
- After each file change, run the relevant test command from OPS COMMANDS if one covers that file.
- Stay within the {ESTIMATED_DIFF × 3} line budget. If you're approaching the cap, stop and commit what works.

When all changes are complete:
1. Run ALL test commands from OPS COMMANDS.
2. Run ALL lint commands from OPS COMMANDS.
3. Fix any failures. Iterate up to 3 times on test/lint fixes.
4. If tests still fail after 3 fix attempts, commit the best-passing state and note failures in the commit body.
5. Stage changed files individually (never `git add .` or `git add -A`).
6. Commit: `{TASK_ID}: {brief description}`

Do NOT run verify.sh — that runs post-commit by the orchestrator.
```

**What's NOT here (and why):**
- No "first, create a plan" — Codex Prompting Guide explicitly warns against this.
- No "explain your approach" — causes premature stops.
- No "think step by step" — Codex has internal reasoning; external CoT is redundant.
- No `grep` — use `rg`. No `sed` — use `apply_patch` or direct file writes.

### SECTION 3: GUARDRAILS

```markdown
## GUARDRAILS (HARD CONSTRAINTS)

99999. SCOPE: Only modify files listed in FILES. If you discover a necessary change outside FILES, add a TODO comment in the nearest FILES-listed file instead.
999999. BLOCKED PATHS: Never touch .env*, *.pem, *.key, .ssh/, .git/, node_modules/, __pycache__/.
9999999. GIT HYGIENE: No uncommitted files after your commit. No untracked generated files.
99999999. NO SECRETS: No API keys, tokens, passwords, or credentials in code. Ever.
999999999. BUDGET: Total diff must not exceed {ESTIMATED_DIFF × 3} lines. If it would, implement the highest-priority acceptance criteria first and stop.
9999999999. COMMIT FORMAT: `{TASK_ID}: {brief description}` — single commit only.
```

---

## 4. Failure-Prevention Strategies

Based on observed Codex agent failure modes:

### 4.1 Premature Stop (most common)

**Cause:** Prompt asks for planning preamble, explanation, or reasoning output. Model "finishes" the plan and stops before implementing.

**Prevention:**
- Zero planning directives in P7. SUMMARY is the plan, already provided.
- First action verb is "Read" (a tool call), not "Think" or "Plan."
- No "explain your approach" anywhere in the prompt.

### 4.2 Scope Creep / Runaway Diffs

**Cause:** Agent discovers a "better" approach, refactors adjacent code, or fixes unrelated issues.

**Prevention:**
- FILES list is an explicit allowlist, enforced by guardrail 99999.
- ESTIMATED_DIFF × 3 budget is stated twice (Section 0 + Guardrail 999999999).
- "TODO comment" escape valve for necessary out-of-scope changes (prevents the agent from feeling "stuck" and breaking scope anyway).

### 4.3 Test Loop Death Spiral

**Cause:** Agent fails tests, tries to fix, introduces new failures, loops indefinitely.

**Prevention:**
- Hard cap: 3 fix iterations in the prompt.
- "Commit best-passing state" fallback — partial progress is better than infinite loops.
- The orchestrator's retry mechanism (P6 re-packages with failure context) handles deeper issues.

### 4.4 Wrong File / Missing Context

**Cause:** Agent reads files not in FILES_TO_LOAD, gets confused by stale or irrelevant context.

**Prevention:**
- "Read ONLY files in FILES_TO_LOAD" is the first instruction.
- FILES_TO_LOAD is curated by P6 with priority ordering and token cap (≤3000 tokens).
- `rg` search is scoped to symbols in FILES, not exploratory.

### 4.5 Shell Command Errors

**Cause:** Agent uses `grep`, `sed`, `cat` piped chains that break on edge cases.

**Prevention:**
- OPS COMMANDS provides exact commands to run. No improvisation needed.
- Implicit preference for tools over shell (Codex's native mode).

### 4.6 Merge Conflicts / Dirty State

**Cause:** Agent uses `git add .` or leaves untracked files.

**Prevention:**
- "Stage files individually" is explicit in instructions.
- "No uncommitted files after commit" guardrail.
- verify.sh Stage 1 checks git cleanliness post-commit (safety net).

---

## 5. Verification Strategy

### In-Prompt Verification (during Codex execution)

```
Implement file A → run relevant tests → fix if needed
Implement file B → run relevant tests → fix if needed
...
All files done → run ALL tests → run ALL lint
Fix loop (max 3 iterations) → commit
```

**Key principle:** Verify incrementally per-file when possible, then verify holistically. This catches issues early when the fix is local, rather than at the end when the root cause is buried.

### Post-Commit Verification (orchestrator-side)

The orchestrator runs `verify_task` which has 3 stages:
1. **verify.sh** (deterministic: diff size, path safety, secrets scan, git clean, tests pass)
2. **LLM verifier** (for `LLM:` acceptance criteria — semantic checks)
3. **Cross-check** (all ACs covered)

P7 does NOT run verify.sh. This is intentional — verify.sh needs committed state.

### Iteration Limits (end-to-end)

| Level | Limit | Handler |
|---|---|---|
| In-prompt test/lint fix loop | 3 iterations | P7 prompt instruction |
| Task retry (implement again) | `task.max_retries` (from POLICY.yaml, typically 2-3) | Orchestrator via P6 rebinding |
| Stuck detection | `stuck_threshold` from POLICY.yaml | Orchestrator → replan or escalate |

---

## 6. Retry Context Handling

### Flow

```
Attempt 1 fails → orchestrator sets last_result.ok=false
→ orchestrator increments task.retry_count
→ next cycle: generate_task (P6) runs with retry context
→ P6 reads last_result.details, appends retry guidance to SUMMARY
→ P7 receives TASK packet with attempt=2 and RETRY CONTEXT section
```

### What P6 Provides on Retry

- `last_result.details`: raw error output (test failures, lint errors, codex stderr)
- Adaptation paragraph appended to SUMMARY: "Previous attempt failed because X. This time, do Y instead of Z."
- Potentially updated FILES_TO_LOAD (if failure revealed missing context)
- Immutable: ACCEPTANCE criteria, TASK_ID, TITLE

### How P7 Uses Retry Context

1. **SECTION 1 (RETRY CONTEXT)** renders `last_result.details` and P6's retry guidance as a visually distinct block.
2. The SUMMARY already contains P6's adaptation paragraph (belt and suspenders).
3. `attempt` counter in the header lets Codex calibrate — attempt 3 of 3 implies "be conservative, commit partial progress if needed."

### Escalation

If `retry_count >= max_retries`, the orchestrator does NOT dispatch P7 again. Instead:
- If `replan_attempted == false` → replan the task (P5 re-runs for this task)
- If `replan_attempted == true` → escalate to human

P7 never sees this logic. It just implements what it's given.

---

## 7. Orchestrator Interface

### What the Orchestrator Sends

The orchestrator (Claude Opus 4.5) assembles the P7 prompt by:

1. Reading `.deadf/tracks/{track.id}/tasks/TASK_{NNN}.md`
2. Reading `STATE.yaml` for `retry_count`, `last_result`, `max_retries`
3. Templating the 4 sections (Section 1 only if retry)
4. Dispatching via: `codex exec -m gpt-5.2-codex -c 'model_reasoning_effort="high"' --approval-mode full-auto "<assembled prompt>"`

### What the Orchestrator Reads Back

**No LLM parsing.** Results are read deterministically from git:

```bash
exit_code=$?                                    # codex return code
commit_hash=$(git rev-parse HEAD)               # new commit (or same = no progress)
files_changed=$(git diff HEAD~1 --name-only)    # what changed
diff_lines=$(git diff HEAD~1 --stat | tail -1)  # how much changed
commit_msg=$(git log -1 --format='%s')          # sanity check task ID in msg
```

### Success Criteria (for orchestrator)

- `exit_code == 0` AND
- `commit_hash != previous_HEAD` (new commit exists) AND
- `commit_msg` starts with `{TASK_ID}:`

If all true → `task.sub_step: verify` (advance to verify_task).
If any false → `last_result.ok: false`, populate `last_result.details`, `CYCLE_FAIL`.

### What P7 Does NOT Return

- No structured output block or sentinel. The commit IS the output.
- No status messages to parse. The git state IS the status.
- No "DONE" or "FAIL" tokens. Exit code + git diff = deterministic.

---

## 8. Complete Assembled Prompt Template

```markdown
# TASK — {TASK_ID}
Attempt: {attempt} of {max_attempts}
Track: {track_id} | Task {task_index} of {task_count}

## TITLE
{TITLE}

## SUMMARY
{SUMMARY}

## FILES
{FILES list}

## ACCEPTANCE CRITERIA
{ACCEPTANCE list}

## ESTIMATED_DIFF
{ESTIMATED_DIFF} lines (hard cap: {max_diff} lines)

## OPS COMMANDS
{commands}

## FILES_TO_LOAD
{file list with reasons}

{IF attempt > 1:}
## PREVIOUS ATTEMPT FAILED
Attempt {attempt - 1} failed:
{last_result.details}

Do NOT repeat: {extracted anti-pattern}
{END IF}

## INSTRUCTIONS

Read all files in FILES_TO_LOAD now (batch reads in parallel).
Then search (rg) for key symbols and types referenced in FILES before writing code.

Implement the changes described in SUMMARY and FILES.
- Work through FILES in dependency order.
- After each file change, run the relevant test/lint command if one covers that file.
- Stay within the {max_diff} line budget.

When all changes are complete:
1. Run ALL test commands from OPS COMMANDS.
2. Run ALL lint commands from OPS COMMANDS.
3. Fix failures. Iterate up to 3 times on test/lint fixes.
4. If tests still fail after 3 fix attempts, commit the best-passing state and note failures in commit body.
5. Stage changed files individually (never `git add .`).
6. Commit: `{TASK_ID}: {description}`

Do NOT run verify.sh.

## GUARDRAILS

99999. SCOPE: Only modify files in FILES. Out-of-scope needs → add TODO comment.
999999. BLOCKED PATHS: Never touch .env*, *.pem, *.key, .ssh/, .git/.
9999999. GIT HYGIENE: No uncommitted files after commit.
99999999. NO SECRETS in code.
999999999. BUDGET: Diff ≤ {max_diff} lines. Prioritize highest-value ACs if over budget.
9999999999. COMMIT: `{TASK_ID}: {description}` — single commit.
```

---

## 9. Risks and Trade-Offs

### Risk: Prompt is too lean → Codex makes bad decisions

**Mitigation:** The TASK packet (Section 0) carries rich context — SUMMARY is 2-3 sentences of concrete instructions from the planner, FILES has rationales, ACs are testable. The "lean" part is the instructions, not the context.

**Trade-off accepted:** We trust Codex's internal reasoning over external hand-holding. If this fails, the retry loop catches it.

### Risk: 3-iteration fix cap is too low

**Mitigation:** If 3 iterations can't fix it, the issue is likely architectural, not syntactic. P6 retry with failure context is the right escalation path. Raising the cap risks death spirals.

### Risk: "Commit best-passing state" on persistent test failure

This means we might commit code that doesn't fully pass tests. The orchestrator's verify_task will catch it and trigger a retry with the specific failures surfaced.

**Trade-off accepted:** Partial progress in git is better than zero progress. The retry cycle can build on partial work. Zero-commit loops waste budget.

### Risk: FILES_TO_LOAD token cap (3000) may miss critical context

**Mitigation:** P6 curates FILES_TO_LOAD with priority ordering. The `rg` search step in ORIENTATION lets Codex discover adjacent context on-demand. This is "just-in-time" context loading vs. "load everything."

### Risk: No explicit reasoning_effort modulation per task complexity

**Current approach:** Always `high`. The Codex guide suggests `medium` for simple tasks.

**Future optimization:** P5/P6 could tag tasks with complexity hints, and the orchestrator could set `reasoning_effort` accordingly. Not in v1 — uniform `high` is safer.

---

## 10. Implementation Checklist

To build P7 from this plan:

- [ ] Create `P7_IMPLEMENT_TASK.md` template in `.pipe/p7/`
- [ ] Update `implement_task` action in CLAUDE.md to reference P7 template
- [ ] Add template variable substitution logic to orchestrator's implement_task action
- [ ] Add retry context assembly logic (read `last_result.details`, format Section 1)
- [ ] Test with a simple greenfield task (happy path, no retry)
- [ ] Test with intentional failure → retry path
- [ ] Test with scope overflow → budget cap behavior
- [ ] Validate that orchestrator reads results purely from git (no stdout parsing)
