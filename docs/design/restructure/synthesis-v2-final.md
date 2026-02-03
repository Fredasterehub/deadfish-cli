# deadf(ish) Restructure — Final Synthesis v2

> **Author:** Opus 4.5 (orchestrator synthesis)
> **Date:** 2026-02-02
> **Sources:** plan-v2-opus.md, plan-v2-gpt52.md, Fred's review feedback
> **Status:** REVISED v4 (post GPT-5.2 R4 — all R1-R4 findings addressed)

---

## Design Principles (binding)

1. **Everything pipeline → `.deadf/`** in target projects. No exceptions.
2. **CLAUDE.md is a binder, not a bible** — ≤300 lines, tells orchestrator WHERE to read, not WHAT the content is.
3. **No `@import` dependency** — explicit `read` calls to `.deadf/contracts/` and `.deadf/templates/`. `.claude/rules/` auto-load is allowed as convenience but CLAUDE.md also lists them as explicit reads at cycle start (belt + suspenders). (GPT-5.2 win, refined per R1)
4. **Spec lives with the parser** — contracts/ directory puts grammars next to the tools that consume them. (GPT-5.2 win)
5. **Task packets as YAML-frontmatter** — structured data parsed by `yq`, not grep regex. (GPT-5.2 win)
6. **Fix tools BEFORE restructuring files** — avoid double churn. (Both plans agree)
7. **Semantic naming only** — P-numbers preserved solely in `PROMPT_OPTIMIZATION.md` history.
8. **Our unique strengths are non-negotiable** — deterministic verification, sentinel grammars + nonces, 3-tier repair, track-level QA, multi-model architecture, Task Management integration.

---

## A) Target Project Layout (`.deadf/`)

```text
<project>/
  .deadf/
    VERSION                       # pinned pipeline version string
    manifest.yaml                 # deployed file list + hashes (update/revert)

    bin/                          # executable tooling
      kick.sh                     # canonical kick entrypoint (shared assembly)
      ralph.sh                    # loop controller (calls kick.sh)
      cron-kick.sh                # cron launcher (calls kick.sh)
      verify.sh                   # deterministic facts-only verifier
      parse-blocks.py             # unified sentinel parser (track/spec/plan/verdict/reflect/qa-review)
      build-verdict.py            # verdict aggregator
      lint-templates.py           # template ↔ contract drift checker
      brainstorm.sh               # seed docs orchestrator
      init.sh                     # brownfield init orchestrator
      init-detect.sh              # P12 detect phase
      init-collect.sh             # P12 collect phase
      init-map.sh                 # P12 map phase
      init-confirm.sh             # P12 confirm phase
      init-inject.sh              # P12 inject phase
      budget-check.sh             # P12 budget check

    contracts/                    # single source of truth for formats
      sentinel/                   # sentinel block grammars (versioned)
        track.v1.md
        spec.v1.md
        plan.v1.md
        verdict.v1.md
        reflect.v1.md
        qa-review.v1.md
      schemas/                    # machine-readable schemas
        state.v2.yaml             # STATE.yaml schema + constraints
        task-packet.v1.yaml       # task packet YAML-frontmatter schema
        verify-result.v1.json     # verify.sh output shape
      policy/
        policy.schema.json        # POLICY.yaml validation schema

    templates/                    # worker model prompt templates (semantic names)
      bootstrap/
        seed-project-docs.md      # was P2_MAIN
        brainstorm-a.md           # was P2_A (through G, A2)
        brainstorm-b.md
        brainstorm-c.md
        brainstorm-d.md
        brainstorm-e.md
        brainstorm-f.md
        brainstorm-g.md
        brainstorm-a2.md
        project.tmpl.md           # was P2_PROJECT_TEMPLATE
        requirements.tmpl.md      # was P2_REQUIREMENTS_TEMPLATE
        roadmap.tmpl.md           # was P2_ROADMAP_TEMPLATE
      init/
        mapper-agent.md           # was MAPPER_AGENT.md
        synthesizer.md            # was SYNTHESIZER.md
        brownfield-brainstorm.md  # was BROWNFIELD_P2.md
        living-docs.tmpl          # was LIVING_DOCS.tmpl
      track/
        select-track.md           # was P3_PICK_TRACK
        write-spec.md             # was P4_CREATE_SPEC
        write-plan.md             # was P5_CREATE_PLAN
      task/
        generate-packet.md        # was P6_GENERATE_TASK
        implement.md              # was P7_IMPLEMENT_TASK
      verify/
        verify-criterion.md       # was P9_VERIFY_CRITERION
        reflect.md                # was P9_5_REFLECT
        qa-review.md              # was P11_QA_REVIEW
      repair/
        format-repair.md          # was P10_FORMAT_REPAIR
        auto-diagnose.md          # was P10_AUTO_DIAGNOSE
      kick/
        cycle-kick.md             # was P1_CYCLE_KICK

    context/                      # project-level living context
      VISION.md
      PROJECT.md
      REQUIREMENTS.md
      ROADMAP.md
      OPS.md                      # build/test/run commands (≤60 lines)

    docs/                         # machine-maintained living docs
      PRODUCT.md
      TECH_STACK.md
      WORKFLOW.md
      PATTERNS.md
      PITFALLS.md
      RISKS.md
      GLOSSARY.md
      .scratch.yaml               # reflect buffer

    tracks/                       # Conductor-style track lifecycle
      index.md                    # all tracks overview (append-only)
      <track-id>/
        track.yaml                # metadata: status, dates, commits, stats
        spec.md
        plan.md
        tasks/
          001.task.md             # YAML-frontmatter + markdown body
          002.task.md
          ...
        qa-review.md              # track-level QA result

    state/
      STATE.yaml                  # authoritative pipeline state
      STATE.yaml.flock            # lock file
      POLICY.yaml                 # mode behavior + thresholds

    runtime/                      # gitignored mechanical state
      locks/
        cron.lock
        ralph.lock
      logs/
        cycle-<id>.log
        qa-warnings.md
        mismatch-<id>.md
      cache/
      task-list-id                # Claude Code Tasks list ID
      task-list-track             # track rotation detector
      tooling-repairs/            # queued parser/tool fixes from P10 MISMATCH
        repair-<ts>.md

```

### Design Notes

- **`contracts/` next to `bin/`**: spec lives with the parser. Grammars and schemas are consumed by `parse-blocks.py` and `verify.sh` — colocated, not scattered into orchestrator folders.
- **`templates/` for worker prompts**: these are instructions for GPT-5.2 / Codex, NOT for the orchestrator. Organized by pipeline phase.
- **`context/` vs `docs/`**: `context/` = "what we're building" (strategic, human-authored seeds). `docs/` = "what we've learned" (machine-maintained living docs from reflect cycles).
- **`state/` contains STATE.yaml + POLICY.yaml**: single location for all pipeline state. Root-level symlinks optional for convenience.
- **`runtime/` is gitignored**: locks, logs, cache, task list IDs — ephemeral operational data.
- **`tracks/index.md`**: Conductor-inspired single-file overview. Updated at track transitions.
- **`track.yaml`**: Conductor-inspired per-track metadata (machine-readable stats for analytics).
- **`manifest.yaml`**: GPT-5.2's contribution — enables deterministic update/revert of deployed pipeline files.

---

## B) deadfish-cli Repo Layout

```text
deadfish-cli/
  CLAUDE.md                       # ≤300 line binder contract
  .claude/
    rules/                        # auto-loaded invariants (~160 lines total)
      core.md                     #   role boundaries, one-cycle-one-action (~40 lines)
      state-locking.md            #   flock pattern, atomic writes (~40 lines)
      safety.md                   #   blocked paths, tool restrictions (~35 lines)
      output-contract.md          #   last-line tokens, sentinel output rules (~25 lines)

  .deadf/                         # canonical deployed tree (copied to target projects)
    (entire structure from section A)

  tests/
    fixtures/
      sentinels/                  # golden files for parser accept/reject
        track-valid.txt
        track-invalid.txt
        spec-valid.txt
        plan-valid.txt
        plan-multi-task.txt
        verdict-valid.txt
        reflect-valid.txt
        qa-review-valid.txt
      task-packets/               # YAML-frontmatter examples
        valid-packet.md
        invalid-packet.md
    test-parsers.sh               # parser golden test runner
    test-templates.sh             # template lint test runner

  docs/                           # design artifacts (not runtime)
    design/
    reviews/
    analysis/

  examples/
    project-structure.md

  VISION.md
  ROADMAP.md
  METHODOLOGY.md
  PROMPT_OPTIMIZATION.md          # historical P-number reference
  README.md
  llms.txt
  .mcp.json
  .gitignore
```

### Design Notes

- **`.claude/rules/` for invariants ONLY** (~160 lines): role boundaries, locking patterns, safety constraints, output contract. These are orchestrator-specific and always relevant.
- **NO `.claude/imports/`**: we don't depend on `@import`. CLAUDE.md tells the orchestrator to `read` files from `.deadf/contracts/` and `.deadf/templates/` explicitly. Platform-proof.
- **`.deadf/` IS the canonical source**: what's committed in the repo IS what gets deployed. No generator. `deadf update` = copy `.deadf/` + update `manifest.yaml`.
- **`.pipe/` → gone**: current `.pipe/` working artifacts move to `docs/` (design history) or are deleted. Runtime pipeline artifacts live in `.deadf/`.

---

## C) CLAUDE.md Binder Contract (~250 lines)

### Structure

```markdown
# CLAUDE.md — deadf(ish) Orchestrator Contract v3.0

## Identity & Role Boundaries (~25 lines)
- You are Claude Code (Opus 4.5), the Orchestrator.
- You coordinate workers. You do NOT write code / plan tasks / judge quality.
- You DO: read state → decide → dispatch → parse → record → reply.
- Write authority table (who writes what).

## Setup: Multi-Model via Codex MCP (~15 lines)
- .mcp.json reference
- codex / codex-reply tools
- Session continuity rules

## Cycle Protocol (~50 lines)
6-step deterministic skeleton:
1. LOAD: read STATE.yaml, POLICY.yaml, OPS.md, active track/task.
         Also read these invariant rule files (belt+suspenders with auto-load):
         - .claude/rules/core.md
         - .claude/rules/state-locking.md
         - .claude/rules/safety.md
         - .claude/rules/output-contract.md
2. VALIDATE: derive nonce, check budget, verify no stale locks
3. DECIDE: evaluate precedence table → select ONE action
4. EXECUTE: read the action's template path from the DECIDE table's "Template" column (canonical, exact path — do NOT derive from action ID)
          + read relevant grammar from the DECIDE table's "Output Grammar" column
          → dispatch to worker model → parse sentinel output
   Exception: `verify.facts` has no template or sentinel. Run `.deadf/bin/verify.sh` directly.
   Output is JSON per `.deadf/contracts/schemas/verify-result.v1.json`. DECIDE row: Template=N/A, Output Grammar=verify-result.v1.json.
5. RECORD: atomic STATE.yaml write under flock
6. REPLY: emit CYCLE_OK | CYCLE_FAIL | DONE

"Before executing, read the template and grammar. Do NOT improvise format."

## DECIDE Table (~40 lines)
Full precedence-ordered table with semantic action names.
15 rows. Columns: Priority | Condition | Action | Template | Output Grammar

## State Schema Reference (~15 lines)
- Pointer to `.deadf/contracts/schemas/state.v2.yaml` for full schema
- Key field names and types (quick reference only)

## Model Dispatch Reference (~20 lines)
Purpose → command → model table

## Nonce & Locking (~15 lines)
- Nonce derivation formula
- Flock discipline
- Lock timeout rules

## Task Management (~15 lines)
- Task naming convention
- Dedup rules
- Graceful degradation (non-fatal)

## Quick Reference (~15 lines)
ASCII cycle flow + key paths
```

**Total: ~210-250 lines.** Well within ≤300 budget.

### Key Difference from v1 Synthesis

No `@import` anywhere in CLAUDE.md. Instead:
```
Before executing action "write-spec":
  1. Read .deadf/templates/track/write-spec.md
  2. Read .deadf/contracts/sentinel/spec.v1.md
  3. Dispatch to planner with template content
```

This is explicit, debuggable, and doesn't depend on Claude Code platform features.

---

## D) Semantic Naming

### Action IDs (used in DECIDE table, STATE.yaml, templates)

| Legacy | Semantic ID | Template Path |
|--------|-------------|---------------|
| P1 | `cycle.kick` | `kick/cycle-kick.md` |
| P2 | `bootstrap.seed_docs` | `bootstrap/seed-project-docs.md` |
| P12 | `bootstrap.map_codebase` | `init/mapper-agent.md` |
| P3 | `track.select` | `track/select-track.md` |
| P4 | `track.write_spec` | `track/write-spec.md` |
| P5 | `track.write_plan` | `track/write-plan.md` |
| P6 | `task.generate_packet` | `task/generate-packet.md` |
| P7 | `task.implement` | `task/implement.md` |
| P8 | `verify.facts` | (bin/verify.sh — no template) |
| P9 | `verify.criteria` | `verify/verify-criterion.md` |
| P9.5 | `docs.reflect` | `verify/reflect.md` |
| P10 | `repair.format` | `repair/format-repair.md` |
| P10 T2 | `repair.auto_diagnose` | `repair/auto-diagnose.md` |
| P11 | `qa.review` | `verify/qa-review.md` |

### STATE.yaml Field Updates

Two-level state model: `stage` (coarse grouping) + `current_action` (exact position):

```yaml
# Old
phase: brainstorm
track:
  sub_step: generate_task

# New — unambiguous two-level model
stage: bootstrap | track | task | qa | complete | needs_human
current_action: bootstrap.seed_docs | bootstrap.map_codebase | track.select | track.write_spec | track.write_plan | task.generate_packet | task.implement | verify.criteria | docs.reflect | repair.format | repair.auto_diagnose | qa.review
```

- **`stage`** = coarse grouping for status display and high-level routing
- **`current_action`** = exact semantic action ID, matches DECIDE table rows 1:1
- DECIDE table conditions reference `current_action` as the canonical field
- Resume after crash: read `current_action`, re-enter at that exact step

**Track/task locator fields (guaranteed in state.v2.yaml, used by verify.sh):**
```yaml
track:
  id: <string>           # active track ID (e.g., "auth-01")
  task_current: <int>    # 1-indexed current task number
  task_total: <int>      # total tasks in current plan
  packet_path: <string>  # optional explicit path override for task file
```
`verify.sh` reads `track.id` + `track.task_current` to derive the task file path. If `track.packet_path` is set, it takes precedence. These fields are NOT replaced by `stage`/`current_action` — they coexist.

---

## E) Task Packet Format (GPT-5.2's YAML-frontmatter approach)

### Current (brittle)
```markdown
## TASK 1
path=src/auth.ts
action=CREATE
ESTIMATED_DIFF=45
...
```
Parsed by `verify.sh` with `grep -oP` — breaks on format variations.

### New: YAML-frontmatter + markdown body
```markdown
---
task_id: 1
track_id: auth-01
estimated_diff: 45
files:
  - path: src/auth.ts
    action: create
  - path: src/auth.test.ts
    action: create
acceptance_criteria:
  - id: AC1
    text: "Auth module exports login() and logout()"
    type: deterministic
  - id: AC2
    text: "All tests pass"
    type: deterministic
---

# Task 1: Implement Authentication Module

## Description
Create the authentication module with login/logout functionality...

## Implementation Notes
...
```

### Migration
- `generate-packet.md` template updated to emit YAML-frontmatter format
- `verify.sh` reads frontmatter via `yq` (already available on system)
- Schema defined in `.deadf/contracts/schemas/task-packet.v1.yaml`
- Old format detection: if no `---` frontmatter found, fall back to grep parsing (backward compat)

---

## F) Contract/Tool Reconciliation

### F1) `parse-blocks.py` (replaces `extract_plan.py`)

Unified sentinel parser with subcommands:

```bash
parse-blocks.py track     --nonce ABC123 < output.txt
parse-blocks.py spec      --nonce ABC123 < output.txt
parse-blocks.py plan      --nonce ABC123 < output.txt
parse-blocks.py verdict   --nonce ABC123 < output.txt
parse-blocks.py reflect   --nonce ABC123 < output.txt
parse-blocks.py qa-review --nonce ABC123 < output.txt
```

Subcommand names map 1:1 to grammar filenames: `parse-blocks.py <name>` reads `.deadf/contracts/sentinel/<name>.v1.md`.

Each subcommand:
1. Reads grammar from `.deadf/contracts/sentinel/<name>.v1.md` (self-documenting)
2. Validates nonce match
3. Validates required fields per grammar
4. Outputs structured JSON to stdout
5. Exit 0 = valid, Exit 1 = parse error (with diagnostic), Exit 2 = nonce mismatch

**Naming convention — two layers:**
- **Action IDs** (STATE.yaml, DECIDE table): dotted → `qa.review`, `docs.reflect`, `repair.format`
- **File identifiers** (grammars, parser subcommands, templates): hyphenated → `qa-review`, `reflect`, `format-repair`
- **Mapping rule:** DECIDE table includes an explicit `Output Grammar` column that maps action ID → grammar file. E.g., action `qa.review` → output grammar `qa-review.v1.md` → parser `parse-blocks.py qa-review`.
- **Never** use bare `qa` as a shorthand anywhere.

Backward compat: `extract_plan.py` becomes a shim → `exec parse-blocks.py plan "$@"`

### F2) `verify.sh` fixes

```bash
# Task file discovery (new)
if [ -n "${VERIFY_TASK_FILE:-}" ]; then
    TASK_FILE="$VERIFY_TASK_FILE"
elif [ -f "${DEADF_ROOT}/state/STATE.yaml" ]; then
    TRACK_ID=$(yq '.track.id' "${DEADF_ROOT}/state/STATE.yaml")
    TASK_NUM=$(printf "%03d" $(yq '.track.task_current' "${DEADF_ROOT}/state/STATE.yaml"))
    TASK_FILE="${DEADF_ROOT}/tracks/${TRACK_ID}/tasks/${TASK_NUM}.task.md"
else
    TASK_FILE="TASK.md"  # backward compat fallback
fi

# YAML-frontmatter parsing (new)
# Requires: mikefarah/yq v4+ (https://github.com/mikefarah/yq)
if head -1 "$TASK_FILE" | grep -q '^---$'; then
    # Strip delimiters, extract pure YAML between first two ---
    FRONTMATTER=$(sed -n '2,/^---$/{ /^---$/d; p }' "$TASK_FILE")
    ESTIMATED_DIFF=$(echo "$FRONTMATTER" | yq '.estimated_diff')
    PLANNED_PATHS=$(echo "$FRONTMATTER" | yq '.files[].path')
else
    # Legacy format: grep fallback
    ESTIMATED_DIFF=$(grep -oP '(?:ESTIMATED_DIFF[=:]\s*)(\d+)' "$TASK_FILE" | head -1 | grep -oP '\d+')
    PLANNED_PATHS=$(grep -oP '(?:path[=:]\s*)([^\s|]+)' "$TASK_FILE" | grep -oP '[^\s|]+$')
fi
```

### F3) Kick unification

`kick.sh` — shared kick assembly:
```bash
#!/bin/bash
# Canonical kick entrypoint. Used by both ralph.sh and cron-kick.sh.
# Reads cycle-kick.md template, substitutes variables, dispatches to orchestrator.
set -euo pipefail
DEADF_ROOT="${DEADF_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
TEMPLATE="${DEADF_ROOT}/templates/kick/cycle-kick.md"
# ... substitute CYCLE_ID, PROJECT_PATH, MODE, TASK_LIST_ID, STATE_HINT
# ... dispatch to Claude Code
```

`ralph.sh` becomes: loop wrapper + iteration tracking + timeout + backoff. Calls `kick.sh`.
`cron-kick.sh` becomes: lock acquisition + rotation check + single kick. Calls `kick.sh`.

### F4) `lint-templates.py` (new — GPT-5.2's contribution)

Deterministic linter that validates:
- Sentinel open/close delimiters in templates match grammar specs in `contracts/sentinel/`
- Required fields appear in required order
- No format drift between what templates tell models to produce and what parsers expect

Run as: `lint-templates.py --contracts .deadf/contracts --templates .deadf/templates`
Exit 0 = clean, Exit 1 = drift detected (with diagnostics).

### F5) `manifest.yaml` (new — GPT-5.2's contribution)

Tracks deployed pipeline files + hashes:
```yaml
version: "3.0.0"
deployed_at: "2026-02-02T15:00:00Z"
files:
  bin/verify.sh:
    sha256: abc123...
    size: 4521
  contracts/sentinel/plan.v1.md:
    sha256: def456...
    size: 1203
  # ...
```

**MVP scope:** `manifest.yaml` is a passive artifact only — created during init, updated on deploy. No CLI commands (`deadf update`, `deadf revert`) in this restructure. Those are future enhancements (see Section H). The manifest enables future tooling but is useful today for manual diff checks.

---

## G) Implementation Plan

### Phase 0: Pre-flight (~0.5h)
- `git tag pre-restructure-v2`
- Run current `verify.sh` on test fixture → save baseline results
- Document current state in `tests/results/baseline.md`

### Phase 1: Tool Fixes (~2 days)
> Fix tools BEFORE moving files. Both plans agree this is critical.

**1a) `parse-blocks.py`** (~1.5 days)
- Create `.deadf/contracts/sentinel/` with all 6 grammar specs (extracted from current CLAUDE.md)
- Create `.deadf/contracts/schemas/task-packet.v1.yaml`
- Implement `parse-blocks.py` with subcommands (track/spec/plan/verdict/reflect/qa-review)
- Create golden fixtures in `tests/fixtures/sentinels/`
- Create backward-compat `extract_plan.py` shim
- **Commit:** `feat(parser): unified sentinel parser with multi-block support`

**1b) `verify.sh` fixes** (~0.5 days)
- Add `DEADF_ROOT` + `VERIFY_TASK_FILE` env var support
- Add YAML-frontmatter parsing via `yq` with grep fallback
- Add STATE.yaml-based task file auto-discovery
- Test with golden fixtures
- **Commit:** `fix(verify): task file discovery and YAML-frontmatter parsing`

### Phase 2: Launcher Unification (~0.5 days)
- Pre-req: create `.deadf/templates/kick/` and move `cycle-kick.md` there (early move to unblock kick.sh)
- Create `.deadf/bin/kick.sh` (shared assembly, reads from `.deadf/templates/kick/cycle-kick.md`)
- Update `ralph.sh` to call `kick.sh`
- Update `cron-kick.sh` to call `kick.sh`
- Test: both launchers produce identical kick messages
- **Commit:** `refactor(launcher): shared kick assembly via kick.sh`

### Phase 3: File Layout Restructure (~1 day)
- Create full `.deadf/` directory structure
- `git mv` templates from `.pipe/pN/` → `.deadf/templates/<phase>/` with semantic names
- `git mv` scripts to `.deadf/bin/`
- Move design artifacts from `.pipe/` → `docs/`
- Update all internal path references in scripts and templates
- Create `manifest.yaml` skeleton
- **Commit:** `refactor(structure): reorganize into .deadf/ canonical layout`

### Phase 4: CLAUDE.md Split (~1 day)
- Create `.claude/rules/` (4 files, ~160 lines total)
- Rewrite CLAUDE.md as binder contract (≤250 lines)
- DECIDE table uses semantic action names
- All action specs reference `.deadf/templates/` and `.deadf/contracts/` paths
- No `@import` — explicit `read` instructions
- **Commit:** `refactor(contract): CLAUDE.md binder + .claude/rules/ (~250 lines)`

### Phase 5: New Artifacts (~0.5 days)
- Create `tracks/index.md` template
- Create `tracks/<id>/track.yaml` template
- Add `lint-templates.py`
- Clean POLICY.yaml of bot-era references
- Update README.md
- **Commit:** `feat(tracks): index.md, track.yaml, template linter`

### Phase 6: Validation (~0.5 days)
Run full validation checklist:
- [ ] `wc -l CLAUDE.md` ≤ 300
- [ ] `wc -l .claude/rules/*.md` ≤ 200 total
- [ ] All templates present in `.deadf/templates/` (≥20 files)
- [ ] All scripts present in `.deadf/bin/` (≥12 files)
- [ ] All grammar specs present in `.deadf/contracts/sentinel/` (6 files)
- [ ] `grep -rn '\.pipe/' --include='*.md' --include='*.sh' --include='*.py' --exclude-dir=docs . ` = 0
- [ ] `grep -rn 'P[0-9]\+_' .deadf/ .claude/ CLAUDE.md` = 0
- [ ] `grep -rn 'clawdbot' .deadf/state/POLICY.yaml` = 0
- [ ] `parse-blocks.py plan --nonce TEST < tests/fixtures/sentinels/plan-valid.txt` passes
- [ ] `parse-blocks.py track --nonce TEST < tests/fixtures/sentinels/track-valid.txt` passes
- [ ] `parse-blocks.py reflect --nonce TEST < tests/fixtures/sentinels/reflect-valid.txt` passes
- [ ] `parse-blocks.py qa-review --nonce TEST < tests/fixtures/sentinels/qa-review-valid.txt` passes
- [ ] `verify.sh` reads YAML-frontmatter task packet correctly
- [ ] `kick.sh` produces valid kick message
- [ ] `lint-templates.py` passes on all templates
- [ ] Simulated dry-run cycle completes
- **Commit:** `test(validation): restructure validation suite`

### Phase 7: Cleanup (~0.5 days)
- Remove `.pipe/` (or archive to `docs/archive/` if Fred wants history)
- Remove backward-compat shims after confirming no references
- Final `git tag post-restructure-v2`
- **Commit:** `chore(cleanup): remove legacy .pipe/ and shims`

### Summary

| Phase | Scope | Effort | Commits |
|-------|-------|--------|---------|
| 0 | Pre-flight | 0.5h | tag only |
| 1 | Tool fixes | 2d | 2 |
| 2 | Launcher unification | 0.5d | 1 |
| 3 | File layout | 1d | 1 |
| 4 | CLAUDE.md split | 1d | 1 |
| 5 | New artifacts | 0.5d | 1 |
| 6 | Validation | 0.5d | 1 |
| 7 | Cleanup | 0.5d | 1 |
| **Total** | | **~6 days** | **8 commits** |

---

## H) What We Explicitly DON'T Do

These were considered and rejected to prevent workflow creep:

1. ❌ **CONTEXT.md per track** — workflow addition, not structural
2. ❌ **RESEARCH.md per track** — workflow addition, not structural
3. ❌ **New doc types from Conductor** (product.md, tech-stack.md at root) — we already have equivalents in `.deadf/docs/`
4. ❌ **Parallel execution waves** (GSD) — our tasks are sequential by design
5. ❌ **`deadf` CLI wrapper** (GPT-5.2) — nice ergonomic, but not MVP. Defer.
6. ❌ **`deadf revert` command** (Conductor) — enhancement, not structural. Defer.
7. ❌ **Quick-mode** (GSD) — Fred mentioned, defer for now
8. ❌ **`planning/runs/` per-cycle workbench** — nice for debug, but not MVP. Defer.

These are noted in ROADMAP.md as future enhancements.

---

## I) Decision Attribution

| Decision | Winner | Why |
|----------|--------|-----|
| No `@import`, explicit `read` | GPT-5.2 | Platform-proof, debuggable, no magic |
| `contracts/` directory | GPT-5.2 | Spec next to parser, cleaner separation |
| YAML-frontmatter task packets | GPT-5.2 | Eliminates brittle grep, structured by default |
| `manifest.yaml` | GPT-5.2 | Enables deterministic update/revert |
| `lint-templates.py` | GPT-5.2 | Prevents the exact drift that caused our 3 mismatches |
| `.claude/rules/` for invariants | Opus | Small auto-load set (~160 lines) for always-needed rules |
| Concrete code snippets | Opus | verify.sh, parse-blocks.py, kick.sh — ready to implement |
| `tracks/index.md` + `track.yaml` | Both | Conductor-inspired observability |
| Phase ordering (tools first) | Both | Avoid double churn |
| Token budget analysis | Opus | ~6K tokens/cycle (down from ~15K) |
| `templates/` over `agents/` | GPT-5.2 | These are prompts for worker models, not "agents" — clearer naming |

---

## J) Contract Versioning Policy

Simple rule: **templates and DECIDE table reference exact versioned grammar paths.**

- Grammar files are named `<type>.v<N>.md` (e.g., `plan.v1.md`)
- Templates include a comment: `# grammar: plan.v1`
- DECIDE table columns include grammar version
- Upgrading: add `plan.v2.md`, update DECIDE table + template pointers in ONE atomic commit
- Old versions kept for backward compat until all references removed
- `lint-templates.py` validates template grammar comments match existing contract files

---

## K) Clarification Notes (from GPT-5.2 R1 review)

1. **Dual `docs/` directories:** Repo-level `docs/` = design artifacts, reviews, analysis (developer reference). Deployed `.deadf/docs/` = machine-maintained living docs (runtime). Only `.deadf/docs/` is copied to target projects. README.md clarifies this.

2. **`planning/runs/` deferred:** Removed from target layout. Not in MVP. Future enhancement for per-cycle debug context bundles.

3. **`manifest.yaml` is passive:** Created during init, useful for manual diff. No CLI commands (update/revert) in this restructure.

4. **`.claude/rules/` dependency model:** Rules auto-load as platform convenience BUT CLAUDE.md also lists them as explicit reads in LOAD step. If auto-load breaks, the explicit read instruction covers it.

---

*Revised post GPT-5.2 R1-R4 reviews. All findings addressed (R1: 3C/3H/2M/1L, R2: 2H/1M, R3: 1H/2M/1L, R4: 1M/1L).*
