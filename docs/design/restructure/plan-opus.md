# Restructuring Plan — deadf(ish) CLI Pipeline

> Author: Claude Opus 4.5 (subagent)
> Date: 2026-02-02
> Status: PROPOSAL — requires Fred's approval before execution

---

## Problem Statement

CLAUDE.md is 1,240 lines. It should be ~200-300. The `.pipe/` directory mixes canonical templates with design artifacts, reviews, and working docs. Prompt names (P1-P12) are opaque without context. Scripts (`extract_plan.py`, `verify.sh`, `ralph.sh`) don't match the contracts they're supposed to implement.

This plan addresses all four problems in a coordinated restructuring.

---

## A) CLAUDE.md Split Strategy

### Current CLAUDE.md Anatomy (1,240 lines)

| Section | Lines (approx) | Disposition |
|---------|----------------|-------------|
| Identity + Setup (MCP config) | ~50 | **STAYS** (trimmed) |
| Cycle Protocol (Steps 1-6) | ~80 | **STAYS** (skeleton) |
| DECIDE table | ~25 | **STAYS** |
| Action Specifications (all 14 actions) | ~450 | **MOVES** → `.claude/rules/` |
| Task Management Integration (§1-6) | ~180 | **MOVES** → `.claude/rules/` |
| Sentinel Parsing (formats, grammars, examples) | ~150 | **MOVES** → `.claude/rules/` |
| P10 3-Tier Escalation | ~80 | **MOVES** → `.claude/rules/` |
| Stuck Detection | ~30 | **MOVES** → `.claude/rules/` |
| Notifications | ~30 | **MOVES** → `.claude/rules/` |
| State Write Authority | ~20 | **STAYS** |
| Model Dispatch Reference | ~25 | **STAYS** (table only) |
| Safety Constraints | ~15 | **STAYS** |
| Quick Reference + Sub-Agent Dispatch | ~40 | **STAYS** (trimmed) |
| Cycle Kick / Launcher details | ~50 | **MOVES** → `.claude/rules/` |

### Target: CLAUDE.md ≤ 280 lines

**What stays in CLAUDE.md (~280 lines):**

```
1. Identity block (who you are, what you do/don't do)        ~20 lines
2. MCP setup (minimal — .mcp.json pointer + tool table)      ~20 lines
3. Cycle Protocol skeleton (6 steps, 1-2 lines each)         ~40 lines
4. DECIDE table (full, with precedence note)                  ~30 lines
5. Action dispatch index (action → rule file pointer)         ~30 lines
6. State Write Authority table                                ~20 lines
7. Model Dispatch Reference table                             ~25 lines
8. Safety Constraints (10 rules)                              ~20 lines
9. Quick Reference (cycle flow ASCII art)                     ~15 lines
10. @imports or pointers to rule files                        ~10 lines
```

**What moves to `.claude/rules/` (auto-loaded by Claude Code):**

| Rule File | Content | Source Lines |
|-----------|---------|-------------|
| `action-research.md` | `seed_docs` + P12 codebase mapper specs | ~40 |
| `action-select-track.md` | `pick_track` + `create_spec` + `create_plan` | ~80 |
| `action-execute.md` | `generate_task` + `implement_task` + `verify_task` + `reflect` (including P9.5) | ~300 |
| `action-qa-review.md` | `qa_review` spec + state transitions | ~60 |
| `action-recovery.md` | `retry_task` + `replan_task` + `rollback_and_escalate` + `escalate` + `summarize` | ~50 |
| `sentinel-grammars.md` | All sentinel formats (PLAN, TRACK, SPEC, VERDICT, REFLECT, QA_REVIEW) + parsing rules | ~120 |
| `task-management.md` | Task naming convention, recovery/backfill algorithm, gate mechanics | ~150 |
| `escalation-p10.md` | P10 3-tier escalation protocol | ~80 |
| `notifications.md` | Mode-dependent notification table + file format | ~30 |
| `stuck-detection.md` | Stuck detection triggers + plan disposability | ~30 |
| `launcher.md` | Cycle kick details, dual-lock model, task list lifecycle | ~50 |

### Import Strategy

Claude Code auto-loads all files in `.claude/rules/*.md`. This means:

1. **No `@import` directives needed** — everything in `.claude/rules/` is always available
2. **No path-specific YAML frontmatter needed** — all rules apply repo-wide
3. **CLAUDE.md becomes a concise index** that references rule files by name for human navigation but doesn't need to `@import` them

**Key design decision:** Rule files are self-contained. Each file starts with a brief context header ("This rule covers action X, triggered when...") so it's useful even if read in isolation. Cross-references use the pattern: "See `sentinel-grammars.md` for block format."

### Why NOT enriched templates?

Considered moving action specs into the prompt templates themselves (e.g., putting the `generate_task` orchestrator procedure into `P6_GENERATE_TASK.md`). Rejected because:

1. Templates are prompts for **other models** (GPT-5.2, Codex). The action specs are instructions for **Claude Code** (the orchestrator). Mixing actor instructions creates confusion.
2. Templates get injected into LLM calls — orchestrator procedure bloat wastes tokens.
3. `.claude/rules/` is purpose-built for this: instructions that Claude Code should always have available.

### Migration: CLAUDE.md v2.4.2 → v3.0

The new CLAUDE.md skeleton:

```markdown
# CLAUDE.md — deadf(ish) Iteration Contract v3.0

> Binding contract for Claude Code orchestrator.
> Rules in `.claude/rules/` are auto-loaded and part of this contract.

## Identity
[~20 lines, unchanged]

## Setup: Multi-Model via Codex MCP
[~20 lines, trimmed to essentials]

## Cycle Protocol
[~40 lines — 6 steps, each 3-5 lines with just the key rule]

## DECIDE Table
[~30 lines, unchanged]

## Action Index
| Action | Rule File | Trigger |
|--------|-----------|---------|
| seed_docs | action-research.md | phase: research |
| pick_track | action-select-track.md | phase: select-track, no track |
| ... | ... | ... |

## State Write Authority
[~20 lines, unchanged]

## Model Dispatch
[~25 lines, table only]

## Safety Constraints
[~20 lines, unchanged]

## Quick Reference
[~15 lines, ASCII flow diagram]
```

---

## B) File Structure Reorganization

### Current Structure (problems annotated)

```
deadfish-cli/
├── CLAUDE.md                          # 1240 lines (too big)
├── ralph.sh                           # OK
├── verify.sh                          # OK (but contract mismatch)
├── extract_plan.py                    # OK (but scope too narrow)
├── build_verdict.py                   # OK
├── POLICY.yaml                        # OK
├── ROADMAP.md                         # OK
├── VISION.md                          # OK
├── METHODOLOGY.md                     # design artifact, not runtime
├── PROMPT_OPTIMIZATION.md             # design artifact, not runtime
├── README.md                          # OK
├── llms.txt                           # OK
├── .mcp.json                          # OK
├── .pipe/                             # MESS — everything in here
│   ├── p1/                            # canonical templates ✓
│   ├── p2/                            # canonical templates ✓
│   ├── p2-brainstorm.sh               # script, should be with other scripts
│   ├── p2-codex-prompt.md             # design artifact, not canonical
│   ├── p2-design-gpt52.md             # design artifact
│   ├── p2-design-opus.md              # design artifact
│   ├── p2-design-unified.md           # design artifact
│   ├── p2-review-opus.md              # review artifact
│   ├── p2-p5-restructure-opus.md      # design artifact
│   ├── p3/                            # canonical template ✓
│   ├── p4/                            # canonical template ✓
│   ├── p5/                            # canonical template ✓
│   ├── p6/                            # canonical template ✓
│   ├── p7/                            # canonical template ✓
│   ├── p9/                            # canonical template ✓
│   ├── p9.5/                          # canonical template ✓
│   ├── p10/                           # canonical templates ✓
│   ├── p11/                           # canonical template ✓
│   ├── p12-init.sh                    # script, mixed with templates
│   ├── p12/                           # scripts + templates mixed
│   ├── p12-codex-prompt.md            # design artifact
│   ├── p12-design-gpt52.md            # design artifact
│   ├── p12-design-opus.md             # design artifact
│   ├── p12-design-unified.md          # design artifact
│   ├── p12-review-opus.md             # review artifact
│   ├── reviews/                       # review artifacts
│   ├── codebase-analysis-gpt52.md     # analysis artifact
│   └── task-integration/              # design artifact (if exists)
├── examples/                          # OK
└── tests/                             # OK
```

### Proposed Structure

```
deadfish-cli/
├── CLAUDE.md                          # ≤280 lines (contract skeleton)
├── .claude/
│   └── rules/                         # auto-loaded by Claude Code
│       ├── action-research.md
│       ├── action-select-track.md
│       ├── action-execute.md
│       ├── action-qa-review.md
│       ├── action-recovery.md
│       ├── sentinel-grammars.md
│       ├── task-management.md
│       ├── escalation-p10.md
│       ├── notifications.md
│       ├── stuck-detection.md
│       └── launcher.md
│
├── templates/                         # canonical prompt templates (runtime)
│   ├── kick/
│   │   └── cycle-kick.md              # was P1_CYCLE_KICK.md
│   ├── research/
│   │   ├── brainstorm-main.md         # was P2_MAIN.md
│   │   ├── brainstorm-a.md            # was P2_A.md
│   │   ├── brainstorm-a2.md           # was P2_A2.md
│   │   ├── brainstorm-b.md            # was P2_B.md
│   │   ├── brainstorm-c.md            # was P2_C.md
│   │   ├── brainstorm-d.md            # was P2_D.md
│   │   ├── brainstorm-e.md            # was P2_E.md
│   │   ├── brainstorm-f.md            # was P2_F.md
│   │   ├── brainstorm-g.md            # was P2_G.md
│   │   ├── project-template.md        # was P2_PROJECT_TEMPLATE.md
│   │   ├── requirements-template.md   # was P2_REQUIREMENTS_TEMPLATE.md
│   │   └── roadmap-template.md        # was P2_ROADMAP_TEMPLATE.md
│   ├── select-track/
│   │   ├── pick-track.md              # was P3_PICK_TRACK.md
│   │   ├── create-spec.md             # was P4_CREATE_SPEC.md
│   │   └── create-plan.md             # was P5_CREATE_PLAN.md
│   ├── execute/
│   │   ├── generate-task.md           # was P6_GENERATE_TASK.md
│   │   └── implement-task.md          # was P7_IMPLEMENT_TASK.md
│   ├── verify/
│   │   └── verify-criterion.md        # was P9_VERIFY_CRITERION.md
│   ├── reflect/
│   │   └── reflect.md                 # was P9_5_REFLECT.md
│   ├── repair/
│   │   ├── format-repair.md           # was P10_FORMAT_REPAIR.md
│   │   └── auto-diagnose.md           # was P10_AUTO_DIAGNOSE.md
│   ├── qa/
│   │   └── qa-review.md               # was P11_QA_REVIEW.md
│   └── init/
│       ├── mapper-agent.md            # was p12/prompts/MAPPER_AGENT.md
│       ├── synthesizer.md             # was p12/prompts/SYNTHESIZER.md
│       ├── brownfield-brainstorm.md   # was p12/prompts/BROWNFIELD_P2.md
│       └── living-docs.tmpl           # was p12/templates/LIVING_DOCS.tmpl
│
├── scripts/                           # executable tooling
│   ├── ralph.sh                       # moved from root
│   ├── verify.sh                      # moved from root
│   ├── extract_plan.py                # moved from root
│   ├── build_verdict.py               # moved from root
│   ├── cron-kick.sh                   # was .pipe/p1/p1-cron-kick.sh
│   ├── brainstorm.sh                  # was .pipe/p2-brainstorm.sh
│   ├── init.sh                        # was .pipe/p12-init.sh
│   ├── init-detect.sh                 # was .pipe/p12/P12_DETECT.sh
│   ├── init-collect.sh                # was .pipe/p12/P12_COLLECT.sh
│   ├── init-map.sh                    # was .pipe/p12/P12_MAP.sh
│   ├── init-confirm.sh               # was .pipe/p12/P12_CONFIRM.sh
│   ├── init-inject.sh                 # was .pipe/p12/P12_INJECT.sh
│   └── budget-check.sh               # was .pipe/p12/p12-budget-check.sh
│
├── docs/                              # design artifacts, analysis, reviews
│   ├── design/
│   │   ├── p2-design-opus.md
│   │   ├── p2-design-gpt52.md
│   │   ├── p2-design-unified.md
│   │   ├── p2-codex-prompt.md
│   │   ├── p12-design-opus.md
│   │   ├── p12-design-gpt52.md
│   │   ├── p12-design-unified.md
│   │   ├── p12-codex-prompt.md
│   │   └── p2-p5-restructure-opus.md
│   ├── reviews/
│   │   ├── batch1-review.md
│   │   ├── batch2-review.md
│   │   ├── batch3-review.md
│   │   ├── batch4-review.md
│   │   ├── p6-review.md
│   │   ├── p6-final-review.md
│   │   ├── p6-post-fix-review.md
│   │   ├── p12-review-opus.md
│   │   ├── p2-review-opus.md
│   │   └── t10-review.md
│   ├── analysis/
│   │   └── codebase-analysis-gpt52.md
│   └── restructure/
│       └── plan-opus.md               # this file
│
├── POLICY.yaml
├── ROADMAP.md
├── VISION.md
├── METHODOLOGY.md
├── PROMPT_OPTIMIZATION.md
├── README.md
├── llms.txt
├── .mcp.json
├── examples/
│   └── project-structure.md
├── tests/
│   └── integration-test-results.md
└── .gitignore
```

### Key Decisions

1. **Templates live in `templates/`, NOT in `.claude/rules/`.** Rules are orchestrator instructions (for Claude Code). Templates are prompts for other models (GPT-5.2, Codex, sub-agents). Different audiences, different directories.

2. **Scripts move from root + scattered `.pipe/` locations into `scripts/`.** Single place for all executable tooling.

3. **`.pipe/` is eliminated entirely.** Its contents are split into `templates/`, `scripts/`, and `docs/`. The `.pipe/` directory was a catch-all that obscured what was canonical vs. working.

4. **Design/review artifacts move to `docs/`.** These are valuable history but not runtime components. Separating them reduces cognitive load when looking at what the pipeline actually uses.

5. **Root stays clean.** Only top-level config/docs files that don't have a better home: `CLAUDE.md`, `POLICY.yaml`, `ROADMAP.md`, `VISION.md`, `METHODOLOGY.md`, `PROMPT_OPTIMIZATION.md`, `README.md`, `llms.txt`, `.mcp.json`.

### What About `.deadf/`?

`.deadf/` is the **runtime state directory** (created per-project at deploy time). It doesn't move — it's not part of the repo template. Contains:
- `seed/`, `tracks/`, `docs/`, `logs/`, `notifications/`, `tooling-repairs/`
- `task_list_id`, `task_list_track`, `cron.lock`, `ralph.lock`

### Path Reference Updates Required

Every reference to `.pipe/p*/...` in CLAUDE.md, scripts, and templates must be updated. A `grep -rn '\.pipe/' .` will find them all. Key updates:

| Old Path | New Path |
|----------|----------|
| `.pipe/p1/P1_CYCLE_KICK.md` | `templates/kick/cycle-kick.md` |
| `.pipe/p1/p1-cron-kick.sh` | `scripts/cron-kick.sh` |
| `.pipe/p2-brainstorm.sh` | `scripts/brainstorm.sh` |
| `.pipe/p2/P2_MAIN.md` | `templates/research/brainstorm-main.md` |
| `.pipe/p3/P3_PICK_TRACK.md` | `templates/select-track/pick-track.md` |
| `.pipe/p4/P4_CREATE_SPEC.md` | `templates/select-track/create-spec.md` |
| `.pipe/p5/P5_CREATE_PLAN.md` | `templates/select-track/create-plan.md` |
| `.pipe/p6/P6_GENERATE_TASK.md` | `templates/execute/generate-task.md` |
| `.pipe/p7/P7_IMPLEMENT_TASK.md` | `templates/execute/implement-task.md` |
| `.pipe/p9/P9_VERIFY_CRITERION.md` | `templates/verify/verify-criterion.md` |
| `.pipe/p9.5/P9_5_REFLECT.md` | `templates/reflect/reflect.md` |
| `.pipe/p10/P10_FORMAT_REPAIR.md` | `templates/repair/format-repair.md` |
| `.pipe/p10/P10_AUTO_DIAGNOSE.md` | `templates/repair/auto-diagnose.md` |
| `.pipe/p11/P11_QA_REVIEW.md` | `templates/qa/qa-review.md` |
| `.pipe/p12-init.sh` | `scripts/init.sh` |
| `.pipe/p12/P12_DETECT.sh` | `scripts/init-detect.sh` |
| `.pipe/p12/P12_COLLECT.sh` | `scripts/init-collect.sh` |
| `.pipe/p12/P12_MAP.sh` | `scripts/init-map.sh` |
| `.pipe/p12/P12_CONFIRM.sh` | `scripts/init-confirm.sh` |
| `.pipe/p12/P12_INJECT.sh` | `scripts/init-inject.sh` |
| `.pipe/p12/p12-budget-check.sh` | `scripts/budget-check.sh` |
| `ralph.sh` (root) | `scripts/ralph.sh` |
| `verify.sh` (root) | `scripts/verify.sh` |
| `extract_plan.py` (root) | `scripts/extract_plan.py` |
| `build_verdict.py` (root) | `scripts/build_verdict.py` |

---

## C) Semantic Naming Convention

### Prompt Name Mapping (P-numbers → semantic names)

| Old ID | Old File | Semantic Name | New Path |
|--------|----------|---------------|----------|
| P1 | `P1_CYCLE_KICK.md` | `cycle-kick` | `templates/kick/cycle-kick.md` |
| P2 | `P2_MAIN.md` + sub-prompts | `brainstorm` | `templates/research/brainstorm-*.md` |
| P3 | `P3_PICK_TRACK.md` | `pick-track` | `templates/select-track/pick-track.md` |
| P4 | `P4_CREATE_SPEC.md` | `create-spec` | `templates/select-track/create-spec.md` |
| P5 | `P5_CREATE_PLAN.md` | `create-plan` | `templates/select-track/create-plan.md` |
| P6 | `P6_GENERATE_TASK.md` | `generate-task` | `templates/execute/generate-task.md` |
| P7 | `P7_IMPLEMENT_TASK.md` | `implement-task` | `templates/execute/implement-task.md` |
| P8 | `verify.sh` | `verify` (script) | `scripts/verify.sh` |
| P9 | `P9_VERIFY_CRITERION.md` | `verify-criterion` | `templates/verify/verify-criterion.md` |
| P9.5 | `P9_5_REFLECT.md` | `reflect` | `templates/reflect/reflect.md` |
| P10 | `P10_FORMAT_REPAIR.md` + `P10_AUTO_DIAGNOSE.md` | `format-repair` + `auto-diagnose` | `templates/repair/*.md` |
| P11 | `P11_QA_REVIEW.md` | `qa-review` | `templates/qa/qa-review.md` |
| P12 | `p12-init.sh` + sub-scripts | `init` | `scripts/init*.sh` + `templates/init/*.md` |

### Naming Conventions

**Templates:** `templates/{phase}/{action}.md` — lowercase kebab-case, no prefixes, no numbers.

**Rule files:** `.claude/rules/{scope}.md` — scope describes what it covers, prefixed by category when grouping helps:
- `action-*.md` for action specs
- `sentinel-grammars.md` for all sentinel formats
- `task-management.md` for Task integration
- `escalation-p10.md` — retains P10 reference since "3-tier escalation" is a known concept internally

**Scripts:** `scripts/{name}.sh` or `scripts/{name}.py` — descriptive names, no P-numbers.

**Design docs:** `docs/{type}/{topic}.md` — organized by type (design, reviews, analysis).

### Where P-Numbers Still Appear

P-numbers should be **removed from all file names** but may remain as internal references in:
- `PROMPT_OPTIMIZATION.md` (historical tracking — this is the index)
- Design docs in `docs/design/` (they were written with P-numbers; changing content is pointless churn)
- Comments within templates that reference the optimization history

### Migration Path (preserving git history)

Use `git mv` for each file to preserve rename tracking:

```bash
# Example (not exhaustive):
git mv .pipe/p3/P3_PICK_TRACK.md templates/select-track/pick-track.md
git mv .pipe/p6/P6_GENERATE_TASK.md templates/execute/generate-task.md
```

Git tracks renames with ~50% similarity threshold by default. Since we're only renaming (not changing content in the same commit), `git log --follow` will work perfectly.

**Strategy:** Rename in one commit, update all internal references in a second commit. This gives clean rename tracking.

---

## D) Contract/Tool Reconciliation

### Problem 1: `extract_plan.py` only parses PLAN blocks

**Current state:** The parser recognizes `<<<PLAN:V1:NONCE=...>>>` only. CLAUDE.md says to use it for TRACK (P3) and SPEC (P4) blocks too.

**Fix options (choose one):**

**Option A (recommended): Extend `extract_plan.py` into `extract_sentinel.py`**
- Add TRACK and SPEC opener/closer regexes alongside PLAN
- Accept a `--block-type` argument: `--block-type plan|track|spec`
- Each block type has its own field allowlist and validation rules
- PLAN gets multi-task support: `TASK_COUNT`, `TASK[N]` sections
- Rename to `extract_sentinel.py` to reflect broader scope

**Option B: Separate parsers**
- `extract_track.py`, `extract_spec.py`, `extract_plan.py`
- More files, but simpler per-parser. Less code sharing.

**Recommendation:** Option A. The sentinel grammar is consistent across all block types (opener/closer/nonce/fields). A single parser with a block-type flag is cleaner and easier to maintain. The field validation differs per type, but that's a config table, not a structural difference.

**Multi-task PLAN support:** The current parser assumes a single-task payload. The P5 template produces multi-task plans (`TASK_COUNT=N`, `TASK[1]:`, `TASK[2]:`, ...). The parser needs a mode that:
1. Reads `TASK_COUNT` from the first line
2. Splits payload into per-task sections at `TASK[N]:` markers
3. Validates each task section independently
4. Returns a JSON array of task objects

**Effort:** ~4-6 hours (extend parser + add tests)

### Problem 2: `verify.sh` can't read task packets as produced

**Three sub-issues:**

**2a. Wrong file path.** `verify.sh` reads `$PROJECT_DIR/TASK.md`. The pipeline writes task packets to `.deadf/tracks/{track.id}/tasks/TASK_{NNN}.md`. Fix: accept `VERIFY_TASK_FILE` env var (or `--task` argument) to override the default path. Fallback to `TASK.md` for backward compatibility.

**2b. ESTIMATED_DIFF parsing.** `verify.sh` uses `grep -oP 'ESTIMATED_DIFF[=:]\s*\K\d+'`. The task packet template uses `## ESTIMATED_DIFF` as a markdown header followed by the value on the next line, and also `ESTIMATED_DIFF=<int>` inline. The grep pattern catches the inline form but not the header form. Fix: add a second pattern that matches `## ESTIMATED_DIFF` followed by a bare number on the next line:
```bash
estimated_diff=$(grep -A1 '## ESTIMATED_DIFF' "$TASK_FILE" | tail -1 | grep -oP '^\d+' 2>/dev/null || true)
if [[ -z "$estimated_diff" ]]; then
    estimated_diff=$(grep -oP 'ESTIMATED_DIFF[=:]\s*\K\d+' "$TASK_FILE" 2>/dev/null || true)
fi
```

**2c. File path extraction.** `verify.sh` uses `grep -oP 'path=\K[^\s]+'`. The P6 task packet format uses `- path: <bare> | action: ...` (note the space after `path:` and `|` separator). Fix: add alternate pattern:
```bash
# Try sentinel format first, then markdown format
mapfile -t allowed_paths < <(
    grep -oP 'path=\K[^\s]+' "$TASK_FILE" 2>/dev/null
    grep -oP '^\s*-\s+path:\s*\K[^\s|]+' "$TASK_FILE" 2>/dev/null
)
```

**Effort:** ~2-3 hours (fix patterns + test)

### Problem 3: `ralph.sh` doesn't use canonical P1 kick template

**Current state:** `ralph.sh` constructs a minimal inline kick message:
```
DEADF_CYCLE $CYCLE_ID
project: $PROJECT_PATH
mode: $MODE
Execute ONE cycle. Follow iteration contract. Reply: CYCLE_OK | CYCLE_FAIL | DONE
```

The canonical P1 template (`P1_CYCLE_KICK.md`) has a richer structure with `task_list_id`, detailed instructions, etc. Meanwhile, `.pipe/p1/p1-cron-kick.sh` properly reads and templates the P1 kick.

**Fix:** Extract kick-message assembly into a shared function or small script (`scripts/assemble-kick.sh`) that:
1. Reads the canonical template
2. Substitutes variables (`$CYCLE_ID`, `$PROJECT_PATH`, `$MODE`, `$TASK_LIST_ID`)
3. Returns the assembled message on stdout

Both `ralph.sh` and `cron-kick.sh` call this function. This eliminates drift between the two kick paths.

**Effort:** ~2 hours

### Problem 4: POLICY.yaml bot-era remnants

GPT-5.2 flagged `authority: clawdbot` in POLICY.yaml. Quick sweep-and-fix:
```bash
grep -rn 'clawdbot\|discord\|session.send\|sessions_spawn' .
```
Update all matches. ~30 minutes.

### Priority Ordering

1. **verify.sh task file path + parsing** (P2a/2b/2c) — blocks end-to-end runs
2. **extract_plan.py → extract_sentinel.py** (P1) — blocks select-track phase
3. **ralph.sh kick unification** (P3) — correctness, not blocking
4. **POLICY.yaml cleanup** (P4) — cosmetic but prevents confusion

---

## E) Implementation Plan

### Phase 1: CLAUDE.md Split (LOW RISK)

**What:** Extract action specs, sentinel grammars, task management, escalation, etc. into `.claude/rules/` files. Rewrite CLAUDE.md as a ~280-line skeleton.

**Steps:**
1. Create `.claude/rules/` directory
2. Extract each section into its rule file (copy-paste, no content changes)
3. Rewrite CLAUDE.md skeleton with action index table
4. Verify: `wc -l CLAUDE.md` ≤ 300; `cat .claude/rules/*.md | wc -l` ≈ 940

**Risk:** LOW. Content is unchanged; just reorganized. Claude Code auto-loads `.claude/rules/` so behavior is identical.

**Git strategy:** Single commit: `refactor(contract): split CLAUDE.md into modular rules`

**Effort:** ~3 hours

### Phase 2: File Structure Reorganization (MEDIUM RISK)

**What:** Move templates, scripts, and docs into clean directory structure. Eliminate `.pipe/`.

**Steps:**
1. Create `templates/`, `scripts/`, `docs/` directory trees
2. `git mv` all files per the mapping table in section B
3. Commit renames (content unchanged)
4. Update all internal path references (grep + sed/edit)
5. Update README.md, PROMPT_OPTIMIZATION.md with new paths
6. Commit reference updates

**Risk:** MEDIUM. Any hardcoded path that's missed will break. Mitigation: exhaustive grep before committing.

**Required grep targets:**
```bash
git grep -n '\.pipe/' -- '*.md' '*.sh' '*.py' '*.yaml' '*.json'
git grep -n 'P[0-9]*_' -- '*.md' '*.sh' '*.py'  # old template names
git grep -n 'ralph\.sh\|verify\.sh\|extract_plan\|build_verdict' -- '*.md' '*.sh'
```

**Git strategy:** Two commits:
1. `refactor(structure): reorganize files into templates/scripts/docs`
2. `refactor(structure): update all internal path references`

**Effort:** ~4 hours

**Can parallelize with Phase 1?** NO — Phase 2 moves files that Phase 1 references. Do Phase 1 first.

### Phase 3: Contract/Tool Reconciliation (HIGH RISK)

**What:** Fix `verify.sh`, extend `extract_plan.py`, unify kick assembly.

**Steps (sequential within phase, but each is an independent commit):**

3a. **verify.sh fixes** (~2-3h)
- Add `VERIFY_TASK_FILE` env var support
- Fix ESTIMATED_DIFF parsing (dual-pattern)
- Fix file path extraction (dual-pattern)
- Add tests (fixture task packets in both formats)
- Commit: `fix(verify): support pipeline task packet format`

3b. **extract_plan.py → extract_sentinel.py** (~4-6h)
- Rename file
- Add `--block-type` argument
- Add TRACK block grammar + validation
- Add SPEC block grammar + validation
- Add multi-task PLAN support
- Add tests for all block types
- Commit: `feat(parser): extend to TRACK/SPEC/multi-task PLAN blocks`

3c. **Kick assembly unification** (~2h)
- Create `scripts/assemble-kick.sh`
- Refactor `ralph.sh` to use it
- Refactor `cron-kick.sh` to use it
- Commit: `refactor(kick): unify kick message assembly`

3d. **POLICY.yaml cleanup** (~30min)
- Remove bot-era references
- Commit: `fix(policy): remove clawdbot/discord references`

**Risk:** HIGH for 3a and 3b (changing behavior of existing tools). Mitigation: golden-file tests before changing anything — capture current behavior, then modify with regression safety.

**Git strategy:** One commit per sub-step (4 commits total).

**Can parallelize with Phase 2?** YES — tool fixes don't depend on file moves if done in the old paths. But for sanity, do Phase 2 first so all path references are stable.

**Effort:** ~10 hours total

### Phase 4: Naming Migration (LOW RISK)

**What:** Remove P-numbers from remaining references in contract and rule files.

**Steps:**
1. In `.claude/rules/` files, replace `P6_GENERATE_TASK.md` → `templates/execute/generate-task.md` etc.
2. In CLAUDE.md skeleton, ensure all references use semantic names
3. Update `PROMPT_OPTIMIZATION.md` with a mapping table (old → new)

**Risk:** LOW. Cosmetic changes to reference strings.

**Git strategy:** Single commit: `refactor(naming): replace P-numbers with semantic names`

**Effort:** ~1 hour

### Phase Summary

| Phase | Depends On | Risk | Effort | Commits |
|-------|-----------|------|--------|---------|
| 1. CLAUDE.md split | — | LOW | 3h | 1 |
| 2. File restructure | Phase 1 | MEDIUM | 4h | 2 |
| 3. Tool reconciliation | Phase 2 | HIGH | 10h | 4 |
| 4. Naming cleanup | Phase 2 | LOW | 1h | 1 |

**Total estimated effort:** ~18 hours
**Total commits:** 8

**Phases 3 and 4 can run in parallel** after Phase 2 completes.

### Git Strategy: Incremental (NOT one big commit)

Reasons:
1. Each phase is independently revertible
2. Renames in their own commit get proper `git log --follow` tracking
3. Tool changes (Phase 3) are the highest risk — isolating them enables targeted rollback
4. Reviewable in smaller chunks

### Validation Checklist (post-restructure)

- [ ] `wc -l CLAUDE.md` ≤ 300
- [ ] `ls .claude/rules/*.md | wc -l` = 11 rule files
- [ ] `grep -rn '\.pipe/' . --include='*.md' --include='*.sh' --include='*.py'` returns 0 results
- [ ] `ls .pipe/` fails (directory gone)
- [ ] `python3 scripts/extract_sentinel.py --block-type plan --nonce 4F2C9A < fixture.txt` works
- [ ] `python3 scripts/extract_sentinel.py --block-type track --nonce 4F2C9A < fixture.txt` works
- [ ] `VERIFY_TASK_FILE=.deadf/tracks/test/tasks/TASK_001.md scripts/verify.sh` reads correct file
- [ ] `ralph.sh` and `cron-kick.sh` both produce identical kick messages (diff test)
- [ ] `grep -rn 'clawdbot\|discord' . --include='*.yaml'` returns 0 results

---

## Appendix: File Count Summary

| Category | Current | Proposed |
|----------|---------|----------|
| Contract (CLAUDE.md) | 1 file, 1240 lines | 1 file ≤280 lines + 11 rule files |
| Templates | 26 files scattered in `.pipe/p*/` | 26 files in `templates/` tree |
| Scripts | 12 files in root + `.pipe/` | 12 files in `scripts/` |
| Design/review docs | 14 files in `.pipe/` | 14 files in `docs/` tree |
| Config/top-level | 8 files | 8 files (unchanged) |

Total file count is unchanged. Only locations and names change.
