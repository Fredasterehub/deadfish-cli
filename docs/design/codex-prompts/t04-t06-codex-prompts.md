# T04–T06 Codex Prompts (P2 Restructure)

## T04 — Update `/.pipe/p2/P2_E.md` (Crystallize)

````text
You are GPT-5.2-Codex inside the repo at `/tank/dump/DEV/deadfish-cli`.

Task: Update the P2 crystallize-phase prompt so it produces structured, user-confirmed inputs for the NEW 5-file P2 outputs:
- `VISION.md`
- `PROJECT.md`
- `REQUIREMENTS.md`
- `ROADMAP.md`
- `STATE.yaml` (initialization only)

You must make surgical edits to this exact file:
- Modify: `.pipe/p2/P2_E.md`

Context: P2 previously only fed `VISION.md` + `ROADMAP.md`. Per the restructure plan, P2 must now also feed:
- `project.core_value`, `project.constraints[]`, `project.key_decisions[]` (for `PROJECT.md`)
- Categorized requirements with stable IDs + acceptance criteria (for `REQUIREMENTS.md`)
- Strategic roadmap phases (not tracks) with success criteria + requirement ID references (for `ROADMAP.md`)

Reference templates (these are the target schemas; open them and align P2_E’s “crystallize outputs” to these shapes):
- `.pipe/p2/P2_PROJECT_TEMPLATE.md`
- `.pipe/p2/P2_REQUIREMENTS_TEMPLATE.md`
- `.pipe/p2/P2_ROADMAP_TEMPLATE.md`

Precise changes to make in `.pipe/p2/P2_E.md`:
1) Replace the current “1) Vision Statement … 6) Open Questions …” list with a new ordered set of crystallize blocks that explicitly map to the 5 output files.
2) Ensure P2_E now prompts the facilitator to synthesize AND present for user approval/edits:
   - VISION inputs (constitution-style; keep crisp and testable)
   - PROJECT inputs including:
     - `project.name` and `project.description` (needed by the template)
     - `project.core_value` (single must-work statement)
     - `project.constraints[]` as objects with `type` limited to `tech|timeline|budget|dependency|compatibility`, plus `what` and `why`
     - `project.context` (short, factual background block; OK if empty-ish for greenfield)
     - `project.key_decisions[]` objects: `decision`, `rationale`, `outcome` (pending|good|revisit), `date` (YYYY-MM-DD)
     - `project.assumptions[]` and `project.open_questions[]`
   - REQUIREMENTS inputs including:
     - v1 requirements list with stable IDs in `CAT-##` form (uppercase CAT, 2 digits)
     - each v1 item must include `category`, `text` (user-centric + testable), `phase` number, `status` (start as `pending`), and `acceptance[]` criteria with `type` in `DET|LLM`
     - v2 deferred requirements (optional)
     - out_of_scope items derived from non-goals (feature + reason)
     - coverage counts (`total_v1`, `mapped`, `unmapped`)
   - ROADMAP inputs including:
     - phases only (no tracks, no steps, no deliverables)
     - each phase has: `id`, `name`, `goal`, `depends_on`, `requirements` (REQ IDs), `success_criteria`, `estimated_tracks`, `status`
     - progress block (`total_phases`, `completed`, `current_phase`)
     - roadmap risks and definition_of_done
   - STATE.yaml init inputs:
     - at minimum: `project.name`, `project.core_value`, and total phases/current phase (so P2_F can initialize state)
     - (Do NOT introduce/require a separate STATE.md; STATE.yaml is the only state file.)
3) Keep the original “ask for confirmation after each block” behavior, but now do it per major block (VISION / PROJECT / REQUIREMENTS / ROADMAP). It’s OK to keep “Guidance” bullets, but update them to the new structure and templates.
4) Keep phrasing crisp and facilitator-oriented (this is a prompt for the P2 human-led session).

Constraints:
- Edit ONLY `.pipe/p2/P2_E.md`.
- Do not add new files.
- Do not change other P2 prompts here (that’s T05/T06).

Done-when checklist:
- [ ] `.pipe/p2/P2_E.md` explicitly says it crystallizes data for all 5 outputs (VISION/PROJECT/REQUIREMENTS/ROADMAP/STATE.yaml init).
- [ ] It references the 3 template paths above.
- [ ] It instructs the facilitator to produce PROJECT core_value/constraints/key_decisions aligned to `P2_PROJECT_TEMPLATE.md`.
- [ ] It instructs the facilitator to produce REQUIREMENTS with stable IDs + DET/LLM acceptance criteria aligned to `P2_REQUIREMENTS_TEMPLATE.md`.
- [ ] It instructs the facilitator to produce ROADMAP phases (no tracks) aligned to `P2_ROADMAP_TEMPLATE.md`.
- [ ] It keeps the “confirm after each block” interaction pattern.

CURRENT FILE (`.pipe/p2/P2_E.md`) — edit this content surgically:
```md
# P2_E — Crystallize Statements

Synthesize and present each item for user approval/edits:
1) Vision Statement (1 paragraph): what this is and why it matters.
2) Success Truths (5-12): observable, verifiable outcomes.
3) Non-Goals (3-7): explicit exclusions.
4) Constraints: tech stack, timeline, team, budget, platform.
5) Key Risks (3-5): what could derail it + mitigation ideas.
6) Open Questions: unresolved items needing research.

Guidance:
- Success truths must be testable (machine or human reviewer).
- Non-goals must be specific, not vague.
- Examples:
  - Success truth BAD: "The tool is easy to use" -> GOOD: "A new user completes [core workflow] within 5 minutes without docs"
  - Non-goal BAD: "We won't support everything" -> GOOD: "We will not support Windows. Linux and macOS only."
- Keep phrasing crisp; ask for confirmation after each block.
```
````

## T05 — Update `/.pipe/p2/P2_F.md` (Output Writer)

````text
You are GPT-5.2-Codex inside the repo at `/tank/dump/DEV/deadfish-cli`.

Task: Update the P2 output-writer prompt so it writes 5 seed docs (not 2).

You must make surgical edits to this exact file:
- Modify: `.pipe/p2/P2_F.md`

New required outputs (all YAML in codefences, and NO extra prose outside codefences):
1) `VISION.md`
2) `PROJECT.md`
3) `REQUIREMENTS.md`
4) `ROADMAP.md`
5) `STATE.yaml` (initialization)

Reference templates for the new/changed formats (open these and align P2_F’s embedded schemas to them verbatim):
- `.pipe/p2/P2_PROJECT_TEMPLATE.md` (PROJECT.md schema)
- `.pipe/p2/P2_REQUIREMENTS_TEMPLATE.md` (REQUIREMENTS.md schema)
- `.pipe/p2/P2_ROADMAP_TEMPLATE.md` (ROADMAP.md schema; phases only)

Precise changes to make in `.pipe/p2/P2_F.md`:
1) Update the title/description to reflect 5 outputs, not “(VISION.md + ROADMAP.md)”.
2) Update the “If files exist…” overwrite/draft instruction to cover all 5 files (not just VISION/ROADMAP). Keep it simple: if ANY exist, ask once whether to overwrite or write new drafts.
3) Replace the old ROADMAP schema (tracks/deliverables/steps) with the new ROADMAP phases-only schema from `.pipe/p2/P2_ROADMAP_TEMPLATE.md`.
4) Add full schemas (as codefenced YAML) for:
   - PROJECT.md (use the exact schema from `.pipe/p2/P2_PROJECT_TEMPLATE.md`)
   - REQUIREMENTS.md (use the exact schema from `.pipe/p2/P2_REQUIREMENTS_TEMPLATE.md`)
   - STATE.yaml init (use the restructure plan’s init shape: includes `project.name`, `project.core_value`, `project.initialized_at`, and the existing orchestrator state fields like `phase`, `mode`, `roadmap.current_phase`, etc.)
5) Update line limits / token budgets to match the restructure plan intent:
   - VISION.md: <= 60–80 lines (keep small)
   - PROJECT.md: <= 80 lines
   - REQUIREMENTS.md: <= 120 lines
   - ROADMAP.md: <= 100 lines
   - STATE.yaml: <= 60 lines
6) Keep the final instruction: “Ask for approval and apply edits.”

Important semantic requirements:
- ROADMAP.md must be phases only (no tracks, no tasks, no deliverables lists).
- REQUIREMENTS.md must include stable IDs (`CAT-##`) and acceptance criteria typed `DET` or `LLM`.
- PROJECT.md constraints.type must be limited to `tech|timeline|budget|dependency|compatibility`.
- `STATE.yaml` should initialize `phase: "select-track"` (consistent with orchestrator expectations), with nulls/defaults for track/task fields.

Constraints:
- Edit ONLY `.pipe/p2/P2_F.md`.
- Do not add new files.

Done-when checklist:
- [ ] `.pipe/p2/P2_F.md` instructs output of 5 files (VISION/PROJECT/REQUIREMENTS/ROADMAP/STATE.yaml) as YAML-in-codefence with no extra prose.
- [ ] PROJECT/REQUIREMENTS/ROADMAP schemas match the referenced templates.
- [ ] ROADMAP schema is phases-only (no tracks/steps/deliverables).
- [ ] Includes a STATE.yaml init template with `project` header and orchestrator fields.
- [ ] Overwrite/draft prompt covers all 5 outputs.

CURRENT FILE (`.pipe/p2/P2_F.md`) — edit this content surgically:
```md
# P2_F — Seed Docs Writer (VISION.md + ROADMAP.md)

If VISION.md or ROADMAP.md already exist, ask whether to overwrite or create a new draft before writing.

Output two codefenced YAML documents (no extra prose) with line limits:

VISION.md (<= 80 lines):
```yaml
vision_yaml<=300t:
  problem:
    why: "<why this needs to exist>"
    pain: ["<pain point 1>", "<pain point 2>"]
  solution:
    what: "<one-sentence pitch>"
    boundaries: "<explicit scope limits>"
  users:
    primary: "<target user>"
    environments: ["<env1>", "<env2>"]
  key_differentiators:
    - "<differentiator 1>"
    - "<differentiator 2>"
  mvp_scope:
    in:
      - "<in-scope item>"
    out:
      - "<explicitly excluded>"
  success_metrics:
    - "<observable, verifiable metric>"
  non_goals:
    - "<specific non-goal>"
  assumptions:
    - "<assumption>"
  open_questions:
    - "<unresolved question>"
```

ROADMAP.md (<= 120 lines):
```yaml
version: "<version>"
project: "<project name>"
goal: "<strategic goal>"
tracks:
  - id: 1
    name: "<track name>"
    goal: "<1-2 sentence goal>"
    deliverables:
      - "<artifact or capability>"
    done_when:
      - "<observable, testable condition>"
    dependencies: []
    risks: []
milestones:
  - "<milestone description>"
risks:
  - "<project-level risk>"
definition_of_done:
  - "<overall completion criteria>"
```

Ask for approval and apply edits.
```
````

## T06 — Update `/.pipe/p2/P2_MAIN.md` (Main Flow)

````text
You are GPT-5.2-Codex inside the repo at `/tank/dump/DEV/deadfish-cli`.

Task: Update the P2 main brainstorm-session flow prompt to reflect the new P2 outputs and updated crystallize/output phases.

You must make surgical edits to this exact file:
- Modify: `.pipe/p2/P2_MAIN.md`

What changed (must reflect in P2_MAIN):
- P2 now produces 5 docs: `VISION.md`, `PROJECT.md`, `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.yaml` (plus the brainstorm ledger at `.deadf/seed/P2_BRAINSTORM.md`).
- Phase 5 (Crystallize) must match the expanded P2_E responsibilities (core value, decisions, requirements IDs, roadmap phases).
- Phase 6 (Output) must write all 5 docs via P2_F (not just VISION/ROADMAP).
- Phase 7 (Adversarial Review) must review consistency across ALL 5 docs (not just 2).

Reference template paths (P2_MAIN should point the facilitator at these during the relevant phases, so the facilitator’s mental model matches the target formats):
- `.pipe/p2/P2_PROJECT_TEMPLATE.md`
- `.pipe/p2/P2_REQUIREMENTS_TEMPLATE.md`
- `.pipe/p2/P2_ROADMAP_TEMPLATE.md`

Precise changes to make in `.pipe/p2/P2_MAIN.md`:
1) Update the first paragraph (“yields VISION.md, ROADMAP.md…”) to list all 5 docs + the ledger.
2) Update “Quick Mode Trigger” inputs so the facilitator collects enough information to generate:
   - core value (must-work statement)
   - key decisions (at least 1–3)
   - enough must-haves to become categorized v1 requirements (with IDs + acceptance)
   - strategic phases (even rough; can be finalized in crystallize)
   Keep it short; don’t overcomplicate quick mode, but make it sufficient for the 5-doc output.
3) Update Phase 5 description to explicitly mention crystallizing structured blocks for VISION/PROJECT/REQUIREMENTS/ROADMAP (and state init inputs), using P2_E.
4) Update Phase 6 description to “Write VISION.md, PROJECT.md, REQUIREMENTS.md, ROADMAP.md, STATE.yaml…” using P2_F.
5) Update Phase 7 description to require 5–15 issues across ALL 5 docs (cross-doc consistency checks). Don’t change the “Looks good is not allowed” rule.
6) Keep everything else (voice, non-negotiables, anti-bias protocols, phase ordering) intact unless strictly necessary.

Constraints:
- Edit ONLY `.pipe/p2/P2_MAIN.md`.
- Do not add new files.

Done-when checklist:
- [ ] P2_MAIN states the output set is 5 docs + the brainstorm ledger.
- [ ] Phase 5 references the expanded crystallize responsibilities (core_value/decisions/requirements IDs/roadmap phases).
- [ ] Phase 6 outputs 5 docs via P2_F.
- [ ] Phase 7 adversarial review covers all 5 docs.
- [ ] Quick Mode collects enough inputs to support the new outputs.

CURRENT FILE (`.pipe/p2/P2_MAIN.md`) — edit this content surgically:
```md
# P2_MAIN — Brainstorm Session Core Prompt

You are GPT-5.2, the P2 Brainstorm Session facilitator for deadf(ish). Your role is to guide a structured, human-led ideation process that yields VISION.md, ROADMAP.md, and a raw ledger at .deadf/seed/P2_BRAINSTORM.md.

Voice: warm, concise, curious. You are a facilitator, not a generator.

## Non-Negotiables
- Ask probing questions; do not dump idea lists. Exceptions: Phase 6 (output synthesis) and Phase 7 (adversarial review).
- Stay in generative mode as long as possible; do not organize until the user asks OR 50+ ideas captured OR energy clearly dropping (offer one last divergent burst first).
- Force a domain pivot every ~10 ideas; track domains explored.
- Quantity over quality. Push beyond the first 20 obvious ideas.
- After 30+ ideas: persist full ledger to .deadf/seed/P2_BRAINSTORM.md; in chat, show only count, last 5 IDs, current lens, and next pivot domain.
- Success metrics must be observable and verifiable.

## Active Anti-Bias Protocols
1) Anti-anchoring — do not lead with suggestions; ask open questions.
2) Anti-premature-convergence — when the human narrows: "What other angles haven't we explored?"
3) Anti-recency — periodically reference early ideas: "Earlier you mentioned [X] — how does that connect?"
4) Anti-sycophancy — probe weak ideas: "Tell me more — what makes this different from [similar]?"
5) Anti-domain-fixation — track explored domains and force shifts via protocol.
6) Anti-feasibility-bias — include at least one "impossible" round, then back-solve.

## Quick Mode Trigger
If the user says: "I already know what I want to build," skip Phases 2-4 and ask for:
- 2-3 sentence description
- 3-5 must-haves
- non-goals
- constraints
Then jump to Phase 6, then Phase 7.

## Phase Flow
SETUP → TECHNIQUE SELECT → IDEATE → ORGANIZE → CRYSTALLIZE → OUTPUT → ADVERSARIAL REVIEW

### Phase 1: SETUP (2-3 exchanges)
Ask the five setup questions:
1) What are we building? Elevator pitch — even rough is fine.
2) Who needs this? Primary user.
3) What's the pain? Why does this need to exist now?
4) Any constraints? (time, money, tech, legal, platform)
5) What does success look like in 90 days? 3-7 measurable outcomes.

Confirm with a one-sentence pitch and get explicit "yes" before proceeding.

Initialize internal state:
- project_name, one_sentence_pitch, target_user, constraints, success_metrics
- idea_count = 0, current_lens = null, lenses_used = []

### Phase 2: TECHNIQUE SELECT
Use P2_A (and P2_A2 only if user-selected mode).

### Phase 3: IDEATE
Use rounds (5-10 ideas per round). Rotate 3-5 techniques across the session. Spend 5-8 exchanges per technique before rotating. Trigger domain pivot every ~10 ideas using P2_B. Use P2_C for capture + ledger hygiene. Run scheduled anti-bias interrupts at ~20/40/60/80 ideas:
- ~20 ideas: Force opposites — Reverse Brainstorm ("How could we make this fail?")
- ~40 ideas: Force analogies — Cross-Pollination / Biomimetic ("What would Stripe/Docker/nature do?")
- ~60 ideas: Force constraints — Constraint Injection ("What if 10x fewer resources?")
- ~80 ideas: Force black swans — Failure Analysis ("How could this be abused? What regulation could kill it?")

Energy checkpoint every 4-5 exchanges:
"We’ve got [N] ideas — solid momentum! Keep pushing this angle, switch technique, or ready to start organizing?"
Default: keep exploring unless the user asks to organize.

When stuck: offer 3-5 lenses, or a simple template, or (only if opted in) 2 example seeds.

### Phase 4: ORGANIZE
Gate entry: user asks OR 50+ ideas and energy dropping. Use P2_D.

### Phase 5: CRYSTALLIZE
Synthesize vision statement, success truths, non-goals, constraints, risks, open questions. Use P2_E.

### Phase 6: OUTPUT
Write VISION.md and ROADMAP.md in YAML-in-codefence format. Use P2_F.

### Phase 7: ADVERSARIAL REVIEW
Find 5-15 issues ("Looks good" is not allowed). Use P2_G.
```
````

