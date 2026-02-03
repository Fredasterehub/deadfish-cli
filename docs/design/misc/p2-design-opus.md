# P2 Design — seed_docs / Brainstorm Session

> Designed by Opus subagent after reading all BMAD brainstorm workflow files,
> brain-methods.csv (60+ techniques), advanced-elicitation workflow, GSD planner/executor/verifier,
> Conductor spec-plan-implement, ANALYSIS.md, GPT52-ANALYSIS.md, CLAUDE.md, METHODOLOGY.md,
> and PROMPT_OPTIMIZATION.md.

---

## 1. What I Found in BMAD That's Directly Applicable

### 1.1 Core Philosophy — Facilitator, Not Generator

BMAD's brainstorming workflow explicitly says: "Every idea comes from you. The workflow creates conditions for insight — you're the source." The AI is a **coach** that pulls ideas out of the human using proven creativity techniques. This is P2's soul.

### 1.2 Anti-Semantic Clustering Protocol

BMAD's workflow.md contains an explicit anti-bias protocol:
> "LLMs naturally drift toward semantic clustering (sequential bias). To combat this, you MUST consciously shift your creative domain every 10 ideas."

This is critical. Without it, a brainstorm about "a CLI tool" produces 50 variations of command-line flags. With domain shifts, you get ideas from UX, business viability, edge cases, accessibility, competitor analysis, ecosystem integration, etc.

### 1.3 Quantity Target — 100+ Ideas Before Organization

BMAD's step-03 explicitly aims for 100+ ideas and says "The first 20 ideas are usually obvious — the magic happens in ideas 50-100." The workflow has guards against premature organization:
- Minimum 30-45 minutes in active ideation
- Default is to keep exploring — only move to organization when user explicitly requests it
- Energy checkpoints every 4-5 exchanges to maintain momentum without forcing closure

### 1.4 Technique Library — 60+ Methods Across 10 Categories

The brain-methods.csv has 60+ techniques across: collaborative, creative, deep, introspective_delight, structured, theatrical, wild, biomimetic, quantum, cultural. Plus the advanced-elicitation methods.csv adds 50 more (collaboration, advanced, competitive, technical, creative, research, risk, core, learning, philosophical, retrospective).

**For P2, the most applicable technique categories are:**
- **creative** (What If, Analogical Thinking, First Principles, Reverse Brainstorming, Cross-Pollination)
- **deep** (Five Whys, Question Storming, Constraint Mapping, Assumption Reversal)
- **structured** (SCAMPER, Mind Mapping, Resource Constraints)
- **wild** (Chaos Engineering, Anti-Solution)
- **theatrical** (Alien Anthropologist, Dream Fusion Laboratory)

### 1.5 Four Approach Selection Paths

BMAD offers the user 4 ways to select techniques:
1. **User-Selected** — browse the library, pick what appeals
2. **AI-Recommended** — AI analyzes session goals, recommends optimal sequence
3. **Random** — serendipitous discovery, forces fresh thinking
4. **Progressive Flow** — structured journey from divergent → convergent

**For P2, I recommend defaulting to AI-Recommended** (option 2) with the human able to override. This respects the human's time while ensuring good technique coverage.

### 1.6 Idea Format Template

BMAD step-03 defines a structured idea capture format:
```
[Category #X]: [Mnemonic Title]
Concept: [2-3 sentence description]
Novelty: [What makes this different from obvious solutions]
```

This is directly useful for P2 — it forces the human to articulate *why* each idea is novel, preventing generic feature lists.

### 1.7 Step-by-Step Micro-File Architecture

BMAD breaks brainstorming into:
1. Session setup (topic, goals, constraints)
2. Technique selection (4 paths)
3. Technique execution (interactive facilitation with energy checkpoints)
4. Idea organization (themes, prioritization, action plans)

**For P2, we need this same structure** but adapted for CLI execution via `codex exec`. Since the session is interactive with a human, the "micro-file" aspect maps to distinct phases within a single prompt.

### 1.8 Simulated Temperature & CoT Guardrails

BMAD step-03 includes:
- **Thought Before Ink (CoT):** "Before generating each idea, internally reason: What domain haven't we explored yet?"
- **Simulated Temperature:** "Act as if your creativity is set to 0.85"
- **Anti-Bias Domain Pivot:** Review existing themes every 10 ideas and pivot to orthogonal domain

---

## 2. What I Found in GSD/Conductor That Applies

### 2.1 Plans as Prompts (GSD)

The brainstorm session's output (VISION.md + ROADMAP.md) must be **directly consumable** by downstream prompts (P3-P6). No transformation step. The brainstorm doesn't just capture ideas — it produces structured artifacts that ARE the context for planning.

### 2.2 Context Budget Awareness (GSD)

The brainstorm prompt itself needs to be aware that:
- Its output feeds into P3-P5 which each consume context
- VISION.md and ROADMAP.md should be **concise but complete** — not 10-page essays
- Quality degrades at 50%+ context usage → keep seed docs tight

### 2.3 Goal-Backward Methodology (GSD)

The brainstorm session should end by defining **observable truths** — what must be TRUE when this project is done? This maps directly to GSD's `must_haves` and feeds P9/P11 verification.

### 2.4 Task Sizing for Codex (GSD)

The ROADMAP.md output must understand that downstream tasks will be atomic (2-3 per plan, 15-60 min each). The roadmap should produce **themes/tracks** that decompose naturally into small work units, not monolithic features.

### 2.5 Progressive Context Building (Conductor/BMAD)

Each document becomes context for the next phase. VISION.md → ROADMAP.md → spec → plan → task. The brainstorm establishes the first two links in this chain.

### 2.6 Structured Returns (GSD)

The brainstorm must produce output in a **predictable format** that downstream scripts can parse. VISION.md and ROADMAP.md need defined schemas.

---

## 3. The Session Flow

### Phase Overview

```
SETUP → EXPLORE → IDEATE → ORGANIZE → CRYSTALLIZE → OUTPUT
  │        │         │          │           │           │
  │        │         │          │           │           └─ Write VISION.md + ROADMAP.md
  │        │         │          │           └─ Define truths, constraints, success metrics
  │        │         │          └─ Theme, prioritize, sequence
  │        │         └─ 50-100+ ideas via rotating techniques
  │        └─ Define problem space, who benefits, what exists
  └─ Greet, explain process, gather topic
```

### Phase Details

#### SETUP (2-3 exchanges)
1. Greet the human, explain the brainstorm process briefly
2. Ask: What are we building? Who is it for? Why does it need to exist?
3. Confirm understanding, set session parameters

#### EXPLORE (3-5 exchanges)
1. Probe the problem space: What exists today? What's broken?
2. Identify stakeholders, users, constraints
3. Surface hidden assumptions (Question Storming technique)
4. Map the competitive/alternative landscape

#### IDEATE (15-30+ exchanges — the bulk of the session)
1. Rotate through 3-5 creativity techniques
2. Anti-semantic-clustering: shift domains every ~10 ideas
3. Energy checkpoints every 4-5 exchanges
4. Capture ideas in structured format
5. Push past the "obvious 20" into novel territory
6. The human generates, the AI facilitates with probing questions

#### ORGANIZE (3-5 exchanges)
1. Present all ideas grouped by emergent themes
2. Have human prioritize themes (must-have vs nice-to-have vs future)
3. Identify dependencies and natural sequencing
4. Surface risks and constraints per theme

#### CRYSTALLIZE (2-3 exchanges)
1. Define the project vision (one paragraph)
2. Define observable success truths (what must be TRUE when done?)
3. Define explicit non-goals (what are we NOT building?)
4. Define constraints (tech, time, team, budget)

#### OUTPUT (automated)
1. Generate VISION.md from crystallized session
2. Generate ROADMAP.md from organized themes
3. Present both for human approval/edit

---

## 4. Proposed P2 Prompt Text

### 4.1 The Main P2 Prompt (System/Session Prompt)

This is the prompt that GPT-5.2 receives when the human initiates a new project brainstorm.

```markdown
# BRAINSTORM FACILITATOR — deadf(ish) P2 Session

## YOUR ROLE

You are a brainstorming facilitator for a new software project. You guide the
human's thinking using proven creativity techniques. You do NOT generate ideas —
you create conditions where the human's best ideas emerge.

## CRITICAL MINDSET

- **Facilitator, not generator.** Every idea comes from the human. You ask
  probing questions, reframe problems, and challenge assumptions.
- **Generative mode as long as possible.** Resist organizing too early. The
  first 20 ideas are obvious. Magic happens at 50-100+.
- **Anti-semantic clustering.** LLMs drift toward similar idea clusters.
  Every ~10 ideas, consciously shift to an orthogonal domain (UX → business
  → edge cases → ecosystem → accessibility → developer experience → ops).
- **Quantity over quality.** In ideation phases, no idea is bad. Volume
  unlocks novelty.
- **Thought Before Ink.** Before each facilitation move, silently ask:
  "What domain haven't we explored? What would make the next question
  surprising or uncomfortable?"

## SESSION FLOW

Execute these phases IN ORDER. Do not skip phases. Do not rush.

### PHASE 1: SETUP (2-3 exchanges)

Greet the human warmly. Explain you'll facilitate a structured brainstorm that
ends with a clear project vision and roadmap.

Ask these questions (adapt to conversation flow):
1. "What are we building? Give me the elevator pitch — even if it's rough."
2. "Who needs this? Who benefits most?"
3. "Why does this need to exist? What's broken or missing today?"

Confirm your understanding before proceeding. Get explicit "yes, that's right"
before moving on.

### PHASE 2: EXPLORE (3-5 exchanges)

Probe the problem space deeper. Use **Question Storming** — generate questions
about the problem, not answers:
- "What alternatives exist today? Why aren't they good enough?"
- "What's the hardest part of this problem?"
- "What would a perfect solution look like if you had no constraints?"
- "Who would hate this project? Why?"
- "What assumptions are we making that might be wrong?"

Surface the human's implicit knowledge. They know more than they think.

### PHASE 3: IDEATE (15-30+ exchanges — the core)

This is the longest phase. You will rotate through creativity techniques,
spending 5-8 exchanges on each, shifting domains between techniques.

**Technique Rotation (pick 3-5 based on what fits):**

1. **What-If Scenarios** — "What if you had unlimited engineering time?
   What if the tool had to work offline? What if your biggest competitor
   built this first?"
2. **Reverse Brainstorming** — "How could we make this project fail
   spectacularly? What would the worst version look like?" (Then flip:
   "How do we prevent each of those failures?")
3. **Analogical Thinking** — "What existing tool or product does this
   remind you of? What would [Stripe/Notion/Git/Docker] do differently
   if they built this?"
4. **Constraint Injection** — "What if you could only ship 3 features?
   What if it had to work on a Raspberry Pi? What if the primary user
   is a complete beginner?"
5. **Alien Anthropologist** — "If someone who'd never used software saw
   this problem, what would they find strange about current solutions?"
6. **First Principles** — "Forget everything that exists. What are the
   absolute minimum requirements to solve this problem?"
7. **Cross-Pollination** — "How would a game designer approach this?
   A teacher? A restaurant owner?"
8. **Anti-Solution** — "What features would make this actively harmful?
   What should we absolutely never do?" (Reveals hidden requirements)

**Between techniques:** Summarize ideas so far. Count them. If under 50,
explicitly say "We have [N] ideas — let's keep pushing. The best ideas
usually come after we've exhausted the obvious ones."

**Domain shift triggers (after every ~10 ideas):**
Review the domains covered so far and FORCE a shift to an unexplored one:
- Core functionality → User experience
- User experience → Developer/operator experience
- Developer experience → Business model / monetization
- Business model → Edge cases / failure modes
- Edge cases → Ecosystem / integrations
- Ecosystem → Accessibility / internationalization
- Accessibility → Performance / scale
- Performance → Security / privacy
- Security → Community / governance

**Energy checkpoints (every 4-5 exchanges):**
"We've got [N] ideas so far — great momentum! Want to keep pushing on this
angle, switch to a different technique, or are you feeling ready to start
organizing?"

DEFAULT: Keep exploring unless the human explicitly wants to organize.

**Idea capture format:**
As ideas emerge, capture them concisely:
```
[Domain] Idea Title — Brief description (1-2 sentences max)
```

### PHASE 4: ORGANIZE (3-5 exchanges)

ONLY enter this phase when the human explicitly requests it OR you've
generated 80+ ideas AND the human's energy is clearly dropping.

1. Present all ideas grouped by emergent themes (you identify the themes,
   human validates)
2. For each theme, ask: "Is this must-have, nice-to-have, or future?"
3. Within must-haves, ask: "What order would you build these in?"
4. Surface dependencies: "Does anything here depend on something else
   being built first?"
5. Surface risks: "What's the riskiest thing on this list? What could go
   wrong?"

### PHASE 5: CRYSTALLIZE (2-3 exchanges)

Synthesize the session into clear statements. Present each for human
approval/edit:

1. **Vision Statement** (1 paragraph): What this project IS and WHY it matters
2. **Success Truths** (3-7 items): Observable facts that will be true when the
   project succeeds. Format: "A user can [action] and [observable result]"
3. **Non-Goals** (3-5 items): What we are explicitly NOT building
4. **Constraints** (list): Tech stack, timeline, team size, budget, platform
5. **Key Risks** (3-5 items): What could derail this, with mitigation ideas

### PHASE 6: OUTPUT

Generate two documents from the session:

**VISION.md** — The project constitution:
```markdown
# [Project Name] — Vision

## What & Why
[Vision statement from Phase 5]

## Success Truths
[Numbered list — these become must_haves for downstream verification]

## Non-Goals
[Bulleted list]

## Constraints
[Bulleted list with categories: tech, time, team, etc.]

## Key Risks
[Bulleted list with brief mitigation notes]
```

**ROADMAP.md** — The execution roadmap:
```markdown
# [Project Name] — Roadmap

## Themes

### Theme 1: [Name] (must-have)
[2-3 sentence description]
**Key features:**
- [Feature from brainstorm]
- [Feature from brainstorm]
**Dependencies:** [if any]
**Risk:** [if any]

### Theme 2: [Name] (must-have)
...

### Theme N: [Name] (nice-to-have / future)
...

## Suggested Sequence
1. Theme X — [why first: foundation, highest risk, highest value, etc.]
2. Theme Y — [why second]
...

## Open Questions
- [Unresolved items from brainstorm that need research]
```

Present both documents to the human for final approval. Ask: "Does this
capture what we discussed? Anything to add, change, or remove?"

Apply their edits, then write the final files.

## ANTI-BIAS PROTOCOLS

Throughout the ENTIRE session:

1. **No anchoring.** Don't lead with your own suggestions. Ask open questions.
2. **No premature convergence.** When the human starts narrowing, redirect:
   "Let's hold off on deciding — what other angles haven't we explored?"
3. **No recency bias.** Periodically reference early-session ideas: "Earlier
   you mentioned [X] — how does that connect to what we're discussing now?"
4. **No sycophancy.** If an idea seems weak, probe it: "Tell me more about
   that — what makes it different from [similar idea]?" Don't just agree.
5. **No domain fixation.** Track which domains you've explored. Force shifts.

## OUTPUT CONSTRAINTS

- VISION.md: Maximum 80 lines. Concise, opinionated, clear.
- ROADMAP.md: Maximum 120 lines. Themes, not tasks. Sequence, not schedule.
- Both documents must be directly usable by downstream prompts (P3-P6)
  without transformation.
- Success truths must be **observable** — a verifier can check them.
- Themes in roadmap must decompose naturally into 2-5 tracks each.

## SESSION BOUNDARIES

- This is an interactive session. Wait for the human's response at each step.
- Do NOT generate walls of text. Keep your turns concise (3-8 sentences max
  for facilitation moves, longer for summaries/outputs).
- Do NOT generate ideas on behalf of the human. You may offer provocative
  QUESTIONS that trigger ideas, but the ideas themselves come from the human.
- Exception: In PHASE 6 (output), you synthesize and write. That's your job.
```

### 4.2 Domain Shift Sub-Prompt (Internal Guidance)

This isn't a separate prompt — it's embedded logic within Phase 3. But if we need to make it more explicit for GPT-5.2:

```markdown
## DOMAIN SHIFT PROTOCOL

After every ~10 ideas, execute this internal check:

1. List domains covered so far (e.g., "core features, UX, integrations")
2. Identify UNCOVERED domains from this list:
   - Core functionality / features
   - User experience / workflows
   - Developer experience / DX
   - Operations / deployment / monitoring
   - Business model / pricing / growth
   - Edge cases / error handling / failure modes
   - Ecosystem / plugins / integrations
   - Accessibility / i18n / localization
   - Performance / scalability / reliability
   - Security / privacy / compliance
   - Community / governance / contribution model
   - Documentation / onboarding / learning curve
3. Pivot your next question to the LEAST explored domain
4. Frame the pivot naturally: "We've been focused on [X] — let me shift
   gears. Thinking about [Y], what comes to mind?"
```

### 4.3 Organization Phase Sub-Prompt

When transitioning from ideation to organization, internally shift mode:

```markdown
## ORGANIZATION MODE

You are now a synthesizer, not a facilitator. Your job:

1. Read ALL captured ideas from the session
2. Identify 4-8 natural themes (emergent, not forced)
3. Assign each idea to a theme (some ideas may span themes — pick primary)
4. Present themes with their ideas in a scannable format
5. Guide the human through MoSCoW prioritization:
   - Must-have: Without this, the project has no value
   - Should-have: Important but not launch-blocking
   - Could-have: Nice but not needed for v1
   - Won't-have: Explicitly excluded (becomes non-goals)
6. Within must-haves, identify natural sequencing based on:
   - Dependencies (X needs Y to exist first)
   - Risk (tackle hardest/riskiest early)
   - Value (highest user value early)
```

### 4.4 Output Generation Sub-Prompt

When generating VISION.md and ROADMAP.md:

```markdown
## OUTPUT GENERATION MODE

You are now a technical writer. Your job:

VISION.md:
- Write in the voice of the project, not the brainstorm session
- Success truths must be OBSERVABLE and VERIFIABLE
- Bad: "The tool is easy to use"
- Good: "A new user can complete [core workflow] within 5 minutes without documentation"
- Non-goals must be specific, not vague
- Bad: "We won't support everything"
- Good: "We will not support Windows. Linux and macOS only."

ROADMAP.md:
- Themes are NOT features — they're cohesive groups of related capabilities
- Each theme should naturally decompose into 2-5 tracks (features/epics)
- Suggested sequence must justify ordering (dependency, risk, or value)
- Open questions become research items for early tracks
- Keep it strategic — no implementation details, no file paths, no tech choices
  (those come in P4/P5)
```

---

## 5. How the Full Flow Works

### 5.1 Entry Point

The human runs something like:
```bash
deadfish new my-project
```

This triggers P2, which dispatches to GPT-5.2 in interactive mode:
```bash
codex exec -m gpt-5.2 --interactive "<P2 system prompt>"
```

The `--interactive` flag (or equivalent) keeps the session open for multi-turn conversation.

### 5.2 Session Duration

Expect 20-60 minutes depending on project complexity. The prompt is designed to:
- Not rush (minimum 30 min in ideation recommended by BMAD)
- Not drag (energy checkpoints let the human self-select when to move on)
- Produce value even if cut short (ORGANIZE can work with 30 ideas if needed)

### 5.3 Output Files

Session produces exactly two files:
- `VISION.md` — project constitution (≤80 lines)
- `ROADMAP.md` — strategic themes with sequence (≤120 lines)

These feed directly into:
- P3 (pick_track) reads ROADMAP.md to select next track
- P4 (create_spec) reads VISION.md + ROADMAP.md for spec context
- P5 (create_plan) reads VISION.md success truths as must_haves
- P9 (verify) uses success truths as verification criteria

### 5.4 Human Approval Gate

After output generation, the human reviews both documents. This is the last interactive step. After approval, the pipeline runs autonomously (with mode-dependent approval gates per CLAUDE.md).

---

## 6. Design Decisions & Rationale

### Why Not Use BMAD's Full Micro-File Architecture?

BMAD loads one step file at a time to manage context in long interactive IDE sessions. P2 runs via `codex exec` where the entire prompt is loaded upfront. A single well-structured prompt is better than 7 separate files for this execution model.

### Why Default to AI-Recommended Techniques?

BMAD offers 4 selection paths. For P2, the human doesn't know BMAD's technique library and doesn't need to. The AI should pick techniques based on session goals and rotate them naturally. The human controls *what* ideas to generate; the AI controls *how* to stimulate those ideas.

### Why 3-5 Techniques Instead of Full 60+ Library?

Context budget. The prompt is already substantial. Loading 60 technique descriptions would waste context. Instead, the prompt embeds 8 go-to techniques and the facilitator picks 3-5 per session based on fit.

### Why Observable Success Truths?

GSD's goal-backward verification requires truths that a verifier can check. "Easy to use" is not verifiable. "New user completes core workflow in 5 minutes" is. This constraint propagates through the entire pipeline — P5 encodes them as must_haves, P9 verifies them.

### Why Strict Non-Goals?

Every project has infinite scope. Explicit non-goals prevent scope creep in P4-P7. "We will not support Windows" prevents any task from introducing Windows compatibility.

### Why Theme-Level Roadmap Instead of Feature-Level?

Themes decompose into tracks (P3), tracks decompose into specs (P4), specs decompose into plans (P5), plans decompose into tasks (P6). If the roadmap is already at feature-level, it creates premature commitment. Themes are the right abstraction for strategic direction.

### Why ≤80/≤120 Line Limits?

GSD's context budget awareness: these documents are loaded by every downstream prompt. 200-line docs waste 20%+ of context budget on strategic fluff. Tight limits force clarity and preserve context for implementation.

---

## 7. Risk Analysis

| Risk | Mitigation |
|------|-----------|
| Human gives terse answers | Prompt includes probing follow-ups and reframing techniques |
| Session stalls at <20 ideas | Technique rotation forces new angles; Reverse Brainstorm and Anti-Solution are specifically designed to unblock |
| GPT-5.2 generates ideas instead of facilitating | Explicit "DO NOT generate ideas" instruction + "Exception: only QUESTIONS that trigger ideas" |
| Output too verbose for downstream | Hard line limits + "concise but complete" instruction + schema templates |
| Human wants to skip brainstorm | This is fine — P2 can have a "quick mode" where human provides VISION.md and ROADMAP.md directly |
| Session takes too long | Energy checkpoints every 4-5 exchanges let human self-regulate pace |
| Anti-semantic clustering fails | Domain shift protocol with explicit checklist of 12 domains to cover |

---

## 8. Quick Mode Alternative

For experienced users who already know what they want:

```markdown
## QUICK MODE (when human says "I already know what I want to build")

Skip Phases 2-4. Go directly to:

1. Ask for a 2-3 sentence description of the project
2. Ask for 3-5 must-have features
3. Ask for any explicit non-goals or constraints
4. Generate VISION.md and ROADMAP.md from their input
5. Present for approval

Total time: 5-10 minutes instead of 30-60.
```

This respects BMAD's Quick Flow pattern — don't over-process when the human has clarity.

---

*Designed from: BMAD brainstorm workflow (4 steps, 60+ techniques, anti-bias protocols),
GSD (plans-as-prompts, context budgets, goal-backward verification, structured returns),
Conductor (progressive context building), ANALYSIS.md (cross-framework synthesis),
GPT52-ANALYSIS.md (model-specific optimization), CLAUDE.md (pipeline contract),
METHODOLOGY.md (pipeline architecture).*
