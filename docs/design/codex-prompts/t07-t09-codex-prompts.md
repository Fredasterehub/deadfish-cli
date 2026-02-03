# T07–T09 Codex Prompts (P3–P5 Redesign)

## T07 — Create `/.pipe/p3/P3_PICK_TRACK.md` (Track Selection)

````text
You are GPT-5.2-Codex inside the repo at `/tank/dump/DEV/deadfish-cli`.

Task: Create a NEW prompt file for GPT-5.2 planner that selects the next track *within the current roadmap phase*.

You must create this exact file:
- Add: `.pipe/p3/P3_PICK_TRACK.md`

If these directories do not exist yet, create them:
- `.pipe/p3/`

Reference docs to open (these define the contract + formats; follow them exactly):
- `.pipe/p2-p5-restructure-opus.md` (Section 6: P3 redesign; use the sentinel TRACK format verbatim)
- `CLAUDE.md` (Sentinel DSL style reference: nonce, `<<<...>>>` wrappers, guardrail “output ONLY sentinel block” pattern)
- `STATE.yaml` (live state; contains current `roadmap.current_phase` and current `phase`)
- `ROADMAP.md` (phases, goals, success_criteria, requirements mapped to phases)
- `REQUIREMENTS.md` (requirement statuses; pending/in_progress/complete/blocked; acceptance criteria)
- `VISION.md` (strategic direction; optional but recommended per restructure plan)
- `PROJECT.md` (constraints/decisions; optional but recommended per restructure plan)

What to write into `.pipe/p3/P3_PICK_TRACK.md`:
- Use the layered prompt structure:
  - `--- ORIENTATION (0a-0c) ---`
  - `--- OBJECTIVE (1) ---`
  - `--- RULES ---`
  - `--- GUARDRAILS (999+) ---`
- Make the prompt phase-aware:
  - It must direct the planner to read STATE.yaml and determine the *current roadmap phase id*.
  - It must direct the planner to read ROADMAP.md for that phase’s goal/success_criteria/requirements.
  - It must direct the planner to read REQUIREMENTS.md and consider requirement `status` for the phase’s requirements.
- Selection rules:
  - Maximize progress on unmet phase success criteria.
  - Prefer unblocked requirements (avoid `blocked` unless there is no other useful work).
  - Prefer smaller tracks: target 2–5 tasks per track.
  - Never select work outside the current phase.
- Output requirements:
  - Output MUST be a sentinel TRACK block ONLY (no prose before/after).
  - Include `PHASE_COMPLETE` and `PHASE_BLOCKED` output signals.

IMPORTANT: Include this sentinel TRACK block format verbatim (from `.pipe/p2-p5-restructure-opus.md` Section 6) in the prompt file:

<<<TRACK:V1:NONCE={nonce}>>>
TRACK_ID=<bare>
TRACK_NAME="<quoted>"
PHASE={phase_id}
REQUIREMENTS=[<comma-separated REQ IDs>]
GOAL="<1-2 sentence goal>"
ESTIMATED_TASKS=<positive integer, 2-5 recommended>
<<<END_TRACK:NONCE={nonce}>>>

Define explicit signal behavior inside `.pipe/p3/P3_PICK_TRACK.md` while still satisfying “output ONLY sentinel block”:
- If all requirements for the current phase are already `complete`, output a TRACK sentinel block that contains `PHASE_COMPLETE=true` and `PHASE={phase_id}` and nothing else (omit track fields).
- If all remaining (non-complete) requirements in the current phase are `blocked`, output a TRACK sentinel block that contains `PHASE_BLOCKED=true`, `PHASE={phase_id}`, and `REASONS=` (1–5 concise reasons) and nothing else (omit track fields).

Guardrails to include in `.pipe/p3/P3_PICK_TRACK.md`:
- Output ONLY the sentinel block (no preamble).
- Never select work outside the current phase (unless emitting `PHASE_COMPLETE=true`).
- Do not invent requirement IDs; REQUIREMENTS must be a subset of requirement IDs from the current phase.
- ESTIMATED_TASKS must be 2–5 for normal track selection.

Done-when checklist:
- [ ] `.pipe/p3/P3_PICK_TRACK.md` exists and uses the layered (0a/1/rules/999+) structure.
- [ ] It instructs reading `STATE.yaml`, `ROADMAP.md`, `REQUIREMENTS.md` (and optionally `VISION.md`/`PROJECT.md`) to be phase-aware.
- [ ] It includes the TRACK sentinel format above verbatim.
- [ ] It defines `PHASE_COMPLETE=true` and `PHASE_BLOCKED=true` signal outputs while still “sentinel block only”.
- [ ] Guardrails explicitly forbid selecting work outside the current phase.
````

## T08 — Create `/.pipe/p4/P4_CREATE_SPEC.md` (JIT Spec)

````text
You are GPT-5.2-Codex inside the repo at `/tank/dump/DEV/deadfish-cli`.

Task: Create a NEW prompt file for GPT-5.2 planner that generates a just-in-time track spec (WHAT to build), using the Conductor-style “search first” pattern.

You must create this exact file:
- Add: `.pipe/p4/P4_CREATE_SPEC.md`

If these directories do not exist yet, create them:
- `.pipe/p4/`

Reference docs to open (these define the contract + what must be loaded):
- `.pipe/p2-p5-restructure-opus.md` (Section 7: P4 design; use sentinel SPEC format verbatim)
- `CLAUDE.md` (Sentinel DSL patterns: nonce, wrappers, output-only guardrails)
- `STATE.yaml` (must contain selected track info: `track.id`, `track.name`, `track.phase`, `track.requirements`, `track.spec_path`)
- `ROADMAP.md` (current phase success_criteria and requirements for phase context)
- `REQUIREMENTS.md` (full text + acceptance criteria for targeted requirement IDs)
- `PROJECT.md` (constraints/decisions/context)
- `OPS.md` (if present; build/test/lint commands)

Add an explicit “codebase search” instruction section inside `.pipe/p4/P4_CREATE_SPEC.md` (replaces Conductor interactive Q&A):
- Instruct the planner to rely on provided `rg`/`find` results for related symbols and files.
- Instruct: if no search evidence is provided, do NOT assume files exist; list `EXISTING_CODE` as empty (or only what is explicitly given) and keep the spec conservative.

What to write into `.pipe/p4/P4_CREATE_SPEC.md`:
- Use the layered prompt structure:
  - `--- ORIENTATION (0a-0c) ---`
  - `--- OBJECTIVE (1) ---`
  - `--- RULES ---`
  - `--- GUARDRAILS (999+) ---`
- ORIENTATION must:
  - Read STATE.yaml to identify the current track and requirement IDs being addressed.
  - Read REQUIREMENTS.md for those requirement IDs’ text + acceptance criteria (DET/LLM tagging already exists at REQUIREMENTS level).
  - Include a “search codebase first” step (rg/find) and “read OPS.md” step.

IMPORTANT: Include this sentinel SPEC block format verbatim (from `.pipe/p2-p5-restructure-opus.md` Section 7) in the prompt file:

<<<SPEC:V1:NONCE={nonce}>>>
TRACK_ID={track.id}
TITLE="<quoted>"
OVERVIEW=
  <2-space indented: what this track delivers, 3-5 sentences>
REQUIREMENTS:
- id=<REQ-ID> text="<requirement text>"
FUNCTIONAL:
- id=FR<n> text="<functional requirement>"
NON_FUNCTIONAL:
- id=NFR<n> text="<non-functional requirement>"
ACCEPTANCE_CRITERIA:
- id=AC<n> req=<REQ-ID> text="<DET:|LLM: testable criterion>"
OUT_OF_SCOPE:
- "<what this track does NOT do>"
EXISTING_CODE:
- path=<file> relevance="<how it relates>"
<<<END_SPEC:NONCE={nonce}>>>

Rules to include in `.pipe/p4/P4_CREATE_SPEC.md`:
- Every AC must trace to a requirement ID (`req=<REQ-ID>` must match one of the REQUIREMENTS entries).
- Tag each AC text with `DET:` or `LLM:` (matching CLAUDE.md convention).
- Include ALL existing code that will be modified or referenced; do not list files not evidenced by search or provided context.
- Keep scope tight: ≤5 tasks worth of work.
- “Spec defines WHAT, not HOW” (implementation strategy belongs in the plan).

Guardrails to include:
- Output ONLY the sentinel SPEC block (no prose).
- Do not hallucinate files or code; if you can’t evidence it, don’t list it.
- Acceptance criteria must be verifiable (no vague verbs).

Done-when checklist:
- [ ] `.pipe/p4/P4_CREATE_SPEC.md` exists and uses layered (0a/1/rules/999+) structure.
- [ ] It instructs loading `STATE.yaml`, `ROADMAP.md`, `REQUIREMENTS.md`, `PROJECT.md`, `OPS.md` (+ codebase search evidence).
- [ ] It includes the SPEC sentinel format above verbatim.
- [ ] It requires AC→REQ traceability and `DET:`/`LLM:` tagging.
- [ ] It contains explicit anti-hallucination guardrails for `EXISTING_CODE`.
````

## T09 — Create `/.pipe/p5/P5_CREATE_PLAN.md` (Plans-as-Prompts)

````text
You are GPT-5.2-Codex inside the repo at `/tank/dump/DEV/deadfish-cli`.

Task: Create a NEW prompt file for GPT-5.2 planner that produces a multi-task implementation plan where each task’s SUMMARY is directly executable by gpt-5.2-codex (plans-as-prompts).

You must create this exact file:
- Add: `.pipe/p5/P5_CREATE_PLAN.md`

If these directories do not exist yet, create them:
- `.pipe/p5/`

Reference docs to open (these define the contract + inputs):
- `.pipe/p2-p5-restructure-opus.md` (Section 8: P5 design; use sentinel PLAN format verbatim)
- `CLAUDE.md` (Sentinel DSL patterns; acceptance criteria DET/LLM conventions)
- `STATE.yaml` (track info and spec_path)
- `.deadf/tracks/{track_id}/SPEC.md` (or wherever STATE.yaml points; this is the spec produced by P4)
- `PROJECT.md` (constraints/decisions/context)
- `OPS.md` (if present; build/test/lint commands)

What to write into `.pipe/p5/P5_CREATE_PLAN.md`:
- Use the layered prompt structure:
  - `--- ORIENTATION (0a-0c) ---`
  - `--- OBJECTIVE (1) ---`
  - `--- RULES ---`
  - `--- GUARDRAILS (999+) ---`
- The plan must be “plans-as-prompts”:
  - SUMMARY is the actual implementation prompt (imperative instructions).
  - SUMMARY must be directly executable by gpt-5.2-codex without transformation.

IMPORTANT: Include this sentinel PLAN block format verbatim (from `.pipe/p2-p5-restructure-opus.md` Section 8) in the prompt file:

<<<PLAN:V1:NONCE={nonce}>>>
TRACK_ID={track.id}
TASK_COUNT=<N>

TASK[1]:
TASK_ID={track.id}-T01
TITLE="<quoted>"
SUMMARY=
  <2-space indented: what to implement, 2-3 sentences>
FILES:
- path=<bare> action=<add|modify|delete> rationale="<quoted>"
ACCEPTANCE:
- id=AC<n> text="<DET:|LLM: testable criterion>"
ESTIMATED_DIFF=<positive integer>
DEPENDS_ON=[]

TASK[2]:
TASK_ID={track.id}-T02
...

<<<END_PLAN:NONCE={nonce}>>>

Rules to include in `.pipe/p5/P5_CREATE_PLAN.md`:
- 2–5 tasks total.
- Each task ≤200 diff lines (planner should split if larger).
- ≤5 files per task.
- Every acceptance criterion from SPEC.md must appear in exactly one task’s ACCEPTANCE list (no duplicates, no omissions).
- ESTIMATED_DIFF should be the smallest plausible implementation estimate (and tasks should still fit within 3× estimate at implement time).
- DEPENDS_ON lists prior TASK_IDs if needed; otherwise `[]`.
- SUMMARY must be actionable instructions (e.g., “Add X file… Update Y function… Add tests… Run commands from OPS.md…”), not a narrative description.

Guardrails to include:
- Output ONLY the sentinel PLAN block (no prose).
- No hallucinated files: every `FILES` path must already exist (if modify/delete) or be explicitly created (if add), and must be consistent with the repo structure.
- The plan must be implementation-ready: “do this, then that”, not “we should consider…”.

Done-when checklist:
- [ ] `.pipe/p5/P5_CREATE_PLAN.md` exists and uses layered (0a/1/rules/999+) structure.
- [ ] It instructs loading `STATE.yaml`, `SPEC.md`, `PROJECT.md`, `OPS.md`.
- [ ] It includes the PLAN sentinel format above verbatim.
- [ ] It enforces 2–5 tasks, ≤200 lines/task, ≤5 files/task.
- [ ] It enforces exact coverage: every SPEC AC appears in exactly one task.
- [ ] It explicitly defines SUMMARY as the direct gpt-5.2-codex implementation prompt (actionable, imperative).
````

