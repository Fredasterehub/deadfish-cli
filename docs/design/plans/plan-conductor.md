# P7 `implement_task` — Conductor Plan

> The TASK packet is a fully-bound work order. P7 is the worker prompt that receives it, executes, and returns a deterministic result. This plan specifies what P7 should look like, why each choice was made, and how it interfaces with the orchestrator.

---

## 1. Proposed P7 Prompt Structure

The prompt is assembled by the orchestrator at dispatch time. It is NOT a static template — it's a **runtime-composed prompt** built from TASK packet fields + injected context.

### Section Order (critical — based on Codex research)

```
┌─────────────────────────────────────────────────┐
│  SECTION A: IDENTITY + MODE                     │  ← 2 lines. Sets autonomy expectations.
│  SECTION B: TASK PACKET (verbatim injection)    │  ← The entire TASK_{NNN}.md content.
│  SECTION C: DIRECTIVES                          │  ← 5-7 imperative lines. The "do" list.
│  SECTION D: HARD GUARDRAILS                     │  ← 4-5 lines. The "never" list.
│  SECTION E: COMMIT CONTRACT                     │  ← 2 lines. What constitutes "done."
└─────────────────────────────────────────────────┘
```

**Why this order:**
- **No preamble/planning section.** Research finding #1: prompting for upfront plans causes premature stops. Codex already has internal planning (#2). We skip straight to context.
- **TASK packet first** (Section B) because Codex processes tokens sequentially. Give it the work order before telling it what to do — it reads the full context, then the short directives anchor behavior.
- **Directives after context** because they act as recency-biased behavioral anchors.
- **Guardrails last** because Codex treats late-prompt constraints as high-priority (system prompt effect).

### Section A: Identity + Mode (~30 tokens)

```
You are gpt-5.2-codex implementing a single task in the deadfish pipeline.
Work autonomously. Do not ask questions. Do not explain your plan.
```

**Why lean:** Research finding #4 — autonomy + persistence is default. Codex doesn't need hand-holding. Two lines set the frame without wasting tokens on role-play.

### Section B: TASK Packet (variable, ~800-2000 tokens)

The entire TASK_{NNN}.md file content, injected verbatim. No reformatting, no summarizing. This includes:

- TASK_ID, TITLE, SUMMARY
- FILES (with actions)
- ACCEPTANCE criteria
- ESTIMATED_DIFF + max_diff
- DEPENDS_ON
- OPS COMMANDS
- FILES_TO_LOAD (ordered, capped)
- HARD STOPS / SIGNALS

**Why verbatim injection:** The TASK packet was already compiled by P6 with resolved paths, prioritized context, and capped token budgets. Re-processing it would be redundant work. Inject as-is.

### Section C: Directives (~100 tokens)

```
DIRECTIVES:
1. Read ALL files in FILES_TO_LOAD first (batch them in one pass).
2. Search (rg) for symbols/types referenced in SUMMARY before writing code.
3. Implement the smallest change set satisfying every ACCEPTANCE criterion.
4. Stay within max_diff lines changed.
5. Run the OPS COMMANDS (test + lint) before committing. Fix failures.
6. Commit with message: "{TASK_ID}: {TITLE}"
```

**Why 6 lines:** Each directive maps to a concrete Codex action. No ambiguity, no "consider" language. Research finding #7 (verification loops) is captured in directive 5. Research finding #8 (scope anchoring) is captured in directives 3-4.

**Why "batch them in one pass":** Research finding #3 — parallel tool calls. Codex can batch file reads when instructed. This is a direct perf lever; reading 5 files sequentially vs. in parallel is measurably different at scale.

### Section D: Hard Guardrails (~80 tokens)

```
NEVER:
- Touch files outside the FILES list.
- Modify blocked paths (.env*, *.pem, *.key, .ssh/, .git/).
- Leave uncommitted files after your commit.
- Put secrets in code.
- Run ./verify.sh (the orchestrator runs it post-commit).
```

**Why separate from directives:** Positive directives ("do X") and negative constraints ("never Y") are cognitively distinct. Separating them prevents the "never" items from diluting the "do" items.

**What's NOT here (by design):**
- No "don't explore beyond scope" — Codex's file sandboxing + the FILES list is sufficient. Over-constraining exploration harms Codex's ability to discover integration points.
- No "don't use grep" — we trust Codex to pick its preferred tools (finding #6 says it prefers rg natively).

### Section E: Commit Contract (~30 tokens)

```
DONE = tests pass + lint passes + one clean commit + no uncommitted files.
If you cannot satisfy all ACCEPTANCE criteria, commit what works and note what's missing in the commit message body.
```

**Why explicit "done" definition:** Codex needs a termination signal. Without it, it may over-iterate or stop prematurely. The second line handles partial completion gracefully — better a partial commit the orchestrator can evaluate than a hung session.

---

## 2. TASK Packet Field Mapping

| TASK Packet Field | Where in P7 | How Used |
|---|---|---|
| `TASK_ID` | Section B (verbatim), Section C directive 6 | Commit message prefix |
| `TITLE` | Section B (verbatim), Section C directive 6 | Commit message suffix |
| `SUMMARY` | Section B (verbatim) | Primary implementation instruction — this IS the prompt |
| `FILES` | Section B (verbatim), Section D guardrail 1 | Scope boundary for writes |
| `ACCEPTANCE` | Section B (verbatim), Section C directive 3 | Success criteria — what "done" means |
| `ESTIMATED_DIFF` / `max_diff` | Section B (verbatim), Section C directive 4 | Size constraint |
| `DEPENDS_ON` | Section B (verbatim) | Informational only — dependencies already resolved by pipeline |
| `OPS COMMANDS` | Section B (verbatim), Section C directive 5 | Test/lint/build commands to run |
| `FILES_TO_LOAD` | Section B (verbatim), Section C directive 1 | Initial read list — parallel batch |
| `HARD STOPS / SIGNALS` | Section B (verbatim) | Informational — orchestrator already validated these |

**Key insight:** SUMMARY is the de facto implementation prompt. P5 designs it as "imperative, directly executable by gpt-5.2-codex." P7 wraps it with context (files, criteria) and behavioral anchors (directives, guardrails) but does NOT rewrite it.

---

## 3. Codex-Native Optimizations

### 3a. No Planning Preamble

**Current spec has:** "0a. Read TASK.md. Restate acceptance criteria."

**P7 removes this.** Restating criteria is a planning preamble. Research finding #1: this causes premature stops. The criteria are already in the injected TASK packet. Codex will reference them naturally.

### 3b. Parallel Batch Reads

**Current spec has:** "0b. Read ONLY the files listed in task.files_to_load."

**P7 changes to:** "Read ALL files in FILES_TO_LOAD first (batch them in one pass)."

The word "batch" is the trigger. Codex's parallel tool call system responds to this framing. In practice this means Codex will issue multiple `file_read` tool calls in a single turn rather than sequential turns.

### 3c. rg Over grep, apply_patch Over sed

Not explicitly stated (Codex defaults to these per finding #6), but the DIRECTIVES use `rg` in directive 2 to reinforce the preferred tool. No mention of grep/sed anywhere in P7.

### 3d. Reasoning Effort: High

The orchestrator dispatches with `model_reasoning_effort="high"`. This is set at the `codex exec` level, not in the prompt. For standard implementation tasks, "high" is correct (finding #5). The orchestrator could escalate to "xhigh" for retry attempts — this is a dispatch-time decision, not a prompt-time one.

### 3e. Lean Directive Style

Total prompt overhead (excluding TASK packet): ~240 tokens. The TASK packet itself is 800-2000 tokens (capped by P6's 3000-token FILES_TO_LOAD budget + structural overhead). Total prompt: **~1000-2200 tokens**.

Compare to the current spec which would expand to ~400+ tokens of directives alone. Every token of instruction is a token not spent on context.

### 3f. No "Read TASK.md" Step

The current spec says "0a. Read TASK.md." But in P7, the TASK content is injected directly into the prompt. Codex doesn't need to read a file — the content is already in its context window. This saves one tool call and eliminates a potential failure point (wrong path, missing file).

---

## 4. Guardrail Strategy

### What P7 Enforces (in-prompt)

| Guardrail | Enforcement | Why In-Prompt |
|---|---|---|
| FILES scope | NEVER list + FILES boundary | Codex respects explicit scope constraints well |
| Blocked paths | NEVER list | Critical safety — must be in prompt |
| Git cleanliness | DONE contract | Codex needs to know what "finished" means |
| No secrets | NEVER list | Critical safety — must be in prompt |
| No verify.sh | NEVER list | Prevents premature verification that breaks orchestrator flow |
| Commit format | Directive 6 | Must match for orchestrator parsing |

### What P7 Leaves to Codex's Defaults

| Behavior | Why Not Enforced |
|---|---|
| Tool selection (rg vs grep) | Codex prefers better tools natively (finding #6) |
| Implementation approach | Internal planning is sufficient (finding #2) |
| Error handling patterns | Project-specific; SUMMARY should cover if needed |
| Test writing style | ACCEPTANCE criteria define what, not how |
| Code style/formatting | Lint in OPS COMMANDS catches deviations |

### What the Orchestrator Enforces Post-Hoc (NOT in P7)

| Check | Enforced By |
|---|---|
| Diff within 3× ESTIMATED_DIFF | verify.sh |
| Tests pass | verify.sh |
| Lint passes | verify.sh |
| No blocked paths modified | verify.sh |
| No secrets detected | verify.sh |
| Git tree clean | verify.sh |
| Acceptance criteria met | LLM verifier sub-agents |

**Trade-off:** P7 states the constraints so Codex aims for them, but verification is the orchestrator's job. Double-enforcement (prompt + post-hoc) is intentional for critical constraints. This means Codex self-corrects during implementation, AND the orchestrator catches anything that slips through.

---

## 5. Orchestrator Interface

### What the Orchestrator Sends

```bash
codex exec \
  -m gpt-5.2-codex \
  -c 'model_reasoning_effort="high"' \
  --approval-mode full-auto \
  "<assembled P7 prompt>"
```

The prompt is assembled by string concatenation:

```python
prompt = f"""{SECTION_A}

{task_packet_content}

{SECTION_C}

{SECTION_D}

{SECTION_E}"""
```

Where `task_packet_content` = contents of `.deadf/tracks/{track.id}/tasks/TASK_{NNN}.md`.

### What the Orchestrator Reads Back

**No prompt-level output format.** The orchestrator reads results from git, not from Codex's stdout:

| Signal | How Detected | Source |
|---|---|---|
| Success | `exit_code == 0` AND new commit at HEAD | `codex` return code + `git rev-parse HEAD` |
| Failure | `exit_code != 0` OR no new commit | `codex` return code + `git log -1` |
| Files changed | `git diff HEAD~1 --name-only` | git |
| Diff size | `git diff HEAD~1 --stat` | git |
| Commit message | `git log -1 --format=%B` | git |

**Why no stdout parsing:** Deterministic > heuristic. Git state is ground truth. Parsing Codex's natural language output would require another LLM call or fragile regex. The current architecture (git-as-IPC) is elegant and reliable.

### Retry Interface

On retry (`task.retry_count > 0`), P6 regenerates the TASK packet with retry context appended to SUMMARY. P7 doesn't change — it still uses the same 5-section structure. The retry intelligence lives in the TASK packet, not in P7.

This means P7 is **stateless** — it doesn't know or care if this is attempt 1 or attempt 3. The TASK packet carries all necessary context. This is the Conductor model: the work order is complete, the worker is interchangeable.

### Reasoning Effort Escalation

| Attempt | Reasoning Effort | Rationale |
|---|---|---|
| 1st attempt | `high` | Standard implementation |
| 2nd attempt | `high` | Same complexity, different approach |
| 3rd attempt | `xhigh` | Last chance — maximum reasoning |

This is a **dispatch-time** decision by the orchestrator, not a prompt-time one. P7 is identical across attempts.

---

## 6. Risks and Trade-Offs

### Risk 1: No Criteria Restatement → Misalignment

**Current spec:** "Restate acceptance criteria in one sentence each (self-check)."
**P7:** Removes this.

**Risk:** Codex might not internalize all criteria, especially if the TASK packet is long.
**Mitigation:** Research finding #1 is definitive — preamble planning causes premature stops. The criteria are in the prompt and Codex's attention mechanism handles them. If criteria are missed, the verifier catches it and triggers retry with explicit failure context.
**Acceptable because:** The verification loop (verify.sh + LLM verifier) is the safety net. One extra retry is cheaper than systematic premature stops.

### Risk 2: Lean Prompt → Under-Specified Edge Cases

**Risk:** 240 tokens of directives can't cover every edge case (e.g., "what if a dependency is missing at runtime").
**Mitigation:** SUMMARY (written by P5/P6) should cover project-specific edge cases. OPS COMMANDS cover build/test specifics. P7's job is behavioral framing, not domain knowledge.
**Acceptable because:** The TASK packet carries domain specifics. P7 carries behavioral constraints. Separation of concerns.

### Risk 3: "Batch reads" Instruction May Be Ignored

**Risk:** Codex might still issue sequential reads despite the "batch" instruction.
**Mitigation:** This is a performance optimization, not a correctness requirement. If Codex reads sequentially, it's slower but still correct. Future Codex versions may handle this better.
**Trade-off:** Low risk, moderate upside.

### Risk 4: Partial Commit Escape Hatch

**P7 says:** "If you cannot satisfy all ACCEPTANCE criteria, commit what works."
**Risk:** Codex might commit incomplete work too readily.
**Mitigation:** The verifier will catch incomplete implementations and trigger retry. The alternative (no escape hatch) risks Codex hanging indefinitely trying to satisfy impossible criteria.
**Acceptable because:** A partial commit gives the orchestrator something to analyze. A hung session gives nothing.

### Risk 5: FILES Scope Is Advisory

**Risk:** Despite the NEVER guardrail, Codex might still modify files outside the FILES list (e.g., to fix an import it discovers is broken).
**Mitigation:** verify.sh checks path compliance post-hoc. The LLM verifier also checks for out-of-scope modifications. Double enforcement.
**Trade-off:** Allowing Codex some flexibility here can be beneficial (e.g., adding a missing `__init__.py`). Strict enforcement is at the verifier level, not the prompt level.

---

## 7. Complete Assembled Prompt (Reference)

```
You are gpt-5.2-codex implementing a single task in the deadfish pipeline.
Work autonomously. Do not ask questions. Do not explain your plan.

---

{TASK_PACKET_CONTENT — verbatim from TASK_{NNN}.md}

---

DIRECTIVES:
1. Read ALL files in FILES_TO_LOAD first (batch them in one pass).
2. Search (rg) for symbols/types referenced in SUMMARY before writing code.
3. Implement the smallest change set satisfying every ACCEPTANCE criterion.
4. Stay within max_diff lines changed.
5. Run the OPS COMMANDS (test + lint) before committing. Fix failures.
6. Commit with message: "{TASK_ID}: {TITLE}"

NEVER:
- Touch files outside the FILES list.
- Modify blocked paths (.env*, *.pem, *.key, .ssh/, .git/).
- Leave uncommitted files after your commit.
- Put secrets in code.
- Run ./verify.sh (the orchestrator runs it post-commit).

DONE = tests pass + lint passes + one clean commit + no uncommitted files.
If you cannot satisfy all ACCEPTANCE criteria, commit what works and note what's missing in the commit message body.
```

Total static overhead: **~180 tokens**. Total with typical TASK packet: **~1000-2000 tokens**. Leaves maximum context window for Codex's internal reasoning and tool calls.

---

## 8. Implementation Checklist

To build P7 into the pipeline:

- [ ] **Template file:** Create `.pipe/p7/P7_IMPLEMENT_TASK.md` with the reference prompt (Section 7), using `{TASK_PACKET_CONTENT}` and `{TASK_ID}` / `{TITLE}` as template variables
- [ ] **Orchestrator assembly:** Update `implement_task` action in CLAUDE.md to: (a) read TASK_{NNN}.md, (b) substitute into template, (c) dispatch via `codex exec`
- [ ] **Reasoning escalation:** Add logic to set `model_reasoning_effort` based on `task.retry_count` (1-2: high, 3: xhigh)
- [ ] **CLAUDE.md update:** Replace current implement_task prompt spec with reference to P7 template
- [ ] **Test with dry run:** Assemble a sample prompt with a real TASK packet and review before live execution
