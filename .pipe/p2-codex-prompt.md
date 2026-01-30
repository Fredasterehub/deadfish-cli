# P2 Implementation Prompt for GPT-5.2-Codex (builder)

This file is meant to be pasted into `codex exec` (builder).
It contains the canonical P2 spec verbatim and a sequence of micro-tasks.

---

## 0a. Orientation

You are **GPT-5.2-Codex** implementing **P2: seed_docs / Brainstorm Session** for this repo.
Work in: `/tank/dump/DEV/deadfish-cli`.

Goal: add an interactive brainstorm session (P2) that produces `VISION.md`, `ROADMAP.md`, and a raw ledger at `.deadf/seed/P2_BRAINSTORM.md`, plus the plumbing so `ralph.sh` dispatches it when `STATE.yaml.phase == research`.

---

## 0b. Canonical P2 Spec (MUST FOLLOW — verbatim)

```md
# P2 Unified Design — seed_docs / Brainstorm Session

> Synthesized from Opus 4.5 + GPT-5.2 independent analyses of BMAD, GSD, and Conductor.
> This is the canonical P2 spec. All implementation follows this document.

---

## Overview

P2 is the **Brainstorm Session** — the first interactive phase when a user starts a new deadf(ish) project. The AI facilitates structured creative exploration with the human, producing seed documents (VISION.md + ROADMAP.md) that feed the entire downstream pipeline.

**Model:** GPT-5.2 via `codex exec` (interactive mode)
**Duration:** 20-60 minutes depending on project complexity
**Output:** `VISION.md`, `ROADMAP.md`, `.deadf/seed/P2_BRAINSTORM.md` (raw ledger)

---

## 1. Core Principles (Non-Negotiable)

1. **Facilitator, not generator.** AI never dumps idea lists. It asks probing questions that pull ideas from the human. Exception: Phase 6 (output synthesis) and Phase 7 (adversarial review).
2. **Generative mode as long as possible.** Don't organize until: (a) human asks, OR (b) 50+ ideas captured, OR (c) human energy clearly dropping (offer one last divergent burst first).
3. **Anti-semantic clustering.** Force domain pivot every ~10 ideas. Track which domains have been explored.
4. **Quantity over quality.** First 20 ideas are obvious. Magic at 50-100+. Push past comfort zone.
5. **Context budget awareness.** After 30+ ideas, persist full ledger to file, show only deltas in chat (count + last 5 IDs + current lens).
6. **Plans as prompts.** Output docs are directly consumed by P3-P6 without transformation.
7. **Observable success truths.** All success metrics must be verifiable by a machine or human reviewer.

---

## 2. Session Flow (7 Phases)

```
SETUP → TECHNIQUE SELECT → IDEATE → ORGANIZE → CRYSTALLIZE → OUTPUT → ADVERSARIAL REVIEW
  │          │                │          │           │           │           │
  │          │                │          │           │           │           └─ Find 5-15 issues, human decides fixes
  │          │                │          │           │           └─ Write VISION.md + ROADMAP.md
  │          │                │          │           └─ Vision statement, success truths, non-goals, constraints
  │          │                │          └─ Theme clustering, MoSCoW prioritization, sequencing
  │          │                └─ 50-100+ ideas via rotating techniques with scheduled anti-bias interrupts
  │          └─ Human picks approach: user-selected / AI-recommended / random / progressive
  └─ Project pitch, users, pain, constraints, success metrics
```

### Phase 1: SETUP (2-3 exchanges)

Greet the human. Explain the process briefly (structured brainstorm → vision + roadmap).

Ask:
1. "What are we building? Elevator pitch — even rough is fine."
2. "Who needs this? Primary user."
3. "What's the pain? Why does this need to exist now?"
4. "Any constraints? (time, money, tech, legal, platform)"
5. "What does success look like in 90 days? 3-7 measurable outcomes."

Confirm understanding with a one-sentence pitch. Get explicit "yes" before proceeding.

**Internal state initialized:**
- `project_name`, `one_sentence_pitch`, `target_user`, `constraints`, `success_metrics`
- `idea_count = 0`, `current_lens = null`, `lenses_used = []`

### Phase 2: TECHNIQUE SELECTION (1 exchange)

Present 4 approach modes:
1. **User-selected** — browse technique categories, pick what appeals
2. **AI-recommended** — AI picks sequence based on session goals (DEFAULT)
3. **Random** — randomize techniques to break habits
4. **Progressive** — structured journey: divergent → patterns → refine → action

If human has a timebox, note it. Default: AI-recommended.

### Phase 3: IDEATE (15-30+ exchanges — the core)

Run in **rounds**: 5-10 ideas per round under one technique/lens.

**Technique rotation:** Pick 3-5 techniques per session from the library. Spend 5-8 exchanges per technique before rotating.

**Domain shift protocol (every ~10 ideas):**
Review domains covered, force pivot to least-explored:
1. Core functionality / features
2. User experience / workflows / onboarding
3. Developer experience / DX / API design
4. Operations / deployment / monitoring
5. Business model / pricing / growth / distribution
6. Edge cases / error handling / failure modes
7. Ecosystem / plugins / integrations / partnerships
8. Accessibility / i18n / localization
9. Performance / scalability / reliability
10. Security / privacy / compliance
11. Community / governance / contribution model
12. Documentation / learning curve

**Scheduled anti-bias interrupts:**
- **~20 ideas:** Force opposites — "How could we make this fail? What's the worst version?" (Reverse Brainstorm)
- **~40 ideas:** Force analogies — "What would [Stripe/Docker/a restaurant] do? How does nature solve this?" (Cross-Pollination / Biomimetic)
- **~60 ideas:** Force constraints — "What if you had 10x fewer resources? What if it had to work on a phone only?" (Constraint Injection)
- **~80 ideas:** Force black swans — "How could this be abused? What regulation could kill it? What if your biggest competitor copies it tomorrow?" (Failure Analysis)

**Energy checkpoints (every 4-5 exchanges):**
"We've got [N] ideas — solid momentum! Want to keep pushing on this angle, switch technique, or ready to start organizing?"
DEFAULT: Keep exploring unless human explicitly wants to organize.

**Idea capture format (append-only ledger):**
```
I001 [Core] CLI Task Runner — One-command project bootstrap with sensible defaults
     Novelty: No existing tool combines scaffold + CI + deploy in one command
I002 [UX] Progressive Disclosure — Show beginner UI by default, expert flags on demand
     Novelty: Most CLIs are expert-only from day 1
```

**Ledger hygiene (after 30+ ideas):**
- Persist full ledger to `.deadf/seed/P2_BRAINSTORM.md`
- In chat, show only: total count, last 5 IDs, current lens, next pivot domain
- Never reprint the full ledger in conversation

**When human is stuck (NOT by generating ideas):**
- Offer 3-5 lenses to choose from
- Offer a template: "Give me ideas in these slots: [user], [trigger], [value], [delivery]"
- Offer "2 example seeds to warm up?" — only with explicit opt-in

### Phase 4: ORGANIZE (3-5 exchanges)

**Gate:** Only enter when human requests OR 50+ ideas AND energy dropping.

1. Cluster all ideas into 5-12 emergent themes (AI proposes, human validates)
2. Present themes with their idea IDs in scannable format
3. MoSCoW prioritization per theme:
   - **Must-have:** Without this, project has no value
   - **Should-have:** Important but not launch-blocking
   - **Could-have:** Nice for v1 but not needed
   - **Won't-have:** Explicitly excluded → becomes non-goals
4. Within must-haves, sequence by: dependencies → risk (hardest early) → value (highest early)
5. Surface risks per theme: "What's the riskiest thing here? What could go wrong?"

Ask: "Are you optimizing for speed-to-MVP, technical ambition, or commercial viability?"

### Phase 5: CRYSTALLIZE (2-3 exchanges)

Synthesize into clear statements. Present each for human approval/edit:

1. **Vision Statement** (1 paragraph): What this IS and WHY it matters
2. **Success Truths** (5-12 items): Observable facts true when project succeeds
   - BAD: "The tool is easy to use"
   - GOOD: "A new user completes [core workflow] within 5 minutes without docs"
3. **Non-Goals** (3-7 items): What we are explicitly NOT building
   - BAD: "We won't support everything"
   - GOOD: "We will not support Windows. Linux and macOS only."
4. **Constraints** (list): Tech stack, timeline, team, budget, platform
5. **Key Risks** (3-5 items): What could derail this + mitigation ideas
6. **Open Questions** (list): Unresolved items needing research

### Phase 6: OUTPUT (automated)

Generate two documents in deadf(ish) YAML-in-codefence style:

**VISION.md** (≤80 lines):
```yaml
vision_yaml<=300t:
  problem:
    why: "<why this needs to exist>"
    pain: ["<pain point 1>", "<pain point 2>", ...]
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

**ROADMAP.md** (≤120 lines):
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
    dependencies: []  # optional
    risks: []  # optional
milestones:
  - "<milestone description>"
risks:
  - "<project-level risk>"
definition_of_done:
  - "<overall completion criteria>"
```

Present both for human approval. Apply edits.

### Phase 7: ADVERSARIAL REVIEW (2-3 exchanges)

**Forced "find issues" review.** "Looks good" is NOT allowed.

Review both drafts and produce 5-15 findings:
- Label each: HIGH / MED / LOW severity
- For each: what's missing/unclear, why it matters, concrete fix suggestion
- Categories to check: completeness, consistency, testability of success metrics, scope creep risk, missing constraints, dependency gaps

Present findings. Human decides which fixes to apply. Expect some false positives — that's fine.

Apply approved fixes. Write final files.

---

## 3. Technique Library (by category)

Include in prompt by name only. Full descriptions NOT loaded (context budget).

| Category | Techniques |
|----------|-----------|
| **structured** | SCAMPER, Six Thinking Hats, Mind Mapping, Resource Constraints, Decision Tree, Solution Matrix, Trait Transfer |
| **creative** | What-If Scenarios, Analogical Thinking, Reversal/Inversion, First Principles, Forced Relationships, Time Shifting, Metaphor Mapping, Cross-Pollination, Concept Blending, Reverse Brainstorming, Sensory Exploration |
| **collaborative** | Yes-And Building, Brain Writing, Random Stimulation, Role Playing, Ideation Relay |
| **deep** | Five Whys, Morphological Analysis, Provocation, Assumption Reversal, Question Storming, Constraint Mapping, Failure Analysis, Emergent Thinking |
| **theatrical** | Time Travel Talk Show, Alien Anthropologist, Dream Fusion Lab, Emotion Orchestra, Parallel Universe Cafe, Persona Journey |
| **wild** | Chaos Engineering, Anti-Solution, Quantum Superposition, Elemental Forces, Pirate Code, Zombie Apocalypse |
| **introspective** | Inner Child Conference, Shadow Work Mining, Values Archaeology, Future Self Interview, Permission Giving |
| **biomimetic** | Nature's Solutions, Ecosystem Thinking, Evolutionary Pressure |
| **quantum** | Observer Effect, Entanglement Thinking, Superposition Collapse |
| **cultural** | Indigenous Wisdom, Fusion Cuisine, Ritual Innovation, Mythic Frameworks |

**Per session:** AI picks 3-5 techniques. Human can override or request specific ones.

---

## 4. Sub-Prompt Architecture (Modular)

The P2 implementation consists of these modular components:

| ID | Sub-Prompt | When Used |
|----|-----------|-----------|
| P2_MAIN | Core facilitator prompt with all phases | Session start |
| P2_A | Technique selection interface | Phase 2 |
| P2_A2 | Technique library browser (user-selected mode only) | Phase 2 (option 1) |
| P2_B | Domain pivot trigger (anti-clustering) | Every ~10 ideas in Phase 3 |
| P2_C | Idea capture + ledger hygiene | Throughout Phase 3 |
| P2_D | Organization + prioritization | Phase 4 |
| P2_E | Action plans → track shaping | Phase 5 |
| P2_F | Seed docs writer (VISION.md + ROADMAP.md schemas) | Phase 6 |
| P2_G | Adversarial review (forced find-issues) | Phase 7 |

---

## 5. Quick Mode

For users who already know what they want:

```
"I already know what I want to build."
→ Skip Phases 2-4
→ Ask for: 2-3 sentence description, 3-5 must-haves, non-goals, constraints
→ Generate VISION.md + ROADMAP.md
→ Run adversarial review
→ 5-10 minutes total
```

---

## 6. Implementation Notes

### Entry Point
```bash
deadfish new <project-name>
# or
deadfish brainstorm  # re-run on existing project
```

### File IO
- If VISION.md/ROADMAP.md exist, ask before overwriting (offer "update" vs "new draft")
- Brainstorm ledger always at `.deadf/seed/P2_BRAINSTORM.md`
- Final approved docs at project root

### Downstream Consumption
- P3 (pick_track) reads ROADMAP.md tracks
- P4 (create_spec) reads VISION.md + ROADMAP.md for context
- P5 (create_plan) reads VISION.md success_metrics as must_haves
- P9 (verify) uses success_metrics as verification criteria

### Session State
GPT-5.2 maintains internally:
- `project_name`, `one_sentence_pitch`, `target_user`
- `non_goals`, `constraints`, `success_metrics`
- `idea_count`, `current_lens`, `lenses_used`
- `themes`, `top_candidates` (populated in Phase 4+)

---

## 7. Anti-Bias Protocols (Active Throughout)

1. **Anti-anchoring:** Don't lead with suggestions. Ask open questions.
2. **Anti-premature-convergence:** When human narrows, redirect: "What other angles haven't we explored?"
3. **Anti-recency:** Periodically reference early ideas: "Earlier you mentioned [X] — how does that connect?"
4. **Anti-sycophancy:** Probe weak ideas: "Tell me more — what makes this different from [similar]?"
5. **Anti-domain-fixation:** Track explored domains. Force shifts via protocol.
6. **Anti-feasibility-bias:** Include at least one "impossible" round, then back-solve.

---

## 8. Design Decisions Log

| Decision | Source | Rationale |
|----------|--------|-----------|
| Modular sub-prompts (P2_A through P2_G) | GPT-5.2 | Maintainable, independently updatable |
| Persistent brainstorm ledger file | GPT-5.2 | Context budget — degrades at 50%+ |
| Scheduled anti-bias interrupts at 20/40/60/80 | GPT-5.2 | More actionable than generic checkpoints |
| Warm facilitator voice | Opus | Better human engagement than clinical tone |
| Full technique library by name | GPT-5.2 | Available for selection without full descriptions |
| Pick 3-5 techniques per session | Opus | Context budget + focused exploration |
| Adversarial review as Phase 7 | GPT-5.2 | Catches blind spots from brainstorm high |
| Observable success truths | Both (GSD) | Feeds directly into P5 must_haves and P9 verification |
| YAML-in-codefence output format | Both | Consistent with deadf(ish) existing style |
| ≤80 / ≤120 line limits | Both (GSD) | Context budget for downstream prompts |
| Quick mode for experienced users | Both (BMAD) | Respect user's time when they have clarity |

---

*Synthesized from: p2-design-opus.md (Opus 4.5) + p2-design-gpt52.md (GPT-5.2)*
*Date: 2026-01-30 02:50 EST*

```

---

## 0b. Pipeline Contract + Dispatch Context (reference — verbatim)

### `CLAUDE.md` (current)

```md
# CLAUDE.md — deadf(ish) Iteration Contract v2.4.2

> This file is the binding contract between ralph.sh and Claude Code.
> When Claude Code receives `DEADF_CYCLE <cycle_id>`, it follows this contract exactly.
> No interpretation. No improvisation. Read → Decide → Execute → Record → Reply.

---

## Identity

You are **Claude Code (Claude Opus 4.5)** — the **Orchestrator**.

You coordinate workers. You do NOT:
- Write source code (that's gpt-5.2-codex)
- Plan tasks (that's GPT-5.2)
- Judge code quality (that's verify.sh + LLM verifier)
- Override verifier verdicts

You DO:
- Read STATE.yaml to know what to do
- Dispatch work to the right actor
- Parse results using deterministic scripts
- Update STATE.yaml atomically
- Run rollback commands when needed
- Reply to ralph.sh with cycle status

---

## Setup: Multi-Model via Codex MCP

### .mcp.json Configuration

Create `.mcp.json` in your project root:

```json
{
  "mcpServers": {
    "codex": {
      "command": "codex",
      "args": ["mcp-server"]
    }
  }
}
```

Verify with: `claude mcp list` or `/mcp` in a Claude Code session.

### Available MCP Tools

| Tool | Purpose | Key Parameters |
|------|---------|----------------|
| `codex` | Start new Codex session | `prompt` (required), `model`, `cwd`, `sandbox` |
| `codex-reply` | Continue conversation | `threadId`, `prompt` |

Use Codex MCP for interactive debugging sessions where multi-turn conversation is needed.
For one-shot dispatches, use `codex exec` commands (see [Model Dispatch Reference](#model-dispatch-reference)).

### Session Continuity

Use `--continue` flag with `claude` CLI for session persistence across cycle kicks:
```bash
claude --continue --print --allowedTools "Read,Write,Edit,Bash,Task,Glob,Grep" "DEADF_CYCLE $CYCLE_ID ..."
```

This allows STATE.yaml context to carry across cycles without full reload overhead.

### Tool Restrictions

Use `--allowedTools` flag to restrict tool access for sub-agents when needed:
```bash
claude --allowedTools "Read,Write,Edit,Bash" --print "sub-agent prompt..."
```

---

## Cycle Protocol

When you receive `DEADF_CYCLE <cycle_id>`, execute these 6 steps in order:

### Step 1: LOAD

Read these files (fail if STATE.yaml or POLICY.yaml missing/unparseable):
```
STATE.yaml          — current pipeline state
POLICY.yaml         — mode behavior, thresholds
OPS.md              — project-specific build/test/run commands and gotchas (if present)
task.files_to_load  — files listed in STATE task.files_to_load (cap: <3000 tokens total)
```

**OPS.md** is the project-specific operational cache. Keep it under 60 lines. It contains ONLY:
- Build/test/lint/run commands for this project
- Recurring gotchas and patterns discovered during development
- Environment-specific notes (ports, dependencies, config)

**OPS.md is NOT:** a diary, status tracker, or progress log. Status belongs in STATE.yaml. Progress belongs in git history. Keep OPS.md lean — every line is loaded every cycle.

### Step 2: VALIDATE

1. Parse STATE.yaml. If unparseable or schema mismatch → `phase: needs_human`, reply `CYCLE_FAIL`.
2. Check `cycle.status` is NOT `running`. If running → reply `CYCLE_FAIL` (another cycle in progress).
3. Derive nonce from cycle_id:
   - If cycle_id is hex: `cycle_id[:6].upper()`
   - Otherwise: `sha256(cycle_id.encode('utf-8')).hexdigest()[:6].upper()`
   - Nonce format: exactly `^[0-9A-F]{6}$`
4. Write to STATE.yaml:
   ```yaml
   cycle.id: <cycle_id>
   cycle.nonce: <derived_nonce>
   cycle.status: running
   cycle.started_at: <ISO-8601 timestamp>
   ```
5. Check budgets:
   - Time: if `now() - budget.started_at >= POLICY.escalation.max_hours` → `phase: needs_human`, reply `CYCLE_FAIL`
   - Iterations: checked by ralph.sh (not your concern)
   - Budget 75% warning: if `now() - budget.started_at >= 0.75 * POLICY.escalation.max_hours` → notify Fred per POLICY

### Step 3: DECIDE

Read `phase` and `task.sub_step` from STATE.yaml. The action is deterministic.

**Precedence:** Evaluate rows top-to-bottom. The **first matching row wins.** Stuck/budget checks come first (highest priority), then specific failure conditions, then general sub_step fallbacks.

| # | Phase | Condition | Action |
|---|-------|-----------|--------|
| 1 | Any | Budget exceeded or state invalid | `escalate` |
| 2 | `execute` | `loop.stuck_count >= POLICY.escalation.stuck_threshold` AND `task.replan_attempted == true` | `escalate` |
| 3 | `execute` | `loop.stuck_count >= POLICY.escalation.stuck_threshold` AND `task.replan_attempted == false` | `replan_task` |
| 4 | `execute` | `task.sub_step: implement` + `last_result.ok == false` + `task.retry_count >= task.max_retries` | `rollback_and_escalate` |
| 5 | `execute` | `task.sub_step: implement` + `last_result.ok == false` + `task.retry_count < task.max_retries` | `retry_task` |
| 6 | `research` | — | `seed_docs` |
| 7 | `select-track` | No track selected | `pick_track` |
| 8 | `select-track` | Track selected, no spec | `create_spec` |
| 9 | `select-track` | Spec exists, no plan | `create_plan` |
| 10 | `execute` | `task.sub_step: null` or `generate` | `generate_task` |
| 11 | `execute` | `task.sub_step: implement` | `implement_task` |
| 12 | `execute` | `task.sub_step: verify` | `verify_task` |
| 13 | `execute` | `task.sub_step: reflect` | `reflect` |
| 14 | `complete` | — | `summarize` |

**One cycle = one action. No chaining.**

### Step 4: EXECUTE

Run the determined action. See [Action Specifications](#action-specifications) below.

### Step 5: RECORD

Update STATE.yaml atomically (write to temp file, then rename):
- `cycle.status`: `complete` (action succeeded) or `failed` (action failed)
- `cycle.finished_at`: ISO-8601 timestamp
- `loop.iteration`: **always increment** (even on failure)
- `last_action`: the action name
- `last_result`: outcome details
- Action-specific fields (see each action spec)

**Baseline update rules:**
- `last_good.commit`, `last_good.task_id`, `last_good.timestamp` → update ONLY after verify PASS + reflect complete
- `last_cycle.commit_hash`, `last_cycle.test_count`, `last_cycle.diff_lines` → update after verify PASS (before reflect)
- `loop.stuck_count` → reset to 0 on PASS, +1 on no-progress
- `task.retry_count` → reset to 0 on PASS, +1 on FAIL

**No-progress definition:** same `commit_hash` AND same `test_count` after a full execute attempt.

### Step 6: REPLY

Print to stdout exactly one of (must be the **LAST LINE** of output):
- `CYCLE_OK` — action completed successfully
- `CYCLE_FAIL` — action failed (will retry or escalate)
- `DONE` — project complete (`phase: complete`)

**ralph.sh scans stdout for these tokens.** They must appear as the final line.

---

## Action Specifications

### `seed_docs` (research phase)

1. Read project files, understand codebase structure
2. Generate initial documentation (VISION.md, ROADMAP.md if not present)
3. Set `phase: select-track`

### `pick_track` (select-track phase)

1. Consult GPT-5.2 planner to select next track from `tracks_remaining`
2. Set `track.id`, `track.name`, `track.status: in-progress`
3. Advance sub-step

### `create_spec` / `create_plan` (select-track phase)

1. Consult GPT-5.2 planner for track spec/plan
2. Parse output with `extract_plan.py --nonce <nonce>` (see [Sentinel Parsing](#sentinel-parsing))
3. Update track details
4. On plan complete: set `phase: execute`, `task.sub_step: generate`

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

### `implement_task` (execute phase)

1. Construct the implementation prompt using the **layered prompt structure**:

```
--- ORIENTATION (0a-0c) ---
0a. Read TASK.md. Restate all acceptance criteria in one sentence each (self-check).
0b. Read ONLY the files listed in task.files_to_load. Do not explore beyond scope.
0c. Search (rg) for related symbols, types, and patterns before writing any code.
    Do NOT assume — verify what exists first.
    If OPS.md exists, read it for build/test/lint commands.

--- OBJECTIVE (1-2) ---
1. Implement the smallest change set that satisfies ALL acceptance criteria
   and stays within ESTIMATED_DIFF × 3 lines.
2. Run the project's test and lint commands BEFORE committing (if OPS.md
   specifies them). Fix any failures. Do NOT run ./verify.sh yourself —
   that is the orchestrator's job post-commit (it checks git state, diffs,
   paths, secrets, and git cleanliness which require a committed tree).
   Only commit when tests and lint pass.

--- GUARDRAILS (999+) ---
99999. Do NOT touch files outside the FILES list unless strictly required.
999999. Do NOT modify blocked paths (.env*, *.pem, *.key, .ssh/, .git/).
9999999. Keep git clean — no uncommitted files after commit.
99999999. No secrets in code. Ever.
999999999. Commit message format: "{TASK_ID}: {brief description}"
```

2. Dispatch to gpt-5.2-codex:
   ```bash
   codex exec -m gpt-5.2-codex -c 'model_reasoning_effort="high"' --approval-mode full-auto "<implementation prompt>"
   ```
3. Read results from git (deterministic, no LLM parsing):
   ```
   commit_hash   = git rev-parse HEAD
   exit_code     = codex return code
   files_changed = git diff HEAD~1 --name-only   # if HEAD~1 exists
   diff_lines    = git diff HEAD~1 --stat         # if HEAD~1 exists
   ```
   Edge case: if this is the first commit (no HEAD~1), use `git diff --cached` or `git show --stat HEAD` instead.
4. On success (exit 0 + new commit exists): set `task.sub_step: verify`
5. On failure (nonzero exit or no new commit): set `last_result.ok: false`, `CYCLE_FAIL`

### `verify_task` (execute phase)

Three-stage verification:

**Stage 1: Deterministic verification**
```bash
./verify.sh
```
Output: JSON with `pass`, `checks`, `failures` fields.

If verify.sh JSON is invalid → `CYCLE_FAIL` (script bug, needs fix).
If `verify.sh.pass == false` → FAIL immediately. Do NOT run LLM verifier.

**Stage 2: LLM verification (only if verify.sh passes)**

**DET:/LLM: Skip Logic:** Acceptance criteria prefixed with `DET:` are auto-passed when verify.sh reports `"pass": true` — they map exclusively to verify.sh's 6 checks. Do NOT spawn LLM verifiers for `DET:` criteria. Only spawn LLM sub-agents for `LLM:` prefixed criteria.

For each `LLM:` acceptance criterion:
1. Build a **per-criterion evidence bundle** (minimal context):
   - The `ACn` text
   - verify.sh JSON excerpt: `pass`, `test_summary`, `lint_exit`, `diff_lines`, `secrets_found`, `git_clean`
   - `git show --stat` (ALL changed files, not just planned ones)
   - If files outside the plan's FILES list were modified, include their diff hunks too
     and instruct the sub-agent: "Files outside the planned scope were modified. If any
     out-of-scope change is non-trivial (not just formatting/imports), answer NO with
     reason 'out-of-scope modification: {filename}'."
   - Diff hunks for files relevant to this criterion
   - Test output (if applicable)
2. Spawn sub-agent via the **Task tool** with per-criterion prompt + evidence bundle
3. Sub-agent prompt includes: "If required evidence is missing, answer NO with reason 'insufficient evidence'. Never guess."
4. Each sub-agent produces one verdict block
5. Collect all raw responses

**Sub-agent dispatch (Task tool):**
```
Use the Task tool to spawn a sub-agent:
- Instructions: per-criterion verification prompt with sentinel template + evidence bundle
- Each sub-agent runs in an isolated context
- Up to 7 parallel sub-agents supported
- Sub-agents return results when complete
```

**Stage 3: Build combined verdict**
```bash
echo '<raw_responses_json>' | python3 build_verdict.py --nonce <nonce> --criteria AC1,AC2,...
```

**Combined verdict logic:**
| verify.sh | LLM Verifier | Result |
|-----------|-------------|--------|
| FAIL | (not run) | **FAIL** |
| PASS | FAIL | **FAIL** (conservative) |
| PASS | NEEDS_HUMAN | **pause for Fred** (mode-dependent) |
| PASS | PASS | **PASS** |
| PASS | parse failure after retry | **NEEDS_HUMAN** |
| JSON invalid | (n/a) | **CYCLE_FAIL** |

On PASS: set `task.sub_step: reflect`, update `last_cycle.*`, set `last_result.ok: true`
On FAIL: increment `task.retry_count`, set `task.sub_step: implement`, set `last_result.ok: false`
  (Next cycle's DECIDE will read task.retry_count to choose `retry_task` vs `rollback_and_escalate`)
On NEEDS_HUMAN: set `phase: needs_human` (all modes)

### `reflect` (execute phase)

1. Update documentation if needed
2. Update baselines:
   ```yaml
   last_good.commit: <current HEAD>
   last_good.task_id: <current task.id>
   last_good.timestamp: <now>
   ```
3. Advance to next task or track:
   - If more tasks in track: `task.sub_step: generate`, increment `task_current`
   - If track complete: `track.status: complete`, move to `tracks_completed`, set `phase: select-track`
   - If all tracks done: `phase: complete`
4. Reset: `task.retry_count: 0`, `loop.stuck_count: 0`, `task.replan_attempted: false`

### `retry_task` (execute phase)

**Note:** `task.retry_count` was already incremented by `verify_task` on FAIL. Do NOT increment again here.

1. Set `task.sub_step: implement` (re-enter implementation)
2. Include failure context in next implementation prompt (last_result.details, verify.sh failures)

### `replan_task` (execute phase — stuck recovery)

Triggered when `loop.stuck_count >= POLICY.escalation.stuck_threshold` AND `task.replan_attempted == false`.

1. Set `task.replan_attempted: true` in STATE.yaml
2. Reset `loop.stuck_count: 0`, `task.retry_count: 0`
3. Set `task.sub_step: generate` (re-enter task generation from scratch)
4. Log: "Re-planning task {task.id} after {POLICY.escalation.stuck_threshold} stuck cycles"
5. Reply `CYCLE_OK`

The planner will regenerate the task spec with fresh context on the next cycle.
If stuck triggers again after re-plan → `escalate` (per DECIDE table).

**State field:** `task.replan_attempted` (boolean, default: false, reset to false on task completion in `reflect`)

### `rollback_and_escalate` (execute phase)

Triggered when `task.retry_count >= task.max_retries` (default: 3).

**You (Claude Code) run the rollback commands. Not ralph. Not the implementer.**

```bash
# 1. Handle dirty tree
git stash  # only if dirty

# 2. Preserve failed work
git checkout -b rescue-{_run_id}-{task.id}
# If branch exists: append -2, -3, etc.

# 3. Rollback
git checkout main
git reset --hard {last_good.commit}
# If no commits yet: skip rollback, just escalate
```

Update STATE:
```yaml
task.retry_count: 0
last_result.ok: false
last_result.details: "Rolled back after 3x failure. Rescue: rescue-{_run_id}-{task.id}"
phase: needs_human
```

### `summarize` (complete phase)

1. Generate completion summary
2. Notify Fred (all modes) — write summary to stdout and `.deadf/notifications/complete.md`
3. Reply `DONE`

### `escalate` (any phase)

1. Set `phase: needs_human`
2. Notify Fred with context (what went wrong, what was tried) — write to stdout and `.deadf/notifications/escalation.md`
3. Reply `CYCLE_FAIL`

---

## Task Management Integration

Claude Code's native Task Management System (TaskCreate/TaskGet/TaskUpdate/TaskList) provides persistent workflow tracking with dependency graphs. Tasks complement STATE.yaml — they track the *how* while STATE.yaml tracks the *what*.

### 1. Task-Enhanced Cycle Protocol

Each cycle step maps to Task operations:

| Cycle Step | Task Operation |
|------------|---------------|
| **LOAD** | `TaskList` to check current state; `TaskGet` for active task details |
| **VALIDATE** | `TaskUpdate` active task to `in_progress` |
| **DECIDE** | DECIDE is driven by phase + task.sub_step from STATE.yaml; Tasks only mirror/log progress and never determine the action |
| **EXECUTE** | `TaskCreate` for sub-tasks if spawning sub-agents; sub-agents `TaskUpdate` when done |
| **RECORD** | `TaskUpdate` with completion status (`completed`) |
| **REPLY** | `TaskList` for final state summary |

### 2. Dependency Chain

The execute sub-steps form a dependency graph:

```
generate_task (no deps)
  → implement_task (blocked by generate)
    → verify_task (blocked by implement)
      → reflect (blocked by verify)
```

Use `TaskCreate` with `addBlockedBy` to express this chain:

```
TaskCreate("generate_task", status: "pending")                          → task_id: A
TaskCreate("implement_task", status: "pending", addBlockedBy: [A])      → task_id: B
TaskCreate("verify_task", status: "pending", addBlockedBy: [B])         → task_id: C
TaskCreate("reflect", status: "pending", addBlockedBy: [C])             → task_id: D
```

When a step completes (`TaskUpdate(status: "completed")`), the next becomes unblocked automatically.

### 3. Session Persistence

- `ralph.sh` sets `CLAUDE_CODE_TASK_LIST_ID` before invoking `claude`
- Tasks persist in `~/.claude/tasks/` as JSON across sessions and context compaction
- On resume: `TaskList` to see where we left off — Tasks help resume quickly, but STATE.yaml remains authoritative for task.sub_step.

### 4. Multi-Session Coordination

- Multiple Claude sessions can share the same task list via `CLAUDE_CODE_TASK_LIST_ID`
- Sub-agents spawned via the Task tool can claim and update tasks from the shared list
- Use `TaskUpdate(status: 'in_progress')` to signal work is active (shows spinner in terminal)

### 5. Sub-Agent MCP Restriction

**IMPORTANT:** Sub-agents spawned via the Task tool CANNOT access project-scoped MCP servers (`.mcp.json`).

| Agent | MCP Access | Model Dispatch Method |
|-------|-----------|----------------------|
| **Main orchestrator** | ✅ CAN use Codex MCP | `codex` / `codex-reply` MCP tools |
| **Sub-agents** | ❌ NO MCP access | `codex exec` (shell command) only |

This is a known Claude Code limitation. Design sub-agent prompts to use `codex exec` for GPT-5.2/gpt-5.2-codex dispatch, never Codex MCP tools.

### 6. Hybrid State Model

Tasks and STATE.yaml coexist with clear separation of concerns:

| System | Tracks | Example |
|--------|--------|---------|
| **STATE.yaml** | Pipeline config — the *what* | phase, mode, budget, baselines, policy |
| **Tasks** | Workflow progress — the *how* | which sub-step, dependencies, completion status |
| **Sentinel DSL** | LLM↔script communication — the *language* | nonce-tagged plan/verdict blocks |

**Never duplicate data between Tasks and STATE.yaml.** Tasks track progress, STATE.yaml tracks configuration. If you need to know *where* in the pipeline: STATE.yaml. If you need to know *what's been done this cycle*: Tasks.

### 7. Task Naming Convention

Tasks follow the pattern: `deadf-{run_id}-{task_id}-{sub_step}`

Examples:
- `deadf-run001-auth01-generate`
- `deadf-run001-auth01-implement`
- `deadf-run001-auth01-verify`
- `deadf-run001-auth01-reflect`

---

## Sentinel Parsing

### Nonce Lifecycle

| Event | Nonce Behavior |
|-------|---------------|
| Cycle start | Derive from cycle_id, store in `cycle.nonce` |
| Planner call | Inject into prompt template |
| Format-repair retry | **Same nonce** (same cycle) |
| All verifier calls | **Same nonce** (all criteria, same cycle) |
| New cycle | **New nonce** (new cycle_id) |

### Plan Block Format

```
<<<PLAN:V1:NONCE={nonce}>>>
TASK_ID=<bare>
TITLE="<quoted>"
SUMMARY=
  <2-space indented multi-line>
FILES:
- path=<bare> action=<add|modify|delete> rationale="<quoted>"
ACCEPTANCE:
- id=AC<n> text="<quoted testable statement>"
ESTIMATED_DIFF=<positive integer>
<<<END_PLAN:NONCE={nonce}>>>
```

**Acceptance criteria prefix convention:**
- `DET: ...` — Deterministic: auto-passed when verify.sh reports `"pass": true`. **DET criteria MUST map to one of verify.sh's 6 checks:**
  1. Tests pass (pytest/jest/etc exit 0)
  2. Lint passes (configured linter exit 0)
  3. Diff lines within 3× ESTIMATED_DIFF
  4. Path validation (no blocked paths: .env*, *.pem, *.key, .ssh/, .git/)
  5. No secrets detected
  6. Git tree clean (no uncommitted files)
- `LLM: ...` — LLM-judged: requires sub-agent reasoning (code quality, design, documentation tone, file existence, specific output matching, anything NOT in the 6 checks above)

Examples:
- `id=AC1 text="DET: All tests pass with ≥1 new test added"`
- `id=AC2 text="DET: No lint errors introduced"`
- `id=AC3 text="LLM: Error messages are user-friendly and follow project tone"`
- `id=AC4 text="LLM: File src/auth.py exports AuthHandler class with login() method"`

**Important:** File existence and content checks are `LLM:`, not `DET:` — verify.sh does not check specific file contents.

The orchestrator uses these prefixes to skip LLM verification for `DET:` criteria (auto-pass if verify.sh passed).

Parse with: `python3 extract_plan.py --nonce <nonce> < raw_output`

### Verdict Block Format

```
<<<VERDICT:V1:{criterion_id}:NONCE={nonce}>>>
ANSWER=YES or NO
REASON="<single sentence>"
<<<END_VERDICT:{criterion_id}:NONCE={nonce}>>>
```

Parse with: `python3 build_verdict.py --nonce <nonce> --criteria AC1,AC2,...`

### Format-Repair Retry

If `extract_plan.py` or `build_verdict.py` exits 1:
1. Read stderr (contains specific error with line number)
2. Send to same LLM: *"Your output could not be parsed. Error: {stderr}. Please output ONLY the corrected block, no other text."*
3. Parse again (**same nonce**)
4. If still fails: `CYCLE_FAIL` (planner) or `NEEDS_HUMAN` (verifier)

**One retry maximum.**

---

## Stuck Detection

| Trigger | Condition | Action |
|---------|-----------|--------|
| Stuck (first) | `loop.stuck_count >= POLICY.escalation.stuck_threshold` (default: 3) AND `task.replan_attempted == false` | **Re-plan**: regenerate task from scratch (see below) |
| Stuck (after re-plan) | `loop.stuck_count >= POLICY.escalation.stuck_threshold` AND `task.replan_attempted == true` | `phase: needs_human`, notify Fred |
| Budget time | `now() - budget.started_at >= POLICY.escalation.max_hours` | `phase: needs_human`, notify Fred |
| 3x task failure | `task.retry_count >= task.max_retries` | Rollback + `phase: needs_human` |
| State invalid | STATE.yaml unparseable or schema mismatch | `phase: needs_human`, `CYCLE_FAIL` |
| Parse failure | Actor output invalid after 1 retry | `CYCLE_FAIL` |

### Plan Disposability (Re-plan Before Escalate)

When stuck detection triggers for the first time on a task:
1. Set `task.replan_attempted: true` in STATE.yaml
2. Reset `loop.stuck_count: 0`, `task.retry_count: 0`
3. Set `task.sub_step: generate` (re-enter task generation)
4. The planner will regenerate the task spec from scratch with fresh context
5. If stuck triggers again after re-plan → escalate to `needs_human`

**Rationale (from Ralph Wiggum methodology):** Plans drift. Regenerating a plan is cheap (one cycle). Grinding on a stale plan wastes more cycles than starting fresh. "The plan is a tool, not an artifact."

---

## Notifications (Mode-Dependent)

Read mode from `STATE.yaml → mode`. Read behavior from `POLICY.yaml → modes.<mode>.notifications`.

Notifications are delivered via **stdout** (for ralph.sh to capture) and **files** in `.deadf/notifications/`:

| Event | yolo | hybrid | interactive |
|-------|------|--------|-------------|
| Track complete | silent | 🔔 notify | 🔔 notify |
| New track starting | silent | 🔔 ask approval | 🔔 ask approval |
| Task complete | silent | silent | 🔔 ask approval |
| Stuck | 🔔 pause | 🔔 pause | 🔔 pause |
| 3x fail + rollback | 🔔 pause | 🔔 pause | 🔔 pause |
| Budget 75% | 🔔 warn | 🔔 warn | 🔔 warn |
| Complete | 🎉 summary | 🎉 summary | 🎉 summary |

**"pause" = set `phase: needs_human` and write notification to `.deadf/notifications/` + stdout.**
**"ask approval" = write notification and wait for response before proceeding.**
**"notify" = write notification to `.deadf/notifications/{event}-{timestamp}.md` + print to stdout.**

### Notification File Format

```
.deadf/notifications/
├── track-complete-2026-01-29T04:30:00Z.md
├── escalation-2026-01-29T05:00:00Z.md
├── budget-warn-2026-01-29T06:00:00Z.md
└── complete.md
```

Each file contains: event type, timestamp, context, and any required human action.

---

## State Write Authority

| Actor | What It Can Write |
|-------|------------------|
| **ralph.sh** | `phase` → `needs_human` ONLY; `cycle.status` → `timed_out` ONLY |
| **Claude Code** | Everything else in STATE.yaml |
| **All others** | Nothing (stdout only) |

**Atomic writes:** Always write to a temp file, then `mv` to STATE.yaml. Never partial writes.

---

## Model Dispatch Reference

| Purpose | Command | Model |
|---------|---------|-------|
| Planning | `codex exec -m gpt-5.2 --skip-git-repo-check "<prompt>"` | GPT-5.2 |
| Implementation | `codex exec -m gpt-5.2-codex -c 'model_reasoning_effort="high"' --approval-mode full-auto "<prompt>"` | GPT-5.2-Codex |
| LLM Verification | Task tool (sub-agent) | Claude Opus 4.5 (native) |
| Interactive Debug | Codex MCP tool (`codex` / `codex-reply`) | GPT-5.2 or GPT-5.2-Codex |
| QA Review | `codex exec -m gpt-5.2 --skip-git-repo-check "<prompt>"` | GPT-5.2 |
| Orchestration | You (this session) | Claude Opus 4.5 |

### When to Use MCP vs codex exec

| Scenario | Use | Why |
|----------|-----|-----|
| One-shot planning | `codex exec` | Fire-and-forget, clean stdout |
| One-shot implementation | `codex exec` | Full-auto, commits directly |
| Multi-turn debugging | Codex MCP (`codex` + `codex-reply`) | Needs conversation context |
| Interactive exploration | Codex MCP | Back-and-forth with model |

---

## Safety Constraints

1. **Never write source code.** Delegate to gpt-5.2-codex.
2. **Never override verifier verdicts.** If verify.sh says FAIL, it's FAIL. Period.
3. **Deterministic wins.** verify.sh results always take precedence over LLM judgment.
4. **Conservative by default.** verify.sh PASS + LLM FAIL = FAIL.
5. **One cycle = one action.** Never chain multiple actions in a single cycle.
6. **Atomic state updates.** Temp file + rename. Never partial writes to STATE.yaml.
7. **Nonce integrity.** Every sentinel parse must use the cycle's nonce. Never reuse across cycles.
8. **Rollback authority is yours.** You run git rollback commands. Not ralph. Not the implementer.
9. **No secrets in files.** Ever.
10. **Escalate when uncertain.** `phase: needs_human` is always safe.

---

## Quick Reference: Cycle Flow

```
DEADF_CYCLE <cycle_id>
  │
  ├─ LOAD:     Read STATE.yaml + POLICY.yaml + task files
  ├─ VALIDATE: Parse state, derive nonce, set cycle.status=running, check budgets
  ├─ DECIDE:   phase + task.sub_step → exactly one action
  ├─ EXECUTE:  Run the action (dispatch to appropriate worker)
  ├─ RECORD:   Update STATE.yaml (always increment iteration)
  └─ REPLY:    CYCLE_OK | CYCLE_FAIL | DONE  (printed to stdout, last line)
```

### Task Management Commands

| Action | How |
|--------|-----|
| Check tasks | `TaskList` (native Claude Code tool) |
| Get task details | `TaskGet` with task ID |
| Create task | `TaskCreate` with description and dependencies (`addBlockedBy`/`addBlocks`) |
| Update task | `TaskUpdate` with status: `pending` / `in_progress` / `completed` |
| Task list ID | Set `CLAUDE_CODE_TASK_LIST_ID` env var (ralph.sh does this automatically) |

---

## The Ralph Loop (CLI Adaptation)

ralph.sh calls Claude Code CLI instead of Clawdbot sessions:

```bash
# Core cycle kick (replaces clawdbot session send):
claude --print --allowedTools "Read,Write,Edit,Bash,Task,Glob,Grep" "DEADF_CYCLE $CYCLE_ID
project: $PROJECT_PATH
mode: $MODE
Execute ONE cycle. Follow iteration contract. Reply: CYCLE_OK | CYCLE_FAIL | DONE"
```

**Key differences from pipeline version:**
- `claude --print` outputs to stdout (ralph.sh captures and scans for cycle tokens)
- `--allowedTools "Read,Write,Edit,Bash,Task,Glob,Grep"` enables full filesystem and exec access
- `--continue` can be added for session persistence across cycles
- No Discord dependency — all communication via stdout and filesystem

### ralph.sh Token Scanning

ralph.sh scans Claude Code's stdout for the cycle reply token:
```bash
# After claude --print completes:
LAST_LINE=$(tail -1 "$OUTPUT_FILE")
case "$LAST_LINE" in
  *CYCLE_OK*)   echo "[ralph] Cycle OK" ;;
  *CYCLE_FAIL*) echo "[ralph] Cycle failed" ;;
  *DONE*)       echo "[ralph] Pipeline complete" ;;
  *)            echo "[ralph] No valid reply — treating as fail" ;;
esac
```

---

## Sub-Agent Dispatch (Task Tool)

Claude Code uses its native **Task tool** for sub-agent spawning (replaces `sessions_spawn`):

### Usage Pattern

```
Use the Task tool:
- Instructions: "Verify acceptance criterion AC1 against the following context..."
- Each Task runs in an isolated context
- Up to 7 parallel Tasks supported
- Results returned when sub-agent completes
```

### When to Use Sub-Agents

| Scenario | Sub-Agent? | Why |
|----------|-----------|-----|
| Per-criterion LLM verification | ✅ Yes | One Task per AC, parallelizable |
| Deep code analysis | ✅ Yes | Isolated context, focused task |
| Quick state check | ❌ No | Overhead exceeds benefit |
| Implementation dispatch | ❌ No | Use `codex exec` instead |

### Sub-Agent Output Contract

Each verification sub-agent MUST return:
1. The sentinel verdict block (for `build_verdict.py` parsing)
2. Raw reasoning (ignored by parser, but preserved in logs)

---

*Contract version: 2.4.2 — Adapted for Claude Code CLI. Matches FINAL_ARCHITECTURE_v2.4.2.md.* 🐟

```

### `ralph.sh` (current)

```bash
#!/bin/bash
# deadf(ish) CLI — ralph.sh (Loop Controller)
# Architecture: v2.4.2 — Claude Code CLI Port
#
# Ralph is the mechanical loop controller. He kicks cycles, watches state,
# enforces timeouts, manages locks, rotates logs. He never thinks, never
# decides, never plans. Purely mechanical.
#
# Key difference from pipeline version:
#   - Calls `claude --print --allowedTools ...` instead of `clawdbot session send`
#   - Synchronous execution: claude exits when done, ralph reads stdout
#   - Scans stdout for CYCLE_OK / CYCLE_FAIL / DONE tokens
#
# Write permissions (STATE.yaml):
#   phase        → "needs_human" ONLY
#   cycle.status → "timed_out" ONLY
#   Everything else belongs to Claude Code.
#
# Usage: ralph.sh <project_path> [mode]

set -uo pipefail

# ── Version ────────────────────────────────────────────────────────────────
RALPH_VERSION="2.4.2-cli"

# ── Arguments ──────────────────────────────────────────────────────────────
PROJECT_PATH="${1:?Usage: ralph.sh <project_path> [mode]}"
MODE="${2:-yolo}"

# ── Configuration ──────────────────────────────────────────────────────────
CYCLE_TIMEOUT="${RALPH_TIMEOUT:-600}"
LOG_DIR="$PROJECT_PATH/.deadf/logs"
LOCK_FILE="$PROJECT_PATH/.deadf/ralph.lock"
STATE_FILE="$PROJECT_PATH/STATE.yaml"
NOTIFY_DIR="$PROJECT_PATH/.deadf/notifications"
MAX_LOG_FILES="${RALPH_MAX_LOGS:-50}"
STALE_LOCK_AGE=86400  # 24 hours in seconds

# New CLI-specific configuration
RATE_LIMIT="${RALPH_RATE_LIMIT:-5}"             # Minimum seconds between cycles
MAX_FAILURES="${RALPH_MAX_FAILURES:-10}"         # Circuit breaker: consecutive failures
SESSION_MODE="${RALPH_SESSION:-auto}"            # auto|fresh|continue
SESSION_FILE="$PROJECT_PATH/.deadf/.claude_session_id"
SESSION_MAX_AGE="${RALPH_SESSION_MAX_AGE:-3600}" # Session expiry in seconds (1hr)
MIN_CLAUDE_VERSION="${RALPH_MIN_CLAUDE:-1.0.0}"  # Minimum claude CLI version

# Task Management configuration (supplementary — does not replace stdout scanning)
RALPH_TASK_LIST_ID="${RALPH_TASK_LIST_ID:-"deadf-$(basename "$PROJECT_PATH")"}"
TASKS_DIR="${HOME}/.claude/tasks"

# ── Color Output ───────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

# ── Preflight ──────────────────────────────────────────────────────────────
[[ -d "$PROJECT_PATH" ]] || { echo -e "${RED}[ralph] ERROR: Project path does not exist: $PROJECT_PATH${NC}" >&2; exit 1; }
[[ -f "$STATE_FILE" ]]   || { echo -e "${RED}[ralph] ERROR: STATE.yaml not found: $STATE_FILE${NC}" >&2; exit 1; }

mkdir -p "$LOG_DIR"    || { echo -e "${RED}[ralph] ERROR: Cannot create log dir: $LOG_DIR${NC}" >&2; exit 1; }
mkdir -p "$NOTIFY_DIR" || { echo -e "${RED}[ralph] ERROR: Cannot create notify dir: $NOTIFY_DIR${NC}" >&2; exit 1; }

command -v yq &>/dev/null    || { echo -e "${RED}[ralph] ERROR: yq required but not found${NC}" >&2; exit 1; }
command -v claude &>/dev/null || { echo -e "${RED}[ralph] ERROR: claude CLI required but not found${NC}" >&2; exit 1; }

# Task Management preflight (supplementary — warn only, never fail)
if [[ -d "$TASKS_DIR" ]]; then
    echo -e "${GREEN}[ralph]${NC} Tasks directory accessible: $TASKS_DIR"
else
    echo -e "${YELLOW}[ralph]${NC} ⚠️  Tasks directory not found: $TASKS_DIR (Task Management is supplementary — continuing)"
fi

# ── Claude CLI Version Check ──────────────────────────────────────────────
check_claude_version() {
    local version_output
    version_output=$(claude --version 2>/dev/null || echo "0.0.0")
    # Extract version number (handles formats like "claude 1.2.3" or just "1.2.3")
    local version
    version=$(echo "$version_output" | grep -oP '\d+\.\d+\.\d+' | head -1)
    [[ -z "$version" ]] && version="0.0.0"

    # Simple semver comparison
    local IFS='.'
    read -r maj1 min1 pat1 <<< "$version"
    read -r maj2 min2 pat2 <<< "$MIN_CLAUDE_VERSION"

    if (( maj1 < maj2 || (maj1 == maj2 && min1 < min2) || (maj1 == maj2 && min1 == min2 && pat1 < pat2) )); then
        echo -e "${RED}[ralph] ERROR: claude CLI version $version < minimum $MIN_CLAUDE_VERSION${NC}" >&2
        exit 1
    fi
    log "Claude CLI version: $version (minimum: $MIN_CLAUDE_VERSION)"
}

# ── Logging ────────────────────────────────────────────────────────────────
log() { echo -e "${CYAN}[ralph]${NC} $(date -Iseconds) $*"; }
log_ok() { echo -e "${GREEN}[ralph]${NC} $(date -Iseconds) $*"; }
log_warn() { echo -e "${YELLOW}[ralph]${NC} $(date -Iseconds) ⚠️  $*"; }
log_err() { echo -e "${RED}[ralph]${NC} $(date -Iseconds) ERROR: $*" >&2; }

# ── Lock Management ───────────────────────────────────────────────────────
acquire_lock() {
    if ! ( set -o noclobber; echo "$$ $(date -Iseconds)" > "$LOCK_FILE" ) 2>/dev/null; then
        local other_pid other_ts
        read -r other_pid other_ts < "$LOCK_FILE" 2>/dev/null || true

        if [[ -z "$other_pid" ]]; then
            log "Empty lockfile. Taking over."
            echo "$$ $(date -Iseconds)" > "$LOCK_FILE"
            return 0
        fi

        if kill -0 "$other_pid" 2>/dev/null; then
            if [[ -n "$other_ts" ]]; then
                local lock_epoch
                lock_epoch=$(date -d "$other_ts" +%s 2>/dev/null || echo 0)
                local now_epoch
                now_epoch=$(date +%s)
                local lock_age=$(( now_epoch - lock_epoch ))

                if [[ "$lock_age" -gt "$STALE_LOCK_AGE" ]]; then
                    log_warn "Lock PID $other_pid alive but ${lock_age}s old (>${STALE_LOCK_AGE}s). Assuming stale."
                    echo "$$ $(date -Iseconds)" > "$LOCK_FILE"
                    return 0
                fi
            fi
            log_err "Another instance running (PID $other_pid). Exiting."
            exit 1
        else
            log "Stale lock (PID $other_pid dead). Taking over."
            echo "$$ $(date -Iseconds)" > "$LOCK_FILE"
        fi
    fi
}

release_lock() {
    rm -f "$LOCK_FILE"
}

# ── Signal Handling ────────────────────────────────────────────────────────
SHUTTING_DOWN=0

cleanup() {
    if [[ "$SHUTTING_DOWN" -eq 1 ]]; then
        return
    fi
    SHUTTING_DOWN=1
    log "🛑 Signal received. Shutting down gracefully."
    release_lock
    print_summary
    log "Shutdown complete."
    exit 130
}

trap cleanup INT TERM

# ── STATE.yaml Helpers ─────────────────────────────────────────────────────
read_field() {
    yq -r ".$1 // \"unknown\"" "$STATE_FILE" 2>/dev/null || echo "unknown"
}

get_iteration()    { read_field "loop.iteration"; }
get_phase()        { read_field "phase"; }
get_cycle_status() { read_field "cycle.status"; }
get_max_iter()     { read_field "loop.max_iterations"; }

# Ralph may ONLY set these specific values:
set_phase_needs_human() {
    yq -i '.phase = "needs_human"' "$STATE_FILE"
}

set_cycle_timed_out() {
    yq -i '.cycle.status = "timed_out"' "$STATE_FILE"
}

# ── Log Rotation ───────────────────────────────────────────────────────────
rotate_logs() {
    local log_count
    log_count=$(find "$LOG_DIR" -maxdepth 1 -name 'cycle-*.log' -type f 2>/dev/null | wc -l)

    if [[ "$log_count" -gt "$MAX_LOG_FILES" ]]; then
        local to_remove=$(( log_count - MAX_LOG_FILES ))
        log "Rotating logs: removing $to_remove oldest files (keeping $MAX_LOG_FILES)"
        find "$LOG_DIR" -maxdepth 1 -name 'cycle-*.log' -type f -printf '%T@ %p\n' \
            | sort -n \
            | head -n "$to_remove" \
            | awk '{print $2}' \
            | xargs -r rm -f
    fi
}

# ── UUID Generation ────────────────────────────────────────────────────────
generate_cycle_id() {
    uuidgen 2>/dev/null \
        || cat /proc/sys/kernel/random/uuid 2>/dev/null \
        || echo "cycle-$(date +%s)-$$"
}

# ── Session Management ─────────────────────────────────────────────────────
get_session_flag() {
    case "$SESSION_MODE" in
        fresh)
            # Always start a new session
            echo ""
            ;;
        continue)
            # Always continue (if session file exists)
            if [[ -f "$SESSION_FILE" ]]; then
                local session_id
                session_id=$(cat "$SESSION_FILE" 2>/dev/null)
                if [[ -n "$session_id" ]]; then
                    echo "--continue --session-id $session_id"
                    return
                fi
            fi
            echo ""
            ;;
        auto|*)
            # Continue if session is fresh enough, otherwise start new
            if [[ -f "$SESSION_FILE" ]]; then
                local session_ts
                session_ts=$(stat -c %Y "$SESSION_FILE" 2>/dev/null || echo 0)
                local now_ts
                now_ts=$(date +%s)
                local age=$(( now_ts - session_ts ))

                if [[ "$age" -lt "$SESSION_MAX_AGE" ]]; then
                    local session_id
                    session_id=$(cat "$SESSION_FILE" 2>/dev/null)
                    if [[ -n "$session_id" ]]; then
                        log "Reusing session (age=${age}s < ${SESSION_MAX_AGE}s)"
                        echo "--continue --session-id $session_id"
                        return
                    fi
                else
                    log "Session expired (age=${age}s >= ${SESSION_MAX_AGE}s). Starting fresh."
                    rm -f "$SESSION_FILE"
                fi
            fi
            echo ""
            ;;
    esac
}

save_session_id() {
    local output="$1"
    # Claude CLI may output session ID — try to capture it
    # The session ID is typically in the output or can be derived
    # For now, use a hash of the first cycle as session marker
    local session_id
    session_id=$(echo "$output" | grep -oP 'session[_-]?id[=: ]+\K\S+' | head -1)
    if [[ -z "$session_id" ]]; then
        # Generate a stable session ID for this run
        session_id="ralph-$$-$(date +%s)"
    fi
    echo "$session_id" > "$SESSION_FILE"
}

# ── Task Status Check (Supplementary) ──────────────────────────────────────
# Reads task list state from ~/.claude/tasks/ for visibility.
# This is SUPPLEMENTARY — stdout scanning for CYCLE_OK/CYCLE_FAIL/DONE
# remains the primary cycle control mechanism.
TASK_STATS_TOTAL=0
TASK_STATS_COMPLETED=0
TASK_STATS_PENDING=0
TASK_STATS_IN_PROGRESS=0
TASK_STATS_FAILED=0

task_status_check() {
    # Reset counters
    TASK_STATS_TOTAL=0
    TASK_STATS_COMPLETED=0
    TASK_STATS_PENDING=0
    TASK_STATS_IN_PROGRESS=0
    TASK_STATS_FAILED=0

    if [[ ! -d "$TASKS_DIR" ]]; then
        echo "[tasks] Tasks directory not available" >&2
        return 1
    fi

    # Look for JSON files matching our task list ID
    local found=0
    while IFS= read -r -d '' task_file; do
        found=1
        # Extract status fields using grep/jq-lite approach
        # Task files are JSON; parse with python if available, else grep
        if command -v python3 &>/dev/null; then
            local counts
            counts=$(python3 -c "
import json, sys, glob, os

tasks_dir = '$TASKS_DIR'
list_id = '$RALPH_TASK_LIST_ID'
total = completed = pending = in_progress = failed = 0

for f in glob.glob(os.path.join(tasks_dir, '**', '*.json'), recursive=True):
    try:
        with open(f) as fh:
            data = json.load(fh)
        # Check if this task belongs to our list
        tid = data.get('listId', '') or data.get('list_id', '') or ''
        if tid != list_id and list_id not in str(data.get('id', '')):
            continue
        tasks = data.get('tasks', [data]) if isinstance(data, dict) else [data]
        for t in tasks:
            status = t.get('status', 'unknown')
            total += 1
            if status == 'completed': completed += 1
            elif status == 'pending': pending += 1
            elif status == 'in_progress': in_progress += 1
            elif status == 'failed': failed += 1
    except Exception:
        pass

print(f'{total} {completed} {pending} {in_progress} {failed}')
" 2>/dev/null)
            if [[ -n "$counts" ]]; then
                read -r TASK_STATS_TOTAL TASK_STATS_COMPLETED TASK_STATS_PENDING TASK_STATS_IN_PROGRESS TASK_STATS_FAILED <<< "$counts"
            fi
            break  # python3 scans all files at once
        else
            # Fallback: simple grep-based counting (less accurate)
            local status
            status=$(grep -o '"status"[[:space:]]*:[[:space:]]*"[^"]*"' "$task_file" 2>/dev/null | head -1 | grep -o '"[^"]*"$' | tr -d '"')
            TASK_STATS_TOTAL=$((TASK_STATS_TOTAL + 1))
            case "$status" in
                completed)   TASK_STATS_COMPLETED=$((TASK_STATS_COMPLETED + 1)) ;;
                pending)     TASK_STATS_PENDING=$((TASK_STATS_PENDING + 1)) ;;
                in_progress) TASK_STATS_IN_PROGRESS=$((TASK_STATS_IN_PROGRESS + 1)) ;;
                failed)      TASK_STATS_FAILED=$((TASK_STATS_FAILED + 1)) ;;
            esac
        fi
    done < <(find "$TASKS_DIR" -maxdepth 2 -name '*.json' -print0 2>/dev/null)

    if [[ "$TASK_STATS_TOTAL" -gt 0 ]]; then
        echo "[tasks] Task list '$RALPH_TASK_LIST_ID': total=$TASK_STATS_TOTAL completed=$TASK_STATS_COMPLETED pending=$TASK_STATS_PENDING in_progress=$TASK_STATS_IN_PROGRESS failed=$TASK_STATS_FAILED" >&2
    else
        echo "[tasks] No tasks found for list '$RALPH_TASK_LIST_ID'" >&2
    fi
    return 0
}

# ── Notifications ──────────────────────────────────────────────────────────
notify() {
    local event="$1"
    local message="$2"
    local timestamp
    timestamp=$(date -Iseconds)
    local file="$NOTIFY_DIR/${event}-${timestamp}.md"

    cat > "$file" <<EOF
# Notification: $event
**Timestamp:** $timestamp
**Project:** $PROJECT_PATH
**Mode:** $MODE

$message
EOF

    log "$message"
}

# ── Statistics Tracking ────────────────────────────────────────────────────
STATS_START_TIME=$(date +%s)
STATS_CYCLES_RUN=0
STATS_CYCLES_OK=0
STATS_CYCLES_FAIL=0
STATS_CONSECUTIVE_FAILURES=0

print_summary() {
    local end_time
    end_time=$(date +%s)
    local duration=$(( end_time - STATS_START_TIME ))
    local hours=$(( duration / 3600 ))
    local minutes=$(( (duration % 3600) / 60 ))
    local seconds=$(( duration % 60 ))

    echo ""
    echo -e "${BOLD}════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ralph.sh Session Summary${NC}"
    echo -e "${BOLD}════════════════════════════════════════${NC}"
    echo -e "  Version:     ${RALPH_VERSION}"
    echo -e "  Project:     ${PROJECT_PATH}"
    echo -e "  Mode:        ${MODE}"
    echo -e "  Duration:    ${hours}h ${minutes}m ${seconds}s"
    echo -e "  Cycles run:  ${STATS_CYCLES_RUN}"
    echo -e "  ├─ OK:       ${GREEN}${STATS_CYCLES_OK}${NC}"
    echo -e "  └─ Failed:   ${RED}${STATS_CYCLES_FAIL}${NC}"
    echo -e "  Final phase: $(get_phase)"

    # Task Management statistics (supplementary)
    task_status_check 2>/dev/null
    if [[ "$TASK_STATS_TOTAL" -gt 0 ]]; then
        echo -e "  ────────────────────────────────────"
        echo -e "  Tasks (${RALPH_TASK_LIST_ID}):"
        echo -e "  ├─ Total:       ${TASK_STATS_TOTAL}"
        echo -e "  ├─ Completed:   ${GREEN}${TASK_STATS_COMPLETED}${NC}"
        echo -e "  ├─ Pending:     ${TASK_STATS_PENDING}"
        echo -e "  ├─ In Progress: ${BLUE}${TASK_STATS_IN_PROGRESS}${NC}"
        echo -e "  └─ Failed:      ${RED}${TASK_STATS_FAILED}${NC}"
    fi

    echo -e "${BOLD}════════════════════════════════════════${NC}"
    echo ""
}

# ── Scan Claude Output ─────────────────────────────────────────────────────
# Scans stdout for the LAST occurrence of CYCLE_OK, CYCLE_FAIL, or DONE.
# Returns: "ok", "fail", "done", or "unknown"
scan_cycle_result() {
    local output_file="$1"

    if [[ ! -s "$output_file" ]]; then
        echo "unknown"
        return
    fi

    # Scan from the end for the last occurrence of a cycle token
    local last_token=""
    while IFS= read -r line; do
        case "$line" in
            *DONE*)       last_token="done" ;;
            *CYCLE_OK*)   last_token="ok" ;;
            *CYCLE_FAIL*) last_token="fail" ;;
        esac
    done < "$output_file"

    echo "${last_token:-unknown}"
}

# ── Run Claude Cycle ───────────────────────────────────────────────────────
run_cycle() {
    local cycle_id="$1"
    local cycle_log="$2"
    local local_iter="$3"
    local phase="$4"

    local session_flags
    session_flags=$(get_session_flag)

    local prompt="DEADF_CYCLE $cycle_id
project: $PROJECT_PATH
mode: $MODE
Execute ONE cycle. Follow iteration contract. Reply: CYCLE_OK | CYCLE_FAIL | DONE"

    local output_file="$LOG_DIR/.cycle-output-$$"

    log "Invoking claude --print (iter=$local_iter, phase=$phase, id=${cycle_id:0:8}...)"

    # Enable native Task Management System and set shared task list ID
    export CLAUDE_CODE_ENABLE_TASKS=1
    export CLAUDE_CODE_TASK_LIST_ID="$RALPH_TASK_LIST_ID"

    # Build command — use eval to handle session_flags which may be empty
    local cmd="claude --print --allowedTools 'Read,Write,Edit,Bash,Task,Glob,Grep'"
    if [[ -n "$session_flags" ]]; then
        cmd="$cmd $session_flags"
    fi

    # Run with timeout
    local exit_code=0
    timeout "$CYCLE_TIMEOUT" bash -c "$cmd -p \"\$1\"" -- "$prompt" \
        > "$output_file" 2>>"$cycle_log" || exit_code=$?

    # Log the output
    if [[ -f "$output_file" ]]; then
        cat "$output_file" >> "$cycle_log"
    fi

    # Handle timeout (exit code 124)
    if [[ "$exit_code" -eq 124 ]]; then
        log_err "⏰ Cycle timeout after ${CYCLE_TIMEOUT}s"
        echo "$(date -Iseconds) TIMEOUT after ${CYCLE_TIMEOUT}s" >> "$cycle_log"
        set_cycle_timed_out
        set_phase_needs_human
        notify "timeout" "Cycle timed out after ${CYCLE_TIMEOUT}s at iteration $local_iter"
        rm -f "$output_file"
        echo "timeout"
        return
    fi

    # Handle claude crash (nonzero exit, not timeout)
    if [[ "$exit_code" -ne 0 ]]; then
        log_warn "claude exited with code $exit_code"
        echo "$(date -Iseconds) CLAUDE_EXIT_CODE=$exit_code" >> "$cycle_log"
    fi

    # Save session ID for potential reuse
    if [[ -f "$output_file" ]]; then
        save_session_id "$(cat "$output_file")"
    fi

    # Scan for cycle result token
    local result
    result=$(scan_cycle_result "$output_file")
    rm -f "$output_file"

    echo "$result"
}

# ── Main ───────────────────────────────────────────────────────────────────
check_claude_version
acquire_lock

log_ok "Starting ralph.sh v${RALPH_VERSION}"
log "  project=$PROJECT_PATH mode=$MODE"
log "  timeout=${CYCLE_TIMEOUT}s rate_limit=${RATE_LIMIT}s"
log "  max_failures=$MAX_FAILURES session=$SESSION_MODE"

# Read max iterations (with fallback)
MAX_ITERATIONS=$(get_max_iter)
[[ "$MAX_ITERATIONS" == "unknown" || "$MAX_ITERATIONS" == "null" ]] && MAX_ITERATIONS=200
log "Max iterations: $MAX_ITERATIONS"

LAST_CYCLE_TIME=0

while true; do
    # Check for shutdown between iterations
    [[ "$SHUTTING_DOWN" -eq 1 ]] && break

    PHASE=$(get_phase)
    ITERATION=$(get_iteration)

    # ── Terminal conditions ──────────────────────────────────────────────
    if [[ "$PHASE" == "complete" ]]; then
        log_ok "🎉 Pipeline complete at iteration $ITERATION"
        notify "complete" "Pipeline completed successfully at iteration $ITERATION"
        release_lock
        print_summary
        exit 0
    fi

    if [[ "$PHASE" == "needs_human" ]]; then
        log_warn "Needs human intervention. Pausing. (iteration=$ITERATION)"
        notify "needs-human" "Pipeline paused — needs human intervention at iteration $ITERATION"
        release_lock
        print_summary
        exit 1
    fi

    if [[ "$ITERATION" != "unknown" && "$ITERATION" -ge "$MAX_ITERATIONS" ]]; then
        log_err "🛑 Max iterations reached ($ITERATION >= $MAX_ITERATIONS)"
        notify "max-iterations" "Max iterations reached ($ITERATION >= $MAX_ITERATIONS)"
        release_lock
        print_summary
        exit 1
    fi

    # ── Circuit breaker ──────────────────────────────────────────────────
    if [[ "$STATS_CONSECUTIVE_FAILURES" -ge "$MAX_FAILURES" ]]; then
        log_err "🔌 Circuit breaker: $STATS_CONSECUTIVE_FAILURES consecutive failures (limit=$MAX_FAILURES)"
        set_phase_needs_human
        notify "circuit-breaker" "Circuit breaker tripped: $STATS_CONSECUTIVE_FAILURES consecutive failures"
        release_lock
        print_summary
        exit 1
    fi

    # ── Rate limiting ────────────────────────────────────────────────────
    NOW_TS=$(date +%s)
    ELAPSED=$(( NOW_TS - LAST_CYCLE_TIME ))
    if [[ "$LAST_CYCLE_TIME" -gt 0 && "$ELAPSED" -lt "$RATE_LIMIT" ]]; then
        WAIT_TIME=$(( RATE_LIMIT - ELAPSED ))
        log "Rate limit: waiting ${WAIT_TIME}s"
        sleep "$WAIT_TIME"
    fi

    # ── Rotate logs before kicking new cycle ─────────────────────────────
    rotate_logs

    # ── Kick a new cycle ─────────────────────────────────────────────────
    CYCLE_ID=$(generate_cycle_id)
    local_iter="${ITERATION:-0}"

    log "── Cycle kick (iter=$local_iter, phase=$PHASE, id=${CYCLE_ID:0:8}...) ──"

    CYCLE_LOG="$LOG_DIR/cycle-${local_iter}.log"
    echo "$(date -Iseconds) CYCLE_START id=$CYCLE_ID iter=$local_iter phase=$PHASE" >> "$CYCLE_LOG"

    LAST_CYCLE_TIME=$(date +%s)

    # Run claude and get result
    RESULT=$(run_cycle "$CYCLE_ID" "$CYCLE_LOG" "$local_iter" "$PHASE")
    STATS_CYCLES_RUN=$((STATS_CYCLES_RUN + 1))

    echo "$(date -Iseconds) RESULT=$RESULT" >> "$CYCLE_LOG"

    # Post-cycle task status check (supplementary visibility)
    task_status_check 2>> "$CYCLE_LOG"
    if [[ "$TASK_STATS_TOTAL" -gt 0 ]]; then
        echo "$(date -Iseconds) TASKS total=$TASK_STATS_TOTAL completed=$TASK_STATS_COMPLETED pending=$TASK_STATS_PENDING in_progress=$TASK_STATS_IN_PROGRESS failed=$TASK_STATS_FAILED" >> "$CYCLE_LOG"
    fi

    case "$RESULT" in
        ok)
            log_ok "✅ Cycle OK (iter=$local_iter)"
            STATS_CYCLES_OK=$((STATS_CYCLES_OK + 1))
            STATS_CONSECUTIVE_FAILURES=0
            ;;
        done)
            log_ok "🎉 Pipeline reports DONE (iter=$local_iter)"
            STATS_CYCLES_OK=$((STATS_CYCLES_OK + 1))
            STATS_CONSECUTIVE_FAILURES=0
            # Loop will check phase on next iteration and exit
            ;;
        fail)
            log_warn "❌ Cycle failed (iter=$local_iter, consecutive=${STATS_CONSECUTIVE_FAILURES})"
            STATS_CYCLES_FAIL=$((STATS_CYCLES_FAIL + 1))
            STATS_CONSECUTIVE_FAILURES=$((STATS_CONSECUTIVE_FAILURES + 1))
            ;;
        timeout)
            log_err "⏰ Cycle timed out — exiting"
            STATS_CYCLES_FAIL=$((STATS_CYCLES_FAIL + 1))
            release_lock
            print_summary
            exit 1
            ;;
        unknown|*)
            log_warn "⚠️  No valid cycle reply — treating as failure (iter=$local_iter)"
            STATS_CYCLES_FAIL=$((STATS_CYCLES_FAIL + 1))
            STATS_CONSECUTIVE_FAILURES=$((STATS_CONSECUTIVE_FAILURES + 1))
            ;;
    esac
done

# If we exit the loop (shutdown flag), clean up
release_lock
print_summary
log "Exited main loop."
exit 130

```

### `METHODOLOGY.md` (current)

```md
# deadf(ish) Methodology — v2.4.2

## Overview

deadf(ish) is a development pipeline for AI-assisted software projects.
It enforces incremental planning, atomic execution, and structured verification.

**Primary operational document: `CLAUDE.md`** — that file contains everything
the AI agent needs to operate within a deadf(ish) project. This methodology
doc provides background context only.

---

## Core Principles

1. **Plan incrementally** — one track (feature/fix) at a time
2. **Execute atomically** — one task = one commit = one verification
3. **Verify everything** — every task has explicit pass/fail criteria
4. **State is YAML** — machine-readable, diffable, unambiguous

## Architecture

### Pipeline Components

| Component | Purpose |
|-----------|---------|
| `ralph.sh` | Orchestrator — runs the task loop |
| `extract_plan.py` | Parses plans into executable task sequences |
| `build_verdict.py` | Evaluates verification output into pass/fail |
| `verify.sh` | Runs verification commands for the current task |

### State Files

| File | Purpose |
|------|---------|
| `STATE.yaml` | Current position: active track, task, status |
| `POLICY.yaml` | Project constraints and rules |
| `CLAUDE.md` | Agent instructions and operational context |
| `VISION.md` | Problem statement and scope (constitution) |
| `ROADMAP.md` | Themes and upcoming tracks |
| `TASK.md` | Current task details (generated per task) |

### Runtime Directory

```
.deadf/
├── logs/            # Execution logs per task
├── notifications/   # Queue for human-attention items
└── ralph.lock       # Prevents concurrent pipeline runs
```

## Workflow

```
ROADMAP → select track → plan tasks → TASK LOOP:
  generate TASK.md → execute → verify → commit → next task
→ mark track complete → next track
```

Each task is atomic. If verification fails, the task is retried or escalated.
Ralph manages this loop automatically.

## MCP Integration

Projects include `.mcp.json` for Model Context Protocol server configuration.
This enables tool-augmented AI workflows (e.g., Codex as an MCP server).

---

*For operational details, see `CLAUDE.md` in any deadf(ish) project.*
*For the CLI tool itself, see `README.md`.*

```

---

## 0c. Guardrails

- Implement via **micro-tasks**. Each micro-task must touch **1–3 files maximum**.
- If you need to touch more files, split into another micro-task.
- Keep changes minimal and consistent with existing style.
- Do not invent new architecture beyond what’s needed for P2.

---

## 1. Objective

Implement P2 end-to-end by completing micro-tasks 1–6 below.

Important: the prompt templates you create must be *usable artifacts* (not design docs) and must closely follow the canonical spec.

---

## Micro-task 1 (create prompts: P2_MAIN, P2_A, P2_A2)

**Files to add (3 max):**
- `.pipe/p2/P2_MAIN.md`
- `.pipe/p2/P2_A.md`
- `.pipe/p2/P2_A2.md`

**Create directory:** `.pipe/p2/` (if missing).

**Write file contents exactly as follows:**

### `.pipe/p2/P2_MAIN.md`
```md
# P2_MAIN — seed_docs / Brainstorm Session (deadf(ish) P2)

You are **GPT-5.2** acting as the **Brainstorm Facilitator** for Phase **P2** (aka `seed_docs`).
This is a **live interactive** session with a human operator.

Your job: facilitate structured ideation and then write these artifacts:
- `VISION.md`
- `ROADMAP.md`
- `.deadf/seed/P2_BRAINSTORM.md` (raw idea ledger; keep ideas append-only)

## Non-Negotiable Rules (from canonical P2 spec)

1. **Facilitator, not generator.** You do not dump idea lists.
   - Your default move is asking probing questions that pull ideas from the human.
   - Exception: Phase 6 (OUTPUT) and Phase 7 (ADVERSARIAL REVIEW) require synthesis.
2. **Stay divergent as long as possible.** Do not organize until:
   - the human explicitly requests organizing, OR
   - ≥50 ideas captured AND the human’s energy is dropping.
3. **Anti-semantic clustering.** Force a domain pivot about every ~10 ideas (see `.pipe/p2/P2_B.md`). Track domain coverage.
4. **Quantity over quality.** Push past the obvious first 20 ideas.
5. **Context hygiene.** After 30+ ideas: persist ledger to file and keep chat output to deltas only.
6. **Plans as prompts.** `VISION.md` and `ROADMAP.md` are directly consumed downstream.
7. **Observable success truths.** Success metrics must be verifiable.

## Active Anti-Bias Protocols (always on)

- **Anti-anchoring:** don’t lead with suggestions; ask open questions.
- **Anti-premature convergence:** when narrowing, ask “what angles haven’t we explored?”
- **Anti-recency:** periodically reference earlier ideas.
- **Anti-sycophancy:** probe weak ideas; ask what makes it different.
- **Anti-domain fixation:** enforce pivots via protocol.
- **Anti-feasibility bias:** include at least one “impossible” round, then back-solve.

## File I/O Guardrails

You may create/modify ONLY:
- `.deadf/seed/P2_BRAINSTORM.md`
- `VISION.md`
- `ROADMAP.md`
- `.deadf/seed/P2_DONE` (optional marker; runner may also create)

Do NOT touch any other files.

## Before You Start (mandatory)

1. Ensure directory exists: `.deadf/seed/`.
2. Read and internalize these sub-prompts (treat them as your operating manual):
   - `.pipe/p2/P2_A.md`
   - `.pipe/p2/P2_A2.md`
   - `.pipe/p2/P2_B.md`
   - `.pipe/p2/P2_C.md`
   - `.pipe/p2/P2_D.md`
   - `.pipe/p2/P2_E.md`
   - `.pipe/p2/P2_F.md`
   - `.pipe/p2/P2_G.md`
3. Initialize internal state:
   - `project_name`, `one_sentence_pitch`, `target_user`, `constraints`, `success_metrics`
   - `idea_count=0`, `current_lens=null`, `lenses_used=[]`
   - `domains_covered=[]`
   - `anti_bias_done={20:false,40:false,60:false,80:false}`
4. If `.deadf/seed/P2_BRAINSTORM.md` does not exist, create it with:
   - a small metadata header (date, operator name if offered)
   - a “Session State” section (editable)
   - an “Ideas” section (append-only)

## Session Flow (7 phases)

SETUP → TECHNIQUE SELECT → IDEATE → ORGANIZE → CRYSTALLIZE → OUTPUT → ADVERSARIAL REVIEW

### Quick Mode (explicit)

If the human says “I already know what I want to build”, do this:
1. Ask for:
   - 2–3 sentence description
   - 3–5 must-haves
   - 3–7 non-goals
   - constraints
   - 3–7 measurable success outcomes (90 days)
2. Write `VISION.md` + `ROADMAP.md` (Phase 6)
3. Run adversarial review (Phase 7)

---

# Phase 1: SETUP

Greet the human and explain the process briefly: structured brainstorm → `VISION.md` + `ROADMAP.md`.

Ask these questions (exactly):
1. “What are we building? Elevator pitch — even rough is fine.”
2. “Who needs this? Primary user.”
3. “What’s the pain? Why does this need to exist now?”
4. “Any constraints? (time, money, tech, legal, platform)”
5. “What does success look like in 90 days? 3–7 measurable outcomes.”

Then:
- Confirm understanding with a one-sentence pitch.
- Get an explicit “yes” before proceeding.

After the human confirms, proceed to Phase 2 using `.pipe/p2/P2_A.md`.

```

### `.pipe/p2/P2_A.md`
```md
# P2_A — Technique Selection (Phase 2)

Goal: choose how we’ll ideate.

Present four approach modes (verbatim) and ask the human to pick:
1. **User-selected** — browse technique categories, pick what appeals
2. **AI-recommended** — AI picks sequence based on session goals (**DEFAULT**)
3. **Random** — randomize techniques to break habits
4. **Progressive** — structured journey: divergent → patterns → refine → action

If the human has a timebox, record it.
Default to **AI-recommended** if they don’t care.

If they pick **User-selected**, open `.pipe/p2/P2_A2.md` and use it as the browser.

If they pick **AI-recommended**, do:
- Choose 3–5 techniques for this session.
- Commit to a rotation plan: 5–8 exchanges per technique.
- Start Phase 3 (IDEATE) using the first technique and the round rules from `.pipe/p2/P2_C.md`.

```

### `.pipe/p2/P2_A2.md`
```md
# P2_A2 — Technique Library Browser (User-selected mode only)

Rule: list techniques **by name only** (no full descriptions).

Ask the human to pick:
- a category
- then 1–2 techniques from that category

Technique library:

- **structured:** SCAMPER, Six Thinking Hats, Mind Mapping, Resource Constraints, Decision Tree, Solution Matrix, Trait Transfer
- **creative:** What-If Scenarios, Analogical Thinking, Reversal/Inversion, First Principles, Forced Relationships, Time Shifting, Metaphor Mapping, Cross-Pollination, Concept Blending, Reverse Brainstorming, Sensory Exploration
- **collaborative:** Yes-And Building, Brain Writing, Random Stimulation, Role Playing, Ideation Relay
- **deep:** Five Whys, Morphological Analysis, Provocation, Assumption Reversal, Question Storming, Constraint Mapping, Failure Analysis, Emergent Thinking
- **theatrical:** Time Travel Talk Show, Alien Anthropologist, Dream Fusion Lab, Emotion Orchestra, Parallel Universe Cafe, Persona Journey
- **wild:** Chaos Engineering, Anti-Solution, Quantum Superposition, Elemental Forces, Pirate Code, Zombie Apocalypse
- **introspective:** Inner Child Conference, Shadow Work Mining, Values Archaeology, Future Self Interview, Permission Giving
- **biomimetic:** Nature's Solutions, Ecosystem Thinking, Evolutionary Pressure
- **quantum:** Observer Effect, Entanglement Thinking, Superposition Collapse
- **cultural:** Indigenous Wisdom, Fusion Cuisine, Ritual Innovation, Mythic Frameworks

```

**Done when:**
- `ls .pipe/p2/` shows these 3 files.

---

## Micro-task 2 (create prompts: P2_B, P2_C, P2_D)

**Files to add (3 max):**
- `.pipe/p2/P2_B.md`
- `.pipe/p2/P2_C.md`
- `.pipe/p2/P2_D.md`

**Write file contents exactly as follows:**

### `.pipe/p2/P2_B.md`
```md
# P2_B — Domain Pivot Trigger (anti-clustering)

Use this every ~10 ideas during Phase 3 (IDEATE).

Protocol:
1. Review which domains have been covered so far.
2. Force a pivot to the least-explored domain.
3. Announce the new domain and ask 1–2 open-ended prompts that elicit ideas from the human.

Domains to rotate through (with short tags for ledger):
1. [Core] Core functionality / features
2. [UX] User experience / workflows / onboarding
3. [DX] Developer experience / DX / API design
4. [Ops] Operations / deployment / monitoring
5. [Biz] Business model / pricing / growth / distribution
6. [Edge] Edge cases / error handling / failure modes
7. [Eco] Ecosystem / plugins / integrations / partnerships
8. [A11y] Accessibility / i18n / localization
9. [Perf] Performance / scalability / reliability
10. [Sec] Security / privacy / compliance
11. [Comm] Community / governance / contribution model
12. [Docs] Documentation / learning curve

Scheduled anti-bias interrupts (once each when you cross the threshold):
- ~20 ideas: Reverse Brainstorm (“How could we make this fail? What’s the worst version?”)
- ~40 ideas: Analogies (“What would [Stripe/Docker/a restaurant] do? How does nature solve this?”)
- ~60 ideas: Constraint Injection (“What if you had 10× fewer resources? What if phone-only?”)
- ~80 ideas: Failure / black swans (“How could this be abused? What regulation kills it? What if competitor copies tomorrow?”)

Energy checkpoint cadence:
Every 4–5 exchanges, ask: keep pushing / switch technique / start organizing?
Default: keep exploring unless human explicitly wants to organize.

```

### `.pipe/p2/P2_C.md`
```md
# P2_C — Idea Capture + Ledger Hygiene (Phase 3)

Your job here is to (a) capture ideas in a strict format, and (b) keep chat outputs compact.

## Idea Ledger Format (append-only under the Ideas section)

Each idea gets an ID and a domain tag:

I001 [Core] <short title> — <1-sentence description>
     Novelty: <why it’s different / why it matters>

Rules:
- IDs are zero-padded and strictly increasing: I001, I002, …
- Domain tag must be one of: [Core] [UX] [DX] [Ops] [Biz] [Edge] [Eco] [A11y] [Perf] [Sec] [Comm] [Docs]
- Do NOT invent ideas. Only record ideas the human supplies.
- You may rephrase for clarity, but preserve the human’s intent.

## Persistence + Chat Hygiene

- Always append captured ideas to `.deadf/seed/P2_BRAINSTORM.md`.
- After 30+ total ideas:
  - ensure the ledger file is fully up to date
  - in chat, NEVER reprint the full ledger
  - in chat, show only:
    - total idea_count
    - last 5 idea IDs + titles
    - current technique/lens
    - next pivot domain

## Rounds

Run Phase 3 in rounds:
- 5–10 ideas per round under one technique/lens.
- Spend ~5–8 exchanges per technique before rotating.

## When the human is stuck (do NOT generate ideas)

Offer choices:
- 3–5 lenses to pick from (e.g., UX, failure modes, pricing, integrations, security)
- A slot template:
  - user: ____
  - trigger: ____
  - value: ____
  - delivery: ____
- Ask: “Want 2 example seeds to warm up?”
  - Only provide example seeds if they explicitly opt in.

## Ledger file structure (recommended)

- Header: project name (if known), date
- Session State (editable): one_sentence_pitch, domains_covered, techniques_used, idea_count
- Ideas (append-only)
- Themes (filled in Phase 4)
- Decisions (MoSCoW + sequencing)

```

### `.pipe/p2/P2_D.md`
```md
# P2_D — ORGANIZE (Phase 4)

Gate: enter ONLY when the human requests it OR (≥50 ideas AND energy dropping).

Steps:
1. Cluster ideas into 5–12 emergent themes.
   - You propose the first clustering.
   - Human validates/edits theme names and memberships.
2. Present themes in a scannable format with idea IDs under each theme.
3. MoSCoW prioritize per theme:
   - Must-have, Should-have, Could-have, Won’t-have (explicit non-goals)
4. Sequence Must-haves by:
   - dependencies first
   - risk next (hardest/riskiest earlier)
   - value next (highest value earlier)
5. Surface risks per theme:
   - “What’s the riskiest thing here? What could go wrong?”

Ask the optimization question (verbatim):
- “Are you optimizing for speed-to-MVP, technical ambition, or commercial viability?”

```

**Done when:**
- `ls .pipe/p2/` includes P2_B, P2_C, P2_D.

---

## Micro-task 3 (create prompts: P2_E, P2_F, P2_G)

**Files to add (3 max):**
- `.pipe/p2/P2_E.md`
- `.pipe/p2/P2_F.md`
- `.pipe/p2/P2_G.md`

**Write file contents exactly as follows:**

### `.pipe/p2/P2_E.md`
```md
# P2_E — CRYSTALLIZE (Phase 5)

Goal: synthesize the brainstorm + organization into crisp, reviewable statements.
Present each item for human approval/edit.

Produce (in chat, not files yet):
1. Vision Statement (1 paragraph): what this is and why it matters
2. Success Truths (5–12): observable, verifiable outcomes
3. Non-Goals (3–7): explicit exclusions
4. Constraints: tech stack, timeline, team, budget, platform
5. Key Risks (3–5): what could derail + mitigation ideas
6. Open Questions: unresolved items needing research

Keep everything specific and testable.
Then proceed to Phase 6 using `.pipe/p2/P2_F.md`.

```

### `.pipe/p2/P2_F.md`
```md
# P2_F — OUTPUT Writer (Phase 6)

Goal: write `VISION.md` and `ROADMAP.md` in deadf(ish) YAML-in-codefence style.

Rules:
- VISION.md must be ≤80 lines.
- ROADMAP.md must be ≤120 lines.
- Use the exact schemas below. Do not add extra top-level keys.
- Present both drafts for human approval; apply edits.
- Then write final files.

## VISION.md schema (exact)

```yaml
vision_yaml<=300t:
  problem:
    why: "<why this needs to exist>"
    pain: ["<pain point 1>", "<pain point 2>", ...]
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

## ROADMAP.md schema (exact)

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
    dependencies: []  # optional
    risks: []  # optional
milestones:
  - "<milestone description>"
risks:
  - "<project-level risk>"
definition_of_done:
  - "<overall completion criteria>"
```

Proceed to Phase 7 using `.pipe/p2/P2_G.md`.

```

### `.pipe/p2/P2_G.md`
```md
# P2_G — ADVERSARIAL REVIEW (Phase 7)

Forced “find issues” review. “Looks good” is NOT allowed.

Review BOTH `VISION.md` and `ROADMAP.md` drafts and produce 5–15 findings.

For each finding:
- Severity: HIGH / MED / LOW
- What’s missing/unclear
- Why it matters
- Concrete fix suggestion

Categories to check:
- completeness
- consistency (VISION ↔ ROADMAP)
- testability of success metrics / done_when
- scope creep risk / missing non-goals
- missing constraints
- dependency gaps

Then ask the human which fixes to apply.
Apply approved fixes and write final files.

```

**Done when:**
- `ls .pipe/p2/` includes P2_E, P2_F, P2_G.

---

## Micro-task 4 (add brainstorm session runner)

**Files to add (1 file):**
- `.pipe/p2-brainstorm.sh`

**Requirements:**
- Bash script, executable.
- Creates `.deadf/seed/` if missing.
- Uses `.pipe/p2/P2_MAIN.md` as the initial prompt for interactive Codex.
- Runs interactive Codex session using **GPT-5.2** (not `exec`). Use `codex -m gpt-5.2 ...`.
- On successful exit, validates that `VISION.md` and `ROADMAP.md` exist and are non-empty.
- Writes/touches `.deadf/seed/P2_DONE` when validation passes.
- Supports a `--project <path>` arg (default `.`), a `--force` flag to re-run even if `P2_DONE` exists, and a `--dry-run` flag that does not launch Codex.
- No dependencies beyond bash + coreutils + `codex`.

**Done when:**
- `bash -n .pipe/p2-brainstorm.sh` passes.
- `.pipe/p2-brainstorm.sh --project . --dry-run` exits 0.

---

## Micro-task 5 (modify ralph.sh to dispatch P2 during research)

**Files to modify (1 file):**
- `ralph.sh`

**Requirements:**
- When `STATE.yaml.phase == research` and `.deadf/seed/P2_DONE` is missing, run `.pipe/p2-brainstorm.sh --project "$PROJECT_PATH"` BEFORE kicking a Claude cycle.
- If the runner exits nonzero:
  - set `phase: needs_human` (using existing helper)
  - write a notification (using existing `notify`) with a clear message
  - exit nonzero
- If `P2_DONE` exists, proceed normally.
- Keep ralph “mechanical” — no decision logic beyond “if research then run P2 once”.

**Done when:**
- `bash -n ralph.sh` passes.
- `rg -n "P2_DONE|p2-brainstorm\.sh|\.deadf/seed" ralph.sh` shows the dispatch wiring.

---

## Micro-task 6 (modify CLAUDE.md to reference P2 phase)

**Files to modify (1 file):**
- `CLAUDE.md`

**Requirements:**
- Update the `seed_docs` action spec to reflect the new P2 behavior:
  - `seed_docs` is now **P2 Brainstorm Session**.
  - Claude Code must NOT attempt to generate seed docs automatically.
  - Deterministic rule: if `.deadf/seed/P2_DONE` is missing OR `VISION.md`/`ROADMAP.md` are missing, set `phase: needs_human` + write a notification instructing the operator to run the P2 brainstorm runner.
  - If `P2_DONE` exists and both docs exist, immediately set `phase: select-track` (no overwrites).
- Add a brief note somewhere appropriate that `.deadf/seed/` is the seed docs ledger directory.

**Done when:**
- `rg -n "P2|brainstorm|\.deadf/seed" CLAUDE.md` shows the new contract language.

---

## Final validation (after micro-task 6)

Run:
- `bash -n ralph.sh .pipe/p2-brainstorm.sh`
- `ls -la .pipe/p2/`

Manual sanity check:
- Start from a project root that has a `STATE.yaml` with `phase: research`.
- Run `./ralph.sh <project_root> interactive`.
- Confirm it launches the P2 interactive brainstorm session once, then proceeds into the normal loop.

