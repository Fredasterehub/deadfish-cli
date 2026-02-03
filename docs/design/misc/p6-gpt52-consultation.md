# P6 (generate_task) Consultation — GPT‑5.2 (Codex) — 2026‑01‑31

This is an opinionated recommendation, not a tour of possibilities.

---

## Executive take

- **Keep P6. Don’t bake it into P5.** But **change P6’s job**: from “LLM generates the next task” to “JIT task compiler (mostly deterministic) + reality checks + retry packaging”.
- P5 should remain the **static, cheap, stable plan** (“what sequence of work, in what order, with what acceptance”). P6 should be the **dynamic, codebase-aware adapter** (“given the current HEAD, what exactly do we load, touch, and how do we run this task safely now?”).
- If you remove P6, you’ll either (a) violate the **one‑action‑per‑cycle** heartbeat by implicitly chaining “select task + implement”, or (b) push orchestration responsibilities into the implementer, which is exactly how you get drift, thrash, and scope creep.

---

## Q1 — Do we really need P6, or should we bake everything into P5?

### Recommendation

**You need P6.** Not because you need another LLM call, but because you need a **separate heartbeat step** whose purpose is “bind plan → current repo reality”.

### Why baking into P5 is the wrong move

P5 runs at a point in time. By task 3, task 1–2 have altered:
- file layout, entrypoints, tests, configs
- what “the right integration point” even is
- what context is most relevant to load under the ~3,000 token hot-loop cap

If you “pre-generate everything” in P5, you lock in **stale file targeting** and **stale context selection**. You will still need a step later that says “given current HEAD, what now?” — that step is P6 (whether you call it P6 or you smuggle it elsewhere).

### Why making P6 “purely mechanical extraction” is also wrong (if taken literally)

Mechanical extraction is the right default, but **not sufficient**. If P6 does *only* “copy TASK[n] into TASK.md”, you lose the Conductor insight at the task level:

> search first, then spec

You don’t want P6 to re-plan; you want P6 to **re-validate** and **re-bind**:
- validate plan references against the current codebase (paths exist, integration points still make sense)
- pick the correct *current* surrounding context for the implementer (tests/config/entrypoints) without blowing the budget
- package retry context when failures happen (so retries are not “try again”)

### The right shape: “P6 as JIT compiler”

**Happy path (first attempt of a task):**
- deterministic: extract `TASK[track.task_current]` from P5 PLAN
- write `TASK_00N.md` (or `TASK.md`) as the execution packet
- compute a **fresh `files_to_load` pack** from current HEAD (not whatever P5 guessed)

**Unhappy path (plan/task mismatch or retry):**
- still start deterministic (detect mismatch)
- only then do a *small* GPT call to adapt the task **without regenerating the whole plan**
  - keep acceptance criteria immutable
  - patch *only* file targeting / integration guidance / missing context

This keeps P6 dynamic and codebase-aware while avoiding token-waste “replanning what P5 already did”.

---

## How to keep P6 dynamic without wasting tokens

### 1) Draw a hard line between “plan truth” and “execution packet”

- **P5 PLAN** is the “source of truth”: tasks, ordering, acceptance, intended touched files.
- **P6 TASK.md** is the “execution packet”: the same task, but with **current‑HEAD bindings**:
  - resolved file paths (if the plan’s guessed paths drifted)
  - `files_to_load` chosen *now* (planned touched files + minimum adjacent integration + tests/config)
  - retry notes (only when needed)

P6 shouldn’t change intent; it should change *bindings*.

### 2) Make LLM usage conditional, not default

Use GPT in P6 only for cases deterministic logic can’t safely resolve:
- plan references `modify/delete` paths that no longer exist
- “add file” task needs a registry/entrypoint and heuristics can’t pick it
- previous attempt failed and the error needs interpretation into “do X differently”

Otherwise, P6 is just packaging and validation.

### 3) Add a cheap drift signal (so you don’t guess)

Right now, the design implicitly assumes “PLAN is still correct”. You want a cheap, unambiguous signal:
- record `track.plan_base_commit` when P5 writes the plan
- in P6, compare `HEAD` vs `plan_base_commit` to decide whether to:
  - proceed mechanically (no drift)
  - do extra validation / search (drift exists)

This gives you JIT awareness without always paying for it.

### 4) Don’t overload `FILES`

Keep `FILES` as the “touched scope” (what verify/LLM scope checking cares about).
Let P6 compute `files_to_load` separately as “context pack” (touched files + tests + config + entrypoints).

This is how you stay inside the ~3,000 token hot-loop file budget without weakening scope enforcement.

---

## Concrete changes I’d make (minimal, builds on what you already have)

### 1) Update the contract, don’t redesign it

In `CLAUDE.md`, rewrite `generate_task` to match the P2–P5 restructure:
- Input: `STATE.yaml`, `.deadf/tracks/{track.id}/PLAN.md`, `OPS.md`, current repo tree
- Output: `.deadf/tracks/{track.id}/tasks/TASK_00N.md` (execution packet)
- Behavior:
  - parse/extract `TASK[N]` from PLAN
  - validate file paths and dependencies against current HEAD
  - compute `task.files_to_load` fresh (bounded) and update `STATE.yaml`
  - **no GPT call on happy path**
  - GPT call only on mismatch/retry, producing a patched TASK packet (not a new plan)

Do not change the DECIDE table shape; just fix what “generate_task” actually means.

### 2) Keep the sentinel DSL and scripts; extend them

You already have a deterministic parsing philosophy (sentinels + `extract_plan.py`).
Don’t invent a new parsing scheme for multi-task plans or task extraction; extend the existing tooling so:
- P5 PLAN block (multi-task) can be parsed deterministically
- P6 can extract `TASK[n]` deterministically

This is the “don’t reinvent the wheel” point in practice.

### 3) Keep retry/stuck handling where it belongs

- **Retry belongs to P7/P8 (implement/verify loop)**: the implementer needs the failure context; P6 should package it into TASK.md when re-entering implementation.
- **Stuck belongs to DECIDE + `replan_task`**: keep the “heartbeat” logic centralized. Don’t smear stuck logic across multiple phases.
- P6’s role is narrower: ensure the *next attempt* is not blind (include error excerpt, what changed, what to try differently).

---

## Q2 — Are we leveraging what we already have, or reinventing the wheel?

You have the right components already:
- **DECIDE table** + one‑action heartbeat (this is a strong design; keep it)
- **Sentinel DSL** + deterministic parsers (good; extend, don’t replace)
- **STATE.yaml** as authority (good; don’t move “what’s next” into freeform markdown)
- **OPS.md** as hot-loop ops cache (good; keep it tight)
- **verify.sh** as deterministic gate (excellent; keep DET vs LLM split)

Where you are *not* leveraging what you already built (and it will bite you):

- The current `generate_task` spec (as written in `CLAUDE.md`) still describes “LLM generates a task spec from scratch”. That is the old world. In the new world, **P5 is the generator** and P6 is the binder/packetizer.
- If you keep the old wording/shape, you will slowly drift back into “re-plan every cycle”, burning tokens and reintroducing a failure mode you just removed with plans-as-prompts.

---

## If you insist on removing P6 (I don’t recommend it)

Only one version is remotely coherent:
- Make `implement_task` read the plan, select the next task, compute its own context pack, and proceed.

That violates the spirit of the heartbeat model (it silently chains “generate + implement”), inflates the implementer prompt/context, and makes retries/stuck harder to reason about because “what task was actually run?” becomes implicit.

If you want debuggability, auditability, and predictable recovery behavior, keep P6 and make it cheap.

