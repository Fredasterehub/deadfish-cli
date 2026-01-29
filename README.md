# deadf(ish) 🐟💀

A development pipeline that doesn't let things slip through the cracks.

**GSD + Conductor hybrid** - Combines Get Shit Done's execution spine with Google Conductor's learning loops.

## Philosophy

Most AI coding workflows fail in predictable ways:
- Skip straight to code, miss requirements
- Plan everything upfront, can't adapt
- No learning loop, same mistakes repeated
- Validation is vibes, not contracts

**deadf(ish)** fixes this:

| Problem | Solution |
|---------|----------|
| Rushing to code | Brainstorm → Research → Plan → Execute |
| Rigid upfront planning | Incremental tracks, one feature at a time |
| No learning | Reflect on ALL outcomes (success, failure, escalation) |
| Vague validation | Contract citations, clause IDs, 3-try rule |

## Quick Start

### With Claude Code

1. Clone this repo
2. Copy `CLAUDE.md` to your project root
3. Start with `/deadf:init myproject`

### Manual Setup

1. Copy `templates/` to your project
2. Follow `METHODOLOGY.md` for the workflow
3. Use templates to create your docs

## Commands

| Command | Purpose |
|---------|---------|
| `/deadf:init <name>` | Initialize project structure |
| `/deadf:brainstorm` | Discover vision interactively |
| `/deadf:research` | Research stack, patterns, pitfalls |
| `/deadf:track <name>` | Start a new feature/fix track |
| `/deadf:task` | Generate next task from plan |
| `/deadf:execute` | Implement current task |
| `/deadf:verify` | Validate against contracts |
| `/deadf:reflect` | Post-outcome analysis + doc updates |
| `/deadf:status` | Show current position |
| `/deadf:next` | Task → Execute → Verify → Reflect |

## Document Architecture

```
project/
├── VISION.md              # Constitution (static)
├── PRODUCT.md             # Goals, users, metrics (living)
├── TECH_STACK.md          # Stack decisions (living)
├── WORKFLOW.md            # Process rules (living)
├── PATTERNS.md            # Blessed patterns (living)
├── PITFALLS.md            # Known traps (living)
├── RISKS.md               # Proactive risks (living)
├── GLOSSARY.md            # Term definitions (living)
├── ROADMAP.md             # Themes + next tracks (thin)
├── STATE.md               # Current position
├── TASK.md                # Current task
├── tracks.md              # Track index
└── tracks/<id>/
    ├── spec.md            # Track specification
    ├── plan.md            # Task breakdown
    └── log.md             # Decisions + learnings
```

### Document Hierarchy

| Layer | Role | Updates |
|-------|------|---------|
| **Constitution** | VISION.md | Only via pivot record |
| **Living Docs** | PRODUCT, TECH_STACK, WORKFLOW, PATTERNS, PITFALLS, RISKS | After successful tasks |
| **Execution** | STATE, TASK, ROADMAP | Continuously |
| **Tracks** | Per-feature specs, plans, logs | During track |

## Core Concepts

### Tracks (not Phases)

Instead of planning all phases upfront, work in **tracks** - one feature at a time:

1. Write spec for ONE track
2. Plan tasks for that track
3. Execute tasks
4. Reflect and update docs
5. Move to next track

### Living Documentation

Docs evolve as you learn:
- **Success** → Consider pattern promotion
- **Failure** → Add to pitfalls/risks
- **Escalation** → Update contracts

Updates are **diffs, not prose** - concrete patches that get reviewed.

### Contract Citations

When validating or disputing, cite specific clauses:
- `VISION.V1` - First vision clause
- `WORKFLOW.W3` - Third workflow rule
- `PATTERNS.P2` - Second blessed pattern
- `SPEC.S1` - First acceptance criterion

No citation = discretionary issue = default to proposer.

### 3-Try Rule

All validation checkpoints:
1. First try
2. Second try (address feedback)
3. Third try (final)
4. Escalate to human

**Clarification step** (asking for more info) doesn't count toward tries.

## Workflow

```
┌─────────────────────────────────────────┐
│           INITIALIZE                     │
│  brainstorm → research → seed docs      │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│           PER-TRACK LOOP                 │
├──────────────────────────────────────────┤
│  Write spec → Validate                   │
│  Write plan → Validate                   │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │         TASK LOOP                  │  │
│  ├────────────────────────────────────┤  │
│  │  Generate task                     │  │
│  │  Execute                           │  │
│  │  Verify                            │  │
│  │  Reflect ← ALL outcomes            │  │
│  │  Update living docs                │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Mark track done, freeze spec            │
└──────────────────────────────────────────┘
```

## Reflection Routing

| Outcome | Route To |
|---------|----------|
| ✅ Success | PATTERNS (if new approach used 2+ times) |
| ❌ Failure | PITFALLS (one-off) or RISKS (systemic) |
| ⏫ Escalation | Contract updates (missing/ambiguous clauses) |

**Key insight**: Most learning comes from failures and escalations, not successes.

## Installation

```bash
# Clone
git clone https://github.com/fredastere/deadfish-cli.git

# Copy to your project
cp deadfish-cli/CLAUDE.md ./your-project/
cp -r deadfish-cli/templates ./your-project/

# Or just copy CLAUDE.md for Claude Code
```

## Templates

All document templates in `templates/`:
- `vision-template.md`
- `product-template.md`
- `tech-stack-template.md`
- `workflow-template.md`
- `patterns-template.md`
- `pitfalls-template.md`
- `risks-template.md`
- `roadmap-template.md`
- `state-template.md`
- `track-spec-template.md`
- `track-plan-template.md`
- `track-log-template.md`
- `task-template.md`
- `glossary-template.md`

## Contributing

This pipeline evolves through use. If you find improvements:
1. Open an issue describing the problem
2. Propose a solution (preferably with diff)
3. We'll integrate and credit

## Credits

- **GSD (Get Shit Done)** - Execution spine inspiration
- **Google Conductor** - Learning loops, living docs
- Built with Claude + GPT collaboration

## Recent Changes

<!-- AUTO-GENERATED: run ./scripts/update-changelog.sh to refresh -->

| Commit | Change |
|--------|--------|
| `adddf1f` | **feat(brownfield):** Convert all templates to machine-optimized YAML format |
| `b78ebfc` | **feat(brownfield):** Add brownfield/returning init flows and context budget |
| `c62725a` | **fix:** Accurate Codex MCP tool syntax |
| `56434f2` | **feat:** Add Codex MCP integration for multi-model support |
| `60351f1` | **feat:** Add parallel reflection analysis |
| `a64b29a` | **feat:** Initial deadf(ish) pipeline release |

<!-- END AUTO-GENERATED -->

## License

MIT

---

*Only dead fish follow the flow.* 🐟💀
