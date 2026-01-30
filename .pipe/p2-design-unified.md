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
