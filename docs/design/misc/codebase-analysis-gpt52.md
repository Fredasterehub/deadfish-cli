# deadfish-cli pipeline — codebase analysis (GPT‑5.2)

Date: 2026-02-02  
Scope: repo-local review of the deadf(ish) CLI pipeline implementation + its “binding contract” (`CLAUDE.md`).  
Audience: architect-level critique (unfiltered).

## Executive Summary (blunt)

This repo is a **spec-heavy, tooling-light** port: most of the “system” lives as an LLM protocol in `CLAUDE.md`, while the actual code implements **only the outer shell** (kick/loop + verifier + two parsers). That can be a valid strategy, but **the current implementation is internally inconsistent** in multiple critical places (contract ↔ templates ↔ scripts), which means the pipeline as described will **not run end-to-end** without substantial reconciliation.

The strongest idea here is the **deterministic envelope** around inherently stochastic agents: strict sentinel grammars, nonces per cycle, atomic state writes with locks, and conservative verification. The weakest reality is **contract drift**: several core contracts referenced by the orchestrator are not implemented by the shipped tools (or contradict them), so the “determinism” collapses at integration time.

---

# 1. Architecture Understanding

## 1.1 End-to-end trace (Kick → … → `CYCLE_OK`)

There are *two* “kick” paths in this repo:

### Path A: cron launcher (`.pipe/p1/p1-cron-kick.sh`) → `claude` CLI

1. **Process lock**: acquires `.deadf/cron.lock` with non-blocking `flock`. If locked, exits with code 10 (“skip: lock held”).
2. **Reads state** (via `yq`): `.cycle.status`, `.phase`, `.cycle.started_at`.  
   - If `.cycle.status == running`, it checks age; if too old, it **forces** `.cycle.status=timed_out` and `.phase=needs_human` under `STATE.yaml.flock`, then exits 14.
   - If `.phase == needs_human`, exits 11.
   - If `.phase == complete`, exits 12.
3. **Cycle ID**: generates `CYCLE_ID="cycle-${iteration+1}-${8hex}"`.
4. **Task list ID** (Claude Code Tasks feature):
   - Manages `.deadf/task_list_id` and rotates it on track change or age (default 7 days).
   - Exports `CLAUDE_CODE_TASK_LIST_ID` (unless already set in env).
5. **Kick message assembly**: parses `.pipe/p1/P1_CYCLE_KICK.md` ` ```text ` block and substitutes variables (project path, mode, task list id, etc.).
6. **Spawn orchestrator**: runs:
   - `claude --print --allowedTools "Read,Write,Edit,Bash,Task,Glob,Grep" "$kick_message"`
   - stdout+stderr are tee’d to `.deadf/logs/cycle-${CYCLE_ID}.log`
7. **Completion**: launcher checks `claude` exit code only. It does **not** parse the final token; it relies on the orchestrator having updated `STATE.yaml`.

### Path B: loop controller (`ralph.sh`) → external dispatch command (`RALPH_DISPATCH_CMD`)

1. **Single-instance lock**: acquires `.deadf/ralph.lock` for the lifetime of Ralph.
2. **Poll loop**:
   - Validates `STATE.yaml` schema *lightly* (`phase` in {research, select-track, execute, complete, needs_human}; `cycle.status` in {idle, running, complete, failed, timed_out}).
   - Exits if `phase` is `complete` or `needs_human`.
   - Enforces `loop.max_iterations` (default 200) — note: this is in `STATE.yaml`, not `POLICY.yaml`.
3. **Timeout watch**:
   - If it sees `cycle.status == running` for longer than `RALPH_TIMEOUT`, it sets `cycle.status=timed_out` and `phase=needs_human` under `STATE.yaml.flock`.
4. **P2 bootstrap** (opinionated):
   - If `phase == research` and `.deadf/seed/P2_DONE` missing, it runs `.pipe/p12-init.sh --project "$PROJECT_PATH"`.
5. **Task list passthrough** (partial):
   - If `.deadf/task_list_id` exists, exports `CLAUDE_CODE_TASK_LIST_ID` from it.
6. **Kick**:
   - Generates a UUID-ish `CYCLE_ID`.
   - Constructs a small inline message (not the canonical P1 template) and invokes:
     - `timeout <DISPATCH_TIMEOUT> <DISPATCH_CMD_ARR...> "$CYCLE_MESSAGE"`
   - `RALPH_DISPATCH_CMD` must point to *something* that accepts a final string message argument (could be `claude --print ...`, could be something else).
7. **Wait for state**:
   - Polls `STATE.yaml` until it observes cycle completion or phase terminal states.
   - It does not interpret the orchestrator’s final token.

### What “a full cycle” is supposed to be (per `CLAUDE.md`)

When the orchestrator receives `DEADF_CYCLE <cycle_id>`, it must execute exactly one action per cycle:

1. LOAD → read `STATE.yaml`, `POLICY.yaml`, optional `OPS.md`, plus `task.files_to_load`.
2. VALIDATE → derive nonce from cycle id, set `cycle.status=running`, set started timestamp, check budgets.
3. DECIDE → map (`phase`, `task.sub_step`, stuck/budget/failure conditions) to exactly one action.
4. EXECUTE → perform that action (often dispatching a planner/implementer/verifier).
5. RECORD → atomically write state under `STATE.yaml.flock`, increment `loop.iteration`, set `cycle.status={complete|failed}`, etc.
6. REPLY → print last-line token: `CYCLE_OK` or `CYCLE_FAIL` or `DONE`.

In other words: the *real* state machine is in `CLAUDE.md`, not in bash/python.

## 1.2 Roles and component responsibilities (as implemented vs as claimed)

### “Five actors” model (docs)

- **Ralph (`ralph.sh`)**: mechanical loop controller; no “thinking”; can only set `phase=needs_human` or `cycle.status=timed_out`.
- **Orchestrator (Claude Code + `CLAUDE.md`)**: reads state, decides next action, dispatches planning/implementation/verification, updates state, runs rollback.
- **Planner (GPT‑5.2)**: produces track selection/spec/plan and task packets using `.pipe/p3–p6` prompts.
- **Implementer (gpt‑5.2‑codex)**: edits code and makes one commit per task using `.pipe/p7/P7_IMPLEMENT_TASK.md`.
- **Verifier**:
  - deterministic: `verify.sh`
  - probabilistic: per-criterion LLM review via `.pipe/p9/P9_VERIFY_CRITERION.md`
  - aggregation: `build_verdict.py`

### What the code actually guarantees

- **Launcher / loop logic exists** (`.pipe/p1/p1-cron-kick.sh`, `ralph.sh`).
- **Deterministic verifier exists** (`verify.sh`) but its inputs do not match the documented task packet formats (details in Weaknesses).
- **Sentinel parsers exist** (`extract_plan.py`, `build_verdict.py`), but `extract_plan.py` currently parses **only PLAN** blocks, not TRACK/SPEC blocks that the contract depends on.
- **The orchestrator is not code**. It is a contract for an LLM to follow.

This is not inherently wrong, but it means correctness hinges on **contract-template-tool alignment**, which currently is not achieved.

## 1.3 The state machine (phases, sub-steps, and transitions)

### Phase-level states (per `CLAUDE.md` and partially validated by `ralph.sh`)

- `research`
- `select-track`
- `execute`
- `complete`
- `needs_human` (terminal pause)

### Task sub-steps (inside `execute`)

`task.sub_step` is the fine-grained state:

- `null` / `generate` → `generate_task`
- `implement` → `implement_task`
- `verify` → `verify_task`
- `reflect` → `reflect`
- `qa_review` → `qa_review` (track-level, conditional at track end)

### Cycle status (`cycle.status`)

`cycle.status` represents “this cycle is currently being executed”:

- `idle` → ready for next kick
- `running` → orchestrator in-flight
- `complete` / `failed` / `timed_out` → end markers that the launcher/loop can detect

### High-level transition sketch

```
research
  └─(P2 seeded)──────────────────────────────▶ select-track

select-track
  ├─(no track)────────▶ pick_track ─────────▶ select-track (with track.id set)
  ├─(no spec)─────────▶ create_spec ────────▶ select-track (with spec_path set)
  └─(no plan)─────────▶ create_plan ────────▶ execute (sub_step=generate)

execute
  generate ───────────▶ implement ─────────▶ verify ─────────▶ reflect ─┬─▶ (more tasks) generate
                                                                        └─▶ (track end) qa_review? ─▶ select-track

any state
  ├─(budget exceeded / invalid state)────────▶ needs_human
  ├─(stuck threshold, first time)────────────▶ replan_task (sub_step=generate, replan_attempted=true)
  ├─(stuck threshold again)──────────────────▶ needs_human
  └─(retry_count >= max_retries)─────────────▶ rollback_and_escalate ───▶ needs_human

all tracks done ─────────────────────────────▶ complete ───────────────▶ DONE
```

### Transition logic is intentionally “table-driven”

`CLAUDE.md` defines a precedence-ordered decision table. This is good: it makes the orchestrator’s behavior testable in principle, and it reduces “LLM creativity” in the control plane.

---

# 2. Strengths

## 2.1 The *idea* is strong: deterministic rails around stochastic work

- **Strict sentinel grammars** + **nonce per cycle** are the right approach if you want automation that can fail fast and recover deterministically.
- The P10 tiered recovery flow (format-repair → auto-diagnose → per-block policy) is pragmatic and acknowledges that LLMs often “almost” comply.
- “One cycle = one action” is a great control constraint. It prevents runaway prompt chains and makes recovery + auditing easier.

## 2.2 Role separation is a real safety primitive (if enforced)

The conceptual separation (planner vs implementer vs verifier) is a meaningful control:

- Planner can’t silently code.
- Implementer can’t silently rewrite policy/contract.
- Verifier can’t “approve by vibes” if deterministic checks fail.

This is one of the more mature designs compared to many autonomous coding loops that blur those roles.

## 2.3 State discipline (YAML + locking + atomic writes)

- The contract explicitly mandates `STATE.yaml.flock`, bounded wait, and temp-write+rename atomicity.
- `ralph.sh` respects this for its limited writes.
- `.pipe/p1/p1-cron-kick.sh` also uses the lock when force-updating stale “running” cycles.

This is good ops hygiene: it anticipates concurrency, crashes, and partial writes.

## 2.4 Conservative verification philosophy is correct

From `POLICY.yaml` and `CLAUDE.md`:

- deterministic FAIL always wins
- PASS + LLM FAIL → FAIL (conservative)
- PASS + LLM NEEDS_HUMAN → pause

This bias is appropriate if the pipeline is allowed to commit code.

## 2.5 P12 “brownfield mapper” is a useful extension

P12 is actually implemented as scripts (`.pipe/p12/*.sh`) that:

- collect evidence
- optionally run `claude` to produce analysis yaml
- run `codex` to synthesize living docs
- fallback gracefully if tooling is missing

That’s a concrete, valuable subsystem: it reduces cold-start cost for brownfield repos and can improve plan quality.

---

# 3. Weaknesses / Gaps (what’s broken or will break)

## 3.1 Contract ↔ tooling mismatch (this is the #1 problem)

### `extract_plan.py` does not parse what the orchestrator needs

`CLAUDE.md` says to parse:

- `<<<TRACK:...>>>` blocks (P3)
- `<<<SPEC:...>>>` blocks (P4)
- `<<<PLAN:...>>>` blocks (P5)

But `extract_plan.py` only recognizes **PLAN** open/close lines and only validates fields for a *single task plan payload* (`TASK_ID`, `TITLE`, `FILES`, `ACCEPTANCE`, etc.). It does not support:

- multi-task plans (`TASK_COUNT`, `TASK[n]`)
- TRACK/SPEC grammars

Net: the orchestrator cannot deterministically consume planner outputs as specified.

### `verify.sh` expects a TASK file format that the templates do not produce

`verify.sh` assumes:

- `TASK.md` exists in project root
- `ESTIMATED_DIFF` is present as `ESTIMATED_DIFF=<int>` or `ESTIMATED_DIFF: <int>`
- planned file paths are discoverable via `path=<...>` tokens

But the task packet templates in the repo (`CLAUDE.md` “minimum required sections” and `.pipe/p6/P6_GENERATE_TASK.md`) format files like:

- `- path: ... | action: ... | rationale: ...`
- `## ESTIMATED_DIFF` followed by a bare number

Those do **not** match the `grep -oP` patterns in `verify.sh`. Result:

- diff budget check likely never runs (estimated diff not parsed)
- allowed paths list is likely empty (paths not parsed)

Even worse: `CLAUDE.md` says task packets live at `.deadf/tracks/.../TASK_{NNN}.md`, but `verify.sh` reads `TASK.md` by default. That implies either:

- orchestrator must copy/symlink the task packet into `TASK.md` (not documented in action specs), or
- verifier is currently incompatible with the pipeline contract.

### `ralph.sh` and P1 launcher disagree on “the canonical kick”

`CLAUDE.md` calls `.pipe/p1/P1_CYCLE_KICK.md` the canonical kick template and prefers `.pipe/p1/p1-cron-kick.sh` as launcher.

But `ralph.sh`:

- constructs its own kick message (missing fields present in P1 template: `path:`, `task_list_id:`, etc.)
- requires `RALPH_DISPATCH_CMD` and doesn’t mention using `.pipe/p1/p1-cron-kick.sh`

So “what actually kicks the orchestrator” is ambiguous in practice.

## 3.2 `POLICY.yaml` still contains bot-era assumptions

Examples:

- rollback section says `authority: clawdbot`, while `CLAUDE.md` says “You (Claude Code) run rollback commands.”

Policy drift matters because it’s referenced for deterministic decisions.

## 3.3 The orchestrator is an LLM with write access (risk)

Even with strong instructions, the orchestrator has `Read,Write,Edit,Bash` tool access by design. That means:

- A prompt injection in repo content (e.g., malicious `OPS.md`, malicious comments) could influence a tool-enabled agent.
- The threat model is not addressed explicitly beyond “No secrets in files.”

If you want “run while you sleep,” you need a concrete adversarial model and sandboxing defaults (not just best-effort prompts).

## 3.4 Determinism claims are overstated

Even if all contracts matched, the system is only deterministic at the envelope:

- P7 directs implementer to run tests/lint/build, but what those commands are is heuristic unless `OPS.md` exists.
- `verify.sh` is heuristic in selecting test/lint commands (package.json → npm test; python projects → pytest; etc.).

This is fine, but it’s not “deterministic verification” in the strict sense; it’s “deterministically executed heuristics.”

## 3.5 Real-world brittleness

Things that will break in actual usage:

- Repos without `yq v4` (hard requirement in `ralph.sh` and launcher).
- Monorepos / multi-language repos: `verify.sh` heuristics are simplistic and may pick the wrong runner.
- Repos where running tests requires env vars/secrets/services: verify will fail; pipeline will thrash unless `OPS.md` is curated.
- Non-standard git branching (not `main`): rollback commands hardcode `main`.
- Concurrent runners (CI + local): lock files are local; on NFS or CI parallelism you can still get weirdness unless locks are shared correctly.

---

# 4. Opinions (architect-level, compared to other systems)

## 4.1 Is the architecture sound for the stated goals?

The *architecture* is directionally sound for “autonomous local dev pipeline” **if** you enforce two invariants:

1. **The control plane must be truly deterministic** (state transitions + parsing + gating).
2. **The data plane must be bounded** (implementation scope, budgets, sandbox limits).

Right now, the repo is closer to a **design document that accidentally ships mismatched components** than a working pipeline.

## 4.2 Comparison to Devin / SWE-Agent / OpenHands / Aider

- **SWE-Agent / OpenHands**: tend to rely on tool loops with flexible reasoning and less strict grammars. deadfish-cli is more “workflow engine” than “agent,” which is good for reliability but increases integration burden.
- **Aider**: uses git as the main safety boundary and keeps the loop tight. deadfish-cli also uses git, but introduces additional state and multi-stage verification. That can be better for complex projects, but it’s more moving parts.
- **Devin-style** systems: aim for broad autonomy + memory + long-horizon planning. deadfish’s design is intentionally narrower and more procedural. That’s a good tradeoff for CLI/CI usage, but only if the procedure is actually executable.

Net: deadfish-cli is closer to “a deterministic autonomous build pipeline with LLM workers” than “an autonomous engineer.” That’s a sensible category—just don’t pretend it’s simpler than it is.

## 4.3 What I would change if redesigning from scratch

If the goal is “overnight coding loops that you can trust,” I would:

1. **Make the orchestrator a real program** (even a thin one) that owns:
   - state transitions
   - prompt assembly
   - parsing and retries
   - calling `claude`/`codex`
   The LLM would become a worker for planning/implementation/review, not the workflow engine.
2. Keep the sentinel formats, but enforce them with **unit tests** and **golden files**.
3. Collapse duplicate launchers: pick **one** kick path (cron launcher or ralph loop), and make the other a wrapper.
4. Treat `OPS.md` as first-class required config for anything non-trivial (or provide per-language adapters).
5. Introduce a real sandbox story for implementer/verifier commands (containers, seccomp, or at least an allowlist).

## 4.4 Is the complexity justified?

The strict parsing + nonce + tiered repair complexity *is* justified **if you are committed to running unattended**.

What’s not justified is having:

- a 1239-line contract (`CLAUDE.md`)
- numerous prompt templates
- multiple launch paths

…without integration tests ensuring that the actual scripts and parsers conform to those contracts. That’s not “over-engineering”; it’s “under-integrating.”

## 4.5 Most impressive vs weakest parts

- Most impressive: **the control-plane philosophy** (table-driven decisions + strict IO formats + locks). It’s the right mindset.
- Weakest: **contract drift / lack of executable coherence** (parsers don’t parse required blocks; verifier doesn’t read produced task packets; launcher/controller divergence).

---

# 5. Recommendations (prioritized)

## Top 5 next actions (high leverage, in order)

1. **Unify contracts and tooling (make it run once end-to-end).**
   - Choose the canonical kick path (I’d pick `.pipe/p1/p1-cron-kick.sh` or make `ralph.sh` call it).
   - Ensure the orchestrator’s “VALIDATE/RECORD” state writes match what kickers poll.

2. **Fix `extract_plan.py` scope or rename it.**
   - Either: extend it to parse TRACK + SPEC + multi-task PLAN exactly as templates specify,
   - or: stop claiming it parses those and introduce separate parsers (`extract_track.py`, `extract_spec.py`, `extract_plan.py` with multi-task support).

3. **Make `verify.sh` consume the real task packet format.**
   - Decide the authoritative task packet schema (prefer one).
   - Update `verify.sh` to parse:
     - the right task file path (likely from `STATE.yaml` or as an argument)
     - `ESTIMATED_DIFF` robustly
     - planned file paths robustly
   - Make “out-of-scope file edits” a configurable policy decision (warn vs fail), not an implicit warning.

4. **Add a real integration test harness (even minimal).**
   - Provide a fixture repo under `tests/fixtures/` with a dummy `STATE.yaml`.
   - Simulate planner output and ensure parsers accept/reject correctly.
   - Simulate verifier JSON and ensure verdict aggregation works.
   This is mandatory if you want “deterministic.”

5. **Threat-model and sandbox the data plane.**
   - Default implementer/verifier to least privilege:
     - restrict bash commands
     - restrict filesystem paths
     - optionally run in a container
   - Treat repo content as untrusted input; explicitly defend against prompt injection (especially via `OPS.md` and “files_to_load”).

## Security concerns (concrete)

- Running `codex exec` in `--approval-mode full-auto` and allowing `Bash` tool access is equivalent to “run arbitrary code in this repo.” If you ever point it at an untrusted repo, you are exposed.
- `verify.sh` performs regex-based secret scanning only on added lines and only for a handful of patterns. It will miss many credential formats and can produce false negatives.
- Rollback procedure assumes branch `main`. In repos with different default branches, the pipeline can reset the wrong thing or fail mid-rollback.
- The system implicitly trusts `OPS.md` (commands) and any injected context. That is a prompt-injection vector plus an execution vector.

## Scalability considerations

Scales fine for single-repo, single-run usage, but weak for:

- **Many repos / many concurrent runs**: lockfiles are local and ad-hoc; no central scheduler or queue.
- **Large diffs / long tracks**: token budgets + evidence bundles become expensive; you’ll end up truncating the exact context you need for LLM verification.
- **Non-homogeneous repos**: verifier heuristics don’t scale; you’ll need per-project adapters (OPS profiles) or plugins.
- **Auditability**: logs exist, but without a single canonical runner it’s hard to reconstruct “what kicked what” consistently.

---

## Appendix A — Key files reviewed

- `CLAUDE.md` (core contract; 1239 lines)
- `ralph.sh` (loop controller)
- `.pipe/p1/p1-cron-kick.sh` + `.pipe/p1/P1_CYCLE_KICK.md` (launcher + kick template)
- `POLICY.yaml` (modes + thresholds)
- `verify.sh` (deterministic verifier)
- `extract_plan.py` (sentinel plan parser — currently PLAN-only)
- `build_verdict.py` (sentinel verdict parser)
- `.pipe/p3/P3_PICK_TRACK.md`, `.pipe/p4/P4_CREATE_SPEC.md`, `.pipe/p5/P5_CREATE_PLAN.md`, `.pipe/p6/P6_GENERATE_TASK.md`, `.pipe/p7/P7_IMPLEMENT_TASK.md`, `.pipe/p9/P9_VERIFY_CRITERION.md`, `.pipe/p9.5/P9_5_REFLECT.md`, `.pipe/p10/*`, `.pipe/p11/*`
- `.pipe/p12-init.sh` + `.pipe/p12/*` (brownfield mapping)
- `VISION.md`, `ROADMAP.md`, `METHODOLOGY.md`, `README.md`, `llms.txt`, `examples/project-structure.md`, `.mcp.json`

