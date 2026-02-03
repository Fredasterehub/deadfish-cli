# P6 (generate_task) — Prompt Design Patterns & Recommended Design (GPT‑5.2 / Codex)

This document analyzes how to design **P6**: the hot-loop phase that takes a **P5 PLAN task entry** and produces a **complete, implementation-ready `TASK.md`** that `gpt-5.2-codex` can execute directly.

## Inputs reviewed (as requested)

- `CLAUDE.md` (deadfish pipeline action specs; `generate_task`, sentinel formats)
- `.pipe/p2-p5-restructure-opus.md` (esp. §9 token budget analysis)
- `.pipe/p5/P5_CREATE_PLAN.md` (PLAN sentinel + TASK entries; P6 input)
- Conductor:
  - The paths `/tank/dump/DEV/prompt-research/conductor/newTrack.md`, `implement.md`, `workflow.md` do **not** exist in this checkout.
  - Used nearest equivalents:
    - `/tank/dump/DEV/prompt-research/conductor/commands/conductor/newTrack.toml`
    - `/tank/dump/DEV/prompt-research/conductor/commands/conductor/implement.toml`
    - `/tank/dump/DEV/prompt-research/conductor/templates/workflow.md`
    - `/tank/dump/DEV/prompt-research/conductor/README.md`
- GSD:
  - `/tank/dump/DEV/prompt-research/gsd/get-shit-done/templates/project.md`
  - `/tank/dump/DEV/prompt-research/gsd/get-shit-done/templates/requirements.md`
  - `/tank/dump/DEV/prompt-research/gsd/get-shit-done/templates/state.md`

---

## Conductor patterns relevant to P6

### 1) “Context as artifacts” + minimal, stable core context
Conductor’s core move is to externalize context into **small, named, stable docs** (product, tech stack, workflow) that are consistently loaded before planning/execution. That yields predictable behavior and reduces “prompt drift.”

P6 translation:
- Treat `TASK.md` as a **context artifact**: it should be the single “what to do next” document that an implementation agent can run without re-reading large strategic docs.
- Put only **the minimum stable invariants** in the hot loop (P6/P7): commands, constraints, scope rules, and just enough code context to implement safely.

### 2) “Plan is the source of truth” → prefer mechanical task derivation
Conductor’s workflow explicitly treats `plan.md` as the source of truth, and the implementer iterates tasks sequentially.

P6 translation:
- P5 already produces “plans-as-prompts” `SUMMARY` blocks. P6 should **not** re-plan; it should **materialize** the next task into `TASK.md` deterministically.
- Use GPT in P6 only when there’s a known gap a deterministic transform can’t cover (e.g., ambiguous file selection or retry recovery).

### 3) Workflow-driven execution readiness
Conductor makes “how to execute” explicit via a workflow template: TDD flow, quality gates, commit expectations, etc.

P6 translation:
- Embed (or reference) the project’s **OPS** commands and execution rules in `TASK.md` so `gpt-5.2-codex` has zero ambiguity about how to validate locally.
- Keep workflow content **compressed**: for P6, you want “commands + constraints,” not a full process manifesto.

### 4) Dependency awareness via “resolved context” (file resolution protocol)
Conductor’s Universal File Resolution Protocol is essentially: “resolve canonical paths; verify existence; halt if missing.”

P6 translation:
- Treat missing/mismatched inputs as a **hard error**:
  - If plan references a `modify/delete` path that doesn’t exist → task generation should fail fast (or force a re-plan) rather than letting Codex thrash.
- Encode “expected existence” and “actions” explicitly in `TASK.md` to avoid silent scope creep.

### 5) Token-awareness as a first-class concern
Conductor’s README explicitly warns about token consumption. The workflow also implicitly prefers automation and avoids interactive loops.

P6 translation:
- P6 should be **budget-governed** (file selection and snippet selection), not “load everything that might help.”
- When in doubt, prefer:
  - smaller files,
  - fewer files,
  - targeted excerpts/snippets (if the pipeline supports it),
  - deterministic rg-driven selection.

---

## GSD patterns relevant to P6

### 1) “Core value” + “constraints” as execution-time guardrails (not planning fluff)
GSD’s `PROJECT.md` template centers “Core Value,” “Constraints,” and “Key Decisions.” Importantly: it’s meant to be **kept short** and consulted to resolve tradeoffs.

P6 translation:
- P6 should carry forward only the **constraints that affect implementation choices** (e.g., “no new deps,” “must remain CLI-compatible,” “keep diff small,” “tests required”).
- Don’t reload full strategic docs in the hot loop; instead, inject a compact “constraints excerpt” into `TASK.md` (or link to it but do not assume Codex will open it).

### 2) Execution readiness via checkable requirements
GSD’s `REQUIREMENTS.md` emphasizes “user-centric, testable, atomic,” plus traceability.

P6 translation:
- Convert the plan task’s acceptance criteria into a **ready-to-check checklist** with clear pass/fail.
- Preserve the DET vs LLM split (already used by deadfish) and make it obvious which criteria are “verify.sh covered” vs “reasoning/judgement.”

### 3) State as “living memory” and “resume point”
GSD’s `STATE.md` template exists to enable instant resumption, including “Stopped at / resume file / blockers.”

P6 translation:
- On retries or “stuck” cycles, P6 should write a small “Retry context” section:
  - what failed last time,
  - what evidence exists (test output summary),
  - what to avoid repeating,
  - what the next attempt should change.

### 4) Plans-as-prompts (the key to minimizing P6)
GSD’s philosophy strongly aligns with deadfish’s P5 rule: the plan task is itself the implementer’s prompt.

P6 translation:
- P6 should primarily do:
  1) selection of the next PLAN task,
  2) scope/budget packaging,
  3) retry-aware adjustments.
  Everything else is already “in the plan.”

---

## Synthesis: recommended P6 design

### High-level answer to the analysis questions

1) **Conductor’s task generation to adopt**
- Treat plan artifacts as canonical; task generation should be mostly deterministic.
- Make file existence and scope explicit; fail fast on invalid plan references.
- Carry only small stable “workflow/commands/constraints” into the execution context.
- Budget-aware file selection, not “read the repo.”

2) **GSD’s task sizing / execution readiness to adopt**
- Atomic, checkable criteria; avoid vague verbs.
- Strong separation of “strategic docs” (rarely loaded) vs “execution packet” (hot loop).
- Explicit deviation rules: if reality conflicts with plan/constraints, stop and re-plan rather than drifting.

3) **How P6 transforms PLAN TASK entry → TASK.md (what’s added vs passed through)**

Pass through (verbatim or near-verbatim):
- `TASK_ID`, `TITLE`
- `SUMMARY` (because P5 already writes it as an implementation prompt)
- `FILES` (path/action/rationale)
- `ACCEPTANCE` (DET/LLM)
- `ESTIMATED_DIFF` and derived `MAX_DIFF = 3x`
- `DEPENDS_ON` (to allow contextual linking to prior tasks)

Add in P6 (execution packaging):
- **Scope contract**: allowed changes, forbidden paths, “do not edit outside FILES unless…”
- **Commands**: test/lint/build commands from `OPS.md` (or defaults), plus “how to run quickly” vs “full suite”
- **File loading plan**: ordered `task.files_to_load` with rationale and budget notes
- **Dependency context**: “what prior tasks guarantee” (short) if `DEPENDS_ON` is non-empty
- **Retry context** (conditional): last failure summary + targeted “what to do differently”
- **Ambiguity resolution hints**: pointers to where relevant patterns live (e.g., “follow existing CLI option parsing style in X”)

4) **What context should P6 load (3000-token budget for `task.files_to_load`)**

Recommended approach: treat `task.files_to_load` as a **curated pack**, not “all touched files.”

Selection priorities (descending):
1. Every file in plan `FILES` with `action=modify|delete`
2. The nearest existing “integration points” for `action=add` (e.g., module index, CLI entrypoint, router registry)
3. The most relevant tests for the touched code (existing test file in same area, or the test runner config)
4. Small config files that constrain behavior (e.g., `pyproject.toml`, `package.json`, `ruff.toml`, CLI config)
5. Small style/convention anchors (one file showing patterns), only if missing otherwise

Hard rule:
- Do not exceed the 3000-token pack; if you must choose, prefer the files that constrain correctness most (entrypoints + tests).

5) **Should P6 use GPT‑5.2 or be mostly mechanical?**

Default: **mostly mechanical**.
- Deterministic transform avoids token spend and removes a failure mode (LLM emits malformed task specs in the hot loop).
- GPT use is justified only for:
  - context pack selection when heuristics are uncertain,
  - large/complex tasks where “what to load” isn’t obvious,
  - retry recovery where “what failed” must be interpreted into next actions.

Practical design: “mechanical-first, LLM-assisted fallback”
- Try mechanical selection and packaging first.
- If constraints violated (missing files, budget overflow, stuck/retry escalation), run a small GPT call to produce an adjusted pack and/or clarified execution notes.

6) **How P6 handles retry context (`last_result.ok == false`, `stuck_count > 0`)**

Key design principle: retries are about **delta guidance**, not restating the whole task.

On retry-aware generation:
- Include a short section:
  - “Previous attempt summary” (1–3 bullets),
  - “Observed failure” (test/lint error excerpt or verify summary),
  - “Required change in approach” (explicit),
  - “Do not repeat” (what not to do again).
- Adjust `task.files_to_load` toward the failure:
  - If tests failed: add the failing test file(s) and the implementation file under test.
  - If lint/type failed: add the config file and the failing file(s).
  - If out-of-scope edits occurred: explicitly restate scope and include the diffstat evidence in the retry context (so Codex can self-correct).

7) **Sentinel format for TASK.md vs structured markdown**

Recommendation: **structured markdown, no sentinel required**.
- `TASK.md` is a local artifact consumed by Codex; it does not need LLM-to-script parsing.
- Keep parsing burden out of the hot loop unless you have a concrete need.

If you want machine-readability for debugging/telemetry, prefer a tiny top-of-file metadata block:
- `---` YAML frontmatter (easy to parse, common)
- or a minimal `TASK_META` fenced YAML

Avoid making the entire file a sentinel DSL block unless another script needs to parse it.

8) **Ensuring `TASK.md` is self-contained for Codex**

The implementer should not need to:
- open PLAN.md,
- infer scope boundaries,
- guess commands,
- reconstruct acceptance criteria,
- guess what files matter.

Therefore `TASK.md` must include:
- prompt-like `SUMMARY` (imperative),
- explicit list of planned file operations,
- explicit criteria checklist,
- explicit commands to run,
- explicit “file pack” to load,
- explicit “don’t touch” constraints,
- explicit diff budget and escalation rule (“if needs more than 3x estimate, stop and re-plan”).

---

## Token budget analysis

From `.pipe/p2-p5-restructure-opus.md` §9:
- P6/P7 are in the hot loop and target roughly:
  - `STATE.yaml` (~250 tokens)
  - `PLAN.md` current task (~200 tokens) or `TASK.md` (~200 tokens)
  - `OPS.md` (~300 tokens)
  - `task.files_to_load` (≤3000 tokens)
  - plus prompt scaffolding overhead

### Implications for P6

1) **File pack must be intentional**
The 3000-token limit is the scarce resource. P6’s job is to ensure Codex sees:
- the files it must change,
- the files that constrain correctness (tests/entrypoints/config),
without blowing the budget.

2) **Prefer “one-hop” dependency context**
If you expand beyond planned FILES, do it in one hop:
- entrypoint + closest test + closest config
and stop.

3) **Budget overflow handling must be deterministic**
If planned FILES are already too large:
- pick a subset of large files to load (e.g., entrypoint + test) and add “snippets” for the rest,
- or trigger a re-plan that splits the task.

4) **Avoid loading strategic docs**
Loading `PROJECT.md` / `REQUIREMENTS.md` in the hot loop is almost always wasted tokens. If constraints are needed, P6 should summarize them into `TASK.md`.

---

## Retry/error handling design

### Retry modes P6 should support

1) **Simple retry** (same plan/task, previous attempt failed)
- Do not change scope unless the failure proves scope was wrong.
- Add failure context and adjust file pack toward the failing area.

2) **Stuck recovery** (`stuck_count` rising)
- Add a “stuck diagnosis” section: what was tried, why it failed, what new evidence is required.
- Tighten acceptance criteria interpretation (e.g., clarify expected CLI output format).
- Expand file pack slightly (one additional anchor file) to break ambiguity.

3) **Re-plan trigger** (policy threshold hit; P6 re-enters generation)
- Regenerate `TASK.md` from the same PLAN entry but with:
  - stricter scope rules,
  - smaller diff target (or split suggestion),
  - updated file pack,
  - explicit “stop condition.”

### Deterministic stop conditions (to prevent hot-loop thrash)

P6 should explicitly encode these in `TASK.md`:
- If implementing requires touching a file outside `FILES` in a non-trivial way → stop and request re-plan.
- If expected diff would exceed `3 * ESTIMATED_DIFF` → stop and request split.
- If plan references missing `modify/delete` paths → stop and request plan repair.

---

## Proposed TASK.md format

Recommended: structured markdown + tiny YAML frontmatter (optional).

```markdown
---
task_id: "<TASK_ID>"
track_id: "<TRACK_ID>"
depends_on: ["<TASK_ID>", "..."]
estimated_diff: <N>
max_diff: <3N>
files_budget_tokens: 3000
---

# <TASK_ID>: <TITLE>

## Objective
<P5 SUMMARY, verbatim (2–3 sentences).>

## Scope
- Planned file operations:
  - `<path>` (<action>): <rationale>
- Do not modify files outside the planned list unless required for a trivial integration (imports/wiring only).
- Blocked paths: `.env*`, `*.pem`, `*.key`, `.ssh/`, `.git/`

## Acceptance Criteria
### Deterministic (verify.sh covered)
- AC1: ...
- AC2: ...

### LLM-judged (must be true in the codebase)
- AC3: ...
- AC4: ...

## Commands
- Tests: `<from OPS.md>`
- Lint: `<from OPS.md>`
- Other: `<build/typecheck/etc from OPS.md>`

## Context Pack (≤3000 tokens total)
- `<path>` — why it matters / what to look for
- `<path>` — ...

## Retry Context (only if last_result.ok == false or stuck_count > 0)
- Observed failure: <short excerpt>
- What to change this attempt: <explicit delta>
- What not to repeat: <explicit>
```

Notes:
- The “Context Pack” section should match `task.files_to_load` exactly (same ordering), so humans and automation can compare easily.
- If you do not want YAML frontmatter, drop it; the headings alone are sufficient for Codex.

---

## Proposed P6 prompt template outline

If P6 remains mechanical-first, the “prompt” is mostly relevant for the *fallback* GPT call (when heuristics can’t pick a good `files_to_load` pack or when retry recovery needs interpretation).

### P6 (fallback) layered prompt

--- ORIENTATION (0a–0d) ---
0a. Read `STATE.yaml`: track/task position, `last_result`, `loop.stuck_count`, nonce/cycle.
0b. Read `.deadf/tracks/{track.id}/PLAN.md`: extract TASK[{task_current}] entry.
0c. Read `OPS.md` (if present) for commands and constraints.
0d. (Optional, fast) Run `rg` for the task’s key symbols and list the top 10 matching files (paths only).

--- OBJECTIVE (1) ---
1. Produce an implementation-ready `TASK.md` for TASK[{task_current}], including a `task.files_to_load` list that fits the 3000-token budget.

--- OUTPUT FORMAT (2) ---
- Output a single markdown document (no sentinel), with sections:
  - Objective, Scope, Acceptance, Commands, Context Pack, Retry Context
- `Context Pack` must be an ordered list of paths (and may include brief rationales).

--- RULES (3) ---
- Preserve `SUMMARY`, `FILES`, `ACCEPTANCE`, `ESTIMATED_DIFF`, `DEPENDS_ON` from the plan task.
- Only add clarifying constraints and retry deltas; do not expand scope.
- Prefer ≤5 files in the context pack unless failure evidence requires more.
- If pack would exceed budget, prioritize: entrypoint → tests → config → implementation files.

--- GUARDRAILS (999+) ---
99999. If any planned `modify/delete` file is missing, output “REPLAN_REQUIRED: missing file <path>” and stop.
999999. Do not hallucinate file paths. Only choose paths that exist.
9999999. Do not rewrite the plan; only package it for execution.

### Why this template is token-efficient
- It delegates most work to deterministic transformation.
- It uses GPT only where judgement is needed (file selection / retry interpretation).
- It avoids reloading strategic docs and avoids multi-round planning in the hot loop.

