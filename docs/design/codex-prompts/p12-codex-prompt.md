# P12 Implementation Prompt for GPT-5.2-Codex (builder)

This file is meant to be pasted into `codex exec` (builder).
It contains the canonical P12 spec verbatim and a sequence of 8 micro-tasks.

---

## 0a. Orientation

You are **GPT-5.2-Codex** implementing **P12: Codebase Mapper / Brownfield Detection** for this repo.
Work in: `/tank/dump/DEV/deadfish-cli`.

Goal: add P12 scripts/prompts under `.pipe/p12/` plus wiring so:
- P12 runs **once** before P2 brainstorm, **outside** the ralph loop (but ralph can invoke the entrypoint when `phase == research` and P2 is missing).
- Greenfield projects skip mapping and go straight to P2.
- Brownfield projects generate living docs (7 YAML-in-fence docs) + evidence cache, then inject confirmed context into P2.
- Returning projects (P2 already done + STATE.yaml exists) offer Continue / Refresh map / Re-brainstorm.

Hard constraints (enforce everywhere):
- Follow the **Canonical P12 Spec** in 0b exactly (do not “improve” it unless explicitly allowed by “Graceful Degradation”).
- Implement the **8 micro-tasks** (0d) in order.
- **Aggressive atomicity:** each micro-task must touch **1–3 files MAX** (do not exceed).
- All bash scripts must pass: `bash -n` and “shellcheck basics” (no obvious SC errors; suppress only with clear justification).
- Scripts must support `--dry-run` where specified by the spec (at minimum: `P12_MAP.sh`, `P12_CONFIRM.sh`, `p12-init.sh`, and the updated `p2-brainstorm.sh`).
- Never block pipeline progress on P12 errors: degrade to greenfield (run P2 without injected context).

Implementation style:
- Match existing script style in this repo: `#!/bin/bash`, `set -uo pipefail`, clear `usage()` blocks, explicit error messages, avoid clever bash.
- Use only POSIX-ish tools that already appear in this repo (bash, find, sed, awk, head, wc, mktemp, etc.). Prefer robustness over fancy parsing.
- Keep logs human-readable; machine outputs must be JSON/YAML exactly as specified.

---

## 0b. Canonical P12 Spec (MUST FOLLOW — verbatim; do not summarize)

# P12 Unified Design — Codebase Mapper / Brownfield Detection

> Synthesized from Opus 4.5 + GPT-5.2 independent designs based on FINAL_PLAN_v5.1.md.
> This is the canonical P12 spec. All implementation follows this document.

---

## Overview

P12 is the **Codebase Mapper** — a pre-loop phase that detects whether a project is greenfield, brownfield, or returning, and for brownfield projects, maps the existing codebase into machine-optimized living docs that enrich the entire downstream pipeline.

**Entry point:** `deadfish init <name>` (or equivalent per target)
**Runs:** Once, before P2 brainstorm, outside the ralph.sh loop
**Output:** Living docs (7 YAML files, <5000 tokens combined) + evidence cache
**Targets:** deadfish-cli, deadfish-pipeline, deadfish skill (shared core + adapters)

---

## 1. Three Scenarios

```
deadfish init <name> [--path <dir>]
       │
       Preflight Detection (pure bash, no LLM)
       │
       ├── GREENFIELD (score < 2 signals)
       │   └── Skip mapping → straight to P2 brainstorm
       │
       ├── BROWNFIELD (score ≥ 2 signals)
       │   └── Mapping → Confirmation → P2 brainstorm (enriched)
       │
       └── RETURNING (.deadf/seed/P2_DONE + STATE.yaml exist)
           └── Offer: [C]ontinue / [R]efresh map / Re-[b]rainstorm
```

---

## 2. Detection Heuristics (P12_DETECT.sh — pure bash)

Signals scored (boolean, 1 point each):
- `sig_git`: `.git/` exists
- `sig_source`: ≥5 source files in known languages (depth 3, excludes node_modules/vendor/etc)
- `sig_deps`: dependency manifest present (package.json, Cargo.toml, go.mod, requirements.txt, pyproject.toml, Gemfile, pom.xml, build.gradle, composer.json, mix.exs)
- `sig_ci`: CI config present (.github/workflows/, .gitlab-ci.yml, Jenkinsfile, .circleci/)
- `sig_docker`: Dockerfile or docker-compose present
- `sig_readme`: README.md exists
- `sig_tests`: test directory exists (tests/, test/, __tests__/, spec/)

**Rule:** ≥2 signals from [sig_git, sig_source, sig_deps, sig_ci] = brownfield

**Returning:** `.deadf/seed/P2_DONE` exists AND `STATE.yaml` exists → returning (checked first, highest priority)

**Output:** JSON to stdout:
```json
{"type": "brownfield|greenfield|returning", "signals": [...], "depth": 1-4, "src_count": N}
```

**Exit codes:** 0=brownfield, 1=greenfield, 2=returning, 3=error

### Dynamic Depth Selection

| Condition | Depth | Estimated Time |
|-----------|-------|----------------|
| <200 source files, good docs | 1 (Quick) | 2-5 min |
| 200-2000 files, mixed signals | 2 (Standard) | 10-20 min |
| 2000+ files, low docs | 3 (Deep) | 20-45 min |
| Monorepo markers, multi-language | 4 (Intensive) | 45-90 min |

MVP ships depth 1-2 only. Depth 3-4 are Phase 2.

---

## 3. Mapping Phase Architecture

### Data Collection (bash, no LLM — P12_COLLECT.sh)

Collects raw evidence into `.deadf/p12/evidence/`:
- `tree.txt` — filtered file tree (depth 4, excludes noise, capped at 500 entries)
- `deps-*.txt` — dependency manifests (first 100 lines each)
- `config-*.txt` — config files (tsconfig, eslint, vite, etc., first 50 lines each)
- `doc-*.md` — existing docs (README, CONTRIBUTING, ARCHITECTURE, first 200 lines each)
- `ci-*.yml` — CI configs (first 80 lines each)
- `entry-*.txt` — entry point files (main/index/app, first 80 lines each)
- `git_hotspots.json` — [Phase 2] hot vs stale files from git history

### Analysis (Claude sub-agents)

Claude sub-agents receive collected evidence and produce structured YAML analysis.

**MVP (depth 1-2): Single agent**
One Claude sub-agent analyzes all collected data.

**Phase 2 (depth 3-4): Parallel agents by domain**
- Agent 1: Stack + Build + CI (`P12_AGENT_STACK.md`)
- Agent 2: Architecture + Entry Points + Modules (`P12_AGENT_ARCH.md`)
- Agent 3: Patterns + Conventions + Tests (`P12_AGENT_PATTERNS.md`)
- Agent 4: Risks + Security + Pitfalls (`P12_AGENT_RISKS.md`)

### Synthesis (GPT-5.2)

GPT-5.2 receives agent analysis + raw evidence and produces the final living docs.

**Prompt:** `P12_SYNTH_GPT52.md`
**Hard constraints:**
- Combined output <5000 tokens
- Only assert what evidence supports — use "unknown" for undetectable items
- Label inferred values with `confidence: low`
- Do not invent commands — mark as inferred

### Confirmation (Interactive — P12_CONFIRM.sh)

Present each living doc section-by-section to operator:
- Show section content
- Ask: `[C]onfirm / [E]dit / [S]kip`
- Write confirmed docs to project root
- Write `.deadf/p12/P12_DONE` marker when complete

**Pipeline target:** Cannot block interactively → write notification + set `phase: needs_human` until operator acknowledges.

---

## 4. Living Docs (Output Format)

Seven machine-optimized YAML files, each with budget tag:

| Doc | Content | Budget |
|-----|---------|--------|
| TECH_STACK.md | Runtime, framework, deps, build, CI, env, commands | ~400t |
| PATTERNS.md | Architecture, code style, naming, conventions | ~400t |
| PITFALLS.md | Known issues, tech debt, dangerous areas | ~300t |
| RISKS.md | Security, config, compliance concerns | ~300t |
| WORKFLOW.md | Process, structure, smart-load map | ~400t |
| PRODUCT.md | What exists today, features, modules | ~400t |
| GLOSSARY.md | Domain terms | ~200t |
| **TOTAL** | | **<5000t** |

### Format (each file)

```markdown
# TECH_STACK.md

```yaml
tech_stack_yaml<=400t:
  runtime: node@20
  framework: express@4
  db: postgres@16/drizzle
  cache: redis@7
  auth: jwt/jose
  test: vitest
  build: tsup
  pm: pnpm
  files:
    entry: src/index.ts
    routes: src/routes/
    models: src/db/schema.ts
  external: [stripe, sendgrid]
  commands:
    dev: npm run dev
    build: npm run build
    test: npm test
    lint: npm run lint
  env:
    required: [DATABASE_URL, JWT_SECRET, STRIPE_KEY]
    config: .env.example
  ci:
    runner: github-actions
    deploy: docker/railway
  sources: [package.json, tsconfig.json, .github/workflows/ci.yml]
  confidence: {overall: high}
`` `
```

### Smart Loading Map (in WORKFLOW.md)

```yaml
smart_load_yaml<=200t:
  by_track_type:
    ui_frontend: [VISION, PATTERNS, WORKFLOW]
    api_backend: [VISION, PATTERNS, TECH_STACK]
    database: [VISION, TECH_STACK, PRODUCT]
    auth_security: [VISION, PATTERNS, RISKS]
    refactor: [VISION, PITFALLS, PATTERNS]
    ambiguous: [VISION, PATTERNS, RISKS, PITFALLS]
```

Downstream P3/P4 can classify track type and load only relevant docs.

---

## 5. P2 Integration (Brownfield Handoff)

### Context Injection

When `CODEBASE_MAP` living docs exist, `p2-brainstorm.sh` prepends a brownfield context block to the P2 prompt:

```markdown
## Existing Codebase Context

This project has an EXISTING codebase. The following was confirmed by the operator.
Use this as ground truth — do NOT re-discover what's already known.
Focus brainstorm on: what to BUILD NEXT, not what already exists.

<tech_stack>
{contents of TECH_STACK.md YAML block}
</tech_stack>

<product_map>
{contents of PRODUCT.md YAML block}
</product_map>

<open_questions>
{list of unresolved items from P12}
</open_questions>

Adjust your Phase 1 SETUP questions:
- Skip "What are we building?" — reference the map.
- Ask: "What do you want to ADD or CHANGE?"
- Ask: "What's the biggest pain point in the current codebase?"
- Ask: "Any protected areas we should NOT touch?"
```

### Modified P2 Entry (brownfield mode)

`p2-brainstorm.sh` gains:
- `--context-mode greenfield|brownfield` flag (auto-detected from P12_DONE)
- `--context-files <comma-separated>` for explicit doc injection
- Auto-prepends context block when brownfield detected

---

## 6. File Structure

```
.pipe/
├── p12/
│   ├── P12_DETECT.sh          # Scenario detection (pure bash)
│   ├── P12_COLLECT.sh         # Raw data collection (pure bash)
│   ├── P12_MAP.sh             # Orchestrates: collect → analyze → synthesize
│   ├── P12_CONFIRM.sh         # Interactive confirmation (operator-facing)
│   ├── P12_INJECT.sh          # Injects context into P2 prompt
│   ├── prompts/
│   │   ├── MAPPER_AGENT.md    # Claude sub-agent analysis prompt (MVP: single agent)
│   │   ├── SYNTHESIZER.md     # GPT-5.2 doc generation prompt
│   │   └── BROWNFIELD_P2.md   # P2 context injection template
│   └── templates/
│       └── LIVING_DOCS.tmpl   # YAML skeleton for all 7 docs
├── p12-init.sh                # Top-level entry point (detect → map → confirm → P2 handoff)
├── p2/
│   └── (existing P2 files)
└── p2-brainstorm.sh           # Updated: --context-mode support
```

Evidence directory (per-project, not in .pipe):
```
.deadf/
├── p12/
│   ├── evidence/              # Raw collected data (tree, deps, configs, docs)
│   ├── P12_DONE               # Marker file
│   └── report.md              # Optional human-readable narrative
└── seed/
    ├── P2_DONE                # Existing P2 marker
    └── P2_BRAINSTORM.md       # Existing P2 ledger
```

---

## 7. Prompt Templates

### MAPPER_AGENT.md (Claude sub-agent — analysis)

```markdown
# Codebase Analysis Agent

You are analyzing an existing codebase. You receive raw evidence (file tree,
dependency files, configs, docs, entry points). Produce a structured YAML
analysis — NOT prose.

## Input
<raw_data>
{collected files concatenated with headers}
</raw_data>

## Rules
- Only assert what evidence directly supports
- Use "unknown" for genuinely undetectable items
- Mark inferred values with confidence: low|medium|high
- Do not invent commands or configs
- Be conservative — false negatives are better than false positives

## Output Contract (YAML only)

```yaml
p12_analysis:
  tech_stack:
    runtime: {lang}@{version or "unknown"}
    framework: {name}@{version or "unknown"}
    db: {type or "none"}
    cache: {type or "none"}
    auth: {method or "unknown"}
    test: {framework or "none"}
    build: {tool or "none"}
    pm: {package_manager}
    files:
      entry: {path}
      routes: {path or "n/a"}
      models: {path or "n/a"}
    external: [{services detected}]
    commands:
      dev: {cmd or "unknown"}
      build: {cmd or "unknown"}
      test: {cmd or "unknown"}
      lint: {cmd or "unknown"}
    env:
      required: [{from .env.example or "unknown"}]
      config: {path or "none"}
    ci:
      runner: {platform or "none"}
      deploy: {method or "unknown"}
  architecture:
    style: {monolith|microservices|serverless|hybrid|unknown}
    modules: [{top-level modules/packages}]
    entry_points: [{paths}]
  patterns:
    code_style: {conventions observed}
    naming: {conventions}
    testing: {approach}
    folder_structure: {pattern}
  pitfalls:
    tech_debt: [{observed issues}]
    dangerous_areas: [{areas to be careful with}]
  risks:
    security: [{concerns}]
    config: [{issues}]
  product:
    features: [{visible features/capabilities}]
    api_endpoints: [{if detectable}]
  glossary:
    terms: [{domain-specific terms found}]
  open_questions:
    - {things that couldn't be determined from evidence}
  confidence:
    overall: {low|medium|high}
    notes: [{what was detected vs inferred}]
`` `
```

### SYNTHESIZER.md (GPT-5.2 — doc generation)

```markdown
# Living Docs Synthesizer

You receive a structured codebase analysis and must produce 7 machine-optimized
living doc files. Each file contains exactly ONE YAML code fence.

## Hard Constraints
- Combined output of ALL docs MUST be <5000 tokens
- Use budget tags: e.g. `tech_stack_yaml<=400t:`
- Use short keys, compact lists, NO prose
- Include `sources:` and `confidence:` fields
- Do not invent — mark unknowns explicitly
- If budget is tight, compress optional docs first (GLOSSARY, then RISKS)

## Input
<analysis>
{YAML analysis from mapper agent}
</analysis>

## Output
Write each file. Use exactly these filenames:
1. TECH_STACK.md (~400t)
2. PATTERNS.md (~400t)
3. PITFALLS.md (~300t)
4. RISKS.md (~300t)
5. WORKFLOW.md (~400t) — MUST include smart_load map
6. PRODUCT.md (~400t)
7. GLOSSARY.md (~200t)

Each file format:
```markdown
# {DOC_NAME}.md

`` `yaml
{doc_name}_yaml<={budget}t:
  {content}
`` `
```
```

### BROWNFIELD_P2.md (P2 context injection template)

```markdown
## Existing Codebase Context

This project has an EXISTING codebase. The following was confirmed by the operator.
Use this as ground truth — do NOT re-discover what's already known.
Focus brainstorm on: what to BUILD NEXT, not what already exists.

<tech_stack>
{{TECH_STACK_YAML}}
</tech_stack>

<product_map>
{{PRODUCT_YAML}}
</product_map>

<open_questions>
{{OPEN_QUESTIONS}}
</open_questions>

Adjust your Phase 1 SETUP questions for brownfield:
- Skip "What are we building?" — reference the map.
- Ask: "What do you want to ADD or CHANGE?"
- Ask: "What's the biggest pain point in the current codebase?"
- Ask: "Any protected areas we should NOT touch?"
- Keep success metrics question as-is.
```

---

## 8. Implementation Micro-Tasks (MVP — Phase 1)

### Micro-task 1: Detection script
**Files:** `.pipe/p12/P12_DETECT.sh`
**Scope:** Pure bash brownfield detection with signal scoring, depth selection, JSON output, exit codes.
**Done when:** `bash -n` passes, `./P12_DETECT.sh /some/repo` outputs valid JSON.

### Micro-task 2: Collection script
**Files:** `.pipe/p12/P12_COLLECT.sh`
**Scope:** Collects raw evidence into `.deadf/p12/evidence/` — tree, deps, configs, docs, CI, entry points.
**Done when:** `bash -n` passes, creates evidence directory with collected files.

### Micro-task 3: Mapper agent prompt + synthesizer prompt
**Files:** `.pipe/p12/prompts/MAPPER_AGENT.md`, `.pipe/p12/prompts/SYNTHESIZER.md`, `.pipe/p12/prompts/BROWNFIELD_P2.md`, `.pipe/p12/templates/LIVING_DOCS.tmpl`
**Done when:** Prompt files exist with full YAML output contracts.

### Micro-task 4: Mapping orchestrator script
**Files:** `.pipe/p12/P12_MAP.sh`
**Scope:** Orchestrates collect → Claude analysis → GPT-5.2 synthesis → writes living docs. Uses single agent for MVP.
**Done when:** `bash -n` passes, can run with `--dry-run`.

### Micro-task 5: Confirmation flow
**Files:** `.pipe/p12/P12_CONFIRM.sh`
**Scope:** Interactive section-by-section confirmation. Confirm/Edit/Skip per doc. Writes P12_DONE marker.
**Done when:** `bash -n` passes, `--dry-run` shows confirmation flow.

### Micro-task 6: Entry point + P2 handoff
**Files:** `.pipe/p12-init.sh`, update `.pipe/p2-brainstorm.sh`
**Scope:** Top-level init script (detect → map → confirm → P2). Update p2-brainstorm.sh with `--context-mode` and brownfield injection.
**Done when:** `bash -n` passes on both, `--dry-run` shows full flow.

### Micro-task 7: Wire ralph.sh + CLAUDE.md
**Files:** `ralph.sh`, `CLAUDE.md`
**Scope:** ralph.sh checks for P12_DONE before P2 dispatch. CLAUDE.md documents P12 phase.
**Done when:** `bash -n ralph.sh` passes, CLAUDE.md references P12.

### Micro-task 8: Budget checker
**Files:** `.pipe/p12/p12-budget-check.sh` (or .py)
**Scope:** Validates combined living docs <5000 tokens (word-count proxy: 1 token ≈ 0.75 words).
**Done when:** Reports pass/fail + per-doc breakdown.

---

## 9. Target Differences

| Component | deadfish-cli | deadfish-pipeline | deadfish skill |
|-----------|-------------|-------------------|----------------|
| **Detection** | Identical | Identical | Identical |
| **Collection** | Identical | Identical | Identical |
| **Agent dispatch** | Claude Task tool | sessions_spawn | Manual (paste prompt) |
| **GPT-5.2 calls** | codex exec | Codex MCP wrapper | codex exec |
| **Confirmation** | Interactive CLI | Notification + needs_human gate | Interactive CLI |
| **P2 handoff** | Direct script call | Notification to run P2 | Manual |
| **Output format** | Identical | Identical | Identical |
| **Token budget** | Identical | Identical | Identical |
| **Prompts** | Identical | Identical | Identical |

Core scripts (detect, collect, budget check, prompts, templates) are 100% shared.
Only the orchestrator (P12_MAP.sh), confirmation (P12_CONFIRM.sh), and entry point (p12-init.sh) need target-specific adapters.

---

## 10. Graceful Degradation

P12 failure is NEVER fatal. Always degrade to greenfield brainstorm.

| Failure | Degradation |
|---------|-------------|
| No git | Skip hotspots, mark confidence: none for git signals |
| No deps manifest | Infer language from extensions, mark confidence: low |
| No CI config | Mark as "local-only", ask operator |
| Repo too large | Cap at 500 files, prioritize entry points, suggest deeper pass |
| LLM call fails | Write deterministic evidence + minimal skeleton docs with "unknown" |
| Confirmation skipped | Proceed with unconfirmed docs, mark as unverified |
| Budget exceeded | Compress optional docs (GLOSSARY first, then RISKS), re-check |

---

## 11. Design Decisions

| Decision | Source | Rationale |
|----------|--------|-----------|
| Seven separate living docs (not one file) | GPT-5.2 / v5.1 spec | Enables smart loading per track type |
| Pure bash detection (no LLM) | Both | Fast, reliable, no token cost |
| Single agent for MVP, parallel for Phase 2 | Opus | Simpler to ship, parallelism is optimization |
| Pre-loop entry point (not inside cycle) | Both | P12 is interactive + runs once, doesn't fit cycle protocol |
| Section-by-section confirmation | Both / v5.1 | Operator can correct individual sections |
| P2 context injection via template | Both | Clean separation — P2_MAIN unchanged, context prepended |
| Brownfield questions replace greenfield setup | Both | Same entry point, adapted questions |
| Evidence cache separate from living docs | GPT-5.2 | Large raw data stays out of cycle context budget |
| Token budget enforced by proxy (word count) | GPT-5.2 | No tiktoken dependency needed |

---

*Synthesized from: p12-design-opus.md (Opus 4.5, 37KB) + p12-design-gpt52.md (GPT-5.2, 21KB)*
*Canonical spec: FINAL_PLAN_v5.1.md*
*Date: 2026-01-30 04:28 EST*

---

## 0c. Existing codebase context (for style + correct wiring; do not “refactor”)

### `.pipe/p2-brainstorm.sh` (current; will be modified in Micro-task 6)
```bash
#!/bin/bash
set -uo pipefail

usage() {
    cat <<'USAGE'
Usage: p2-brainstorm.sh [--project <path>] [--force] [--dry-run]

Runs the P2 brainstorm interactive session using Codex.

Options:
  --project <path>   Project root (default: .)
  --force            Re-run even if .deadf/seed/P2_DONE exists
  --dry-run          Validate inputs and exit without launching Codex
  -h, --help         Show this help
USAGE
}

PROJECT_PATH="."
FORCE=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --project)
            if [[ -z "${2:-}" ]]; then
                echo "Missing value for --project" >&2
                exit 1
            fi
            PROJECT_PATH="$2"
            shift 2
            ;;
        --force)
            FORCE=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown arg: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

if [[ ! -d "$PROJECT_PATH" ]]; then
    echo "Project path does not exist: $PROJECT_PATH" >&2
    exit 1
fi

if ! PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"; then
    echo "Failed to resolve project path: $PROJECT_PATH" >&2
    exit 1
fi

PROMPT_FILE="$PROJECT_PATH/.pipe/p2/P2_MAIN.md"
PROMPT_DIR="$(dirname "$PROMPT_FILE")"
SEED_DIR="$PROJECT_PATH/.deadf/seed"
P2_DONE="$SEED_DIR/P2_DONE"
VISION_FILE="$PROJECT_PATH/VISION.md"
ROADMAP_FILE="$PROJECT_PATH/ROADMAP.md"

if [[ -f "$P2_DONE" && "$FORCE" -ne 1 ]]; then
    echo "P2 already completed: $P2_DONE"
    exit 0
fi

if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "Missing prompt template: $PROMPT_FILE" >&2
    exit 1
fi

if ! mkdir -p "$SEED_DIR"; then
    echo "Failed to create seed dir: $SEED_DIR" >&2
    exit 1
fi

command -v codex &>/dev/null || { echo "codex CLI required but not found" >&2; exit 1; }

if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] Would run: codex -m gpt-5.2 --cd '$PROJECT_PATH' < '<prompt_file>'"
    exit 0
fi

prompt="$(cat "$PROMPT_FILE")"
missing_subprompts=()
for f in "$PROMPT_DIR"/P2_{A,A2,B,C,D,E,F,G}.md; do
    if [[ -f "$f" ]]; then
        prompt+=$'\n\n'"$(cat "$f")"
    else
        missing_subprompts+=("$(basename "$f")")
    fi
done
if [[ ${#missing_subprompts[@]} -gt 0 ]]; then
    echo "Warning: missing sub-prompts: ${missing_subprompts[*]}" >&2
fi

prompt_file="$(mktemp)"
trap 'rm -f "$prompt_file"' EXIT
printf '%s\n' "$prompt" > "$prompt_file"

codex -m gpt-5.2 --cd "$PROJECT_PATH" < "$prompt_file"
exit_code=$?

if [[ "$exit_code" -ne 0 ]]; then
    echo "Codex session failed with exit code $exit_code" >&2
    exit "$exit_code"
fi

if [[ ! -s "$VISION_FILE" || ! -s "$ROADMAP_FILE" ]]; then
    echo "P2 outputs missing or empty: VISION.md and/or ROADMAP.md" >&2
    exit 1
fi

touch "$P2_DONE"
echo "P2 complete: $P2_DONE"
```

### `ralph.sh` (current: P2 dispatch block will be updated in Micro-task 7)
Current P2 dispatch behavior (snippet you must preserve semantics of, while adding “P12 before P2”):
```bash
    # ── P2 Brainstorm (research phase) ───────────────────────────────────
    if [[ "$PHASE" == "research" && ! -f "$PROJECT_PATH/.deadf/seed/P2_DONE" ]]; then
        log "P2 brainstorm required — launching .pipe/p2-brainstorm.sh"
        if ! "$PROJECT_PATH/.pipe/p2-brainstorm.sh" --project "$PROJECT_PATH"; then
            log_err "P2 brainstorm runner failed"
            set_phase_needs_human
            notify "p2-brainstorm-failed" "P2 brainstorm runner failed. Run: .pipe/p2-brainstorm.sh --project \"$PROJECT_PATH\""
            release_lock
            print_summary
            exit 1
        fi
    fi
```

### `CLAUDE.md` (current: seed_docs guidance will be updated in Micro-task 7)
Existing guidance (keep the style; extend with P12 without rewriting the whole contract):
```md
### `seed_docs` (research phase) — P2 Brainstorm Session

This phase is **human-driven**. Claude Code must **NOT** generate seed docs automatically.

Deterministic rule:
1. If `.deadf/seed/P2_DONE` is missing **OR** `VISION.md`/`ROADMAP.md` are missing/empty:
   - set `phase: needs_human`
   - write a notification instructing the operator to run the P2 runner:
     `.pipe/p2-brainstorm.sh --project "<project_root>"`
```

---

## 0d. Micro-task execution order (you must follow; do not reorder)

You must implement Micro-task 1 → 8 in order.
Each micro-task:
- Touch 1–3 files max
- Has its own “Done when” checks (run them)
- Should be implemented as the smallest, shippable MVP (depth 1–2 only; Phase 2 features stubbed)

---

## Micro-task 1 — Detection script (1 file)

**Edit/Create exactly this file:**
- Create: `.pipe/p12/P12_DETECT.sh`

**Requirements:**
- Pure bash; no LLM calls.
- Accept a single positional arg: project dir (default `.`). Resolve to absolute path.
- Implement all signals listed in the spec (including docker/readme/tests), but the *brownfield rule* uses only `[sig_git, sig_source, sig_deps, sig_ci]`.
- Source file count: known languages; depth 3; exclude noisy dirs: `.git/`, `node_modules/`, `vendor/`, `dist/`, `build/`, `.deadf/`, `.venv/`, `__pycache__/`, `.next/`, `.cache/`.
- `sig_source` true when `src_count >= 5`.
- Returning detection: `.deadf/seed/P2_DONE` AND `STATE.yaml` exist (checked first).
- Output JSON exactly: `{"type":"...","signals":[...],"depth":N,"src_count":N}`.
  - `signals` should be a list of the signal names that are true (e.g., `["sig_git","sig_source"]`).
- Dynamic depth selection: MVP supports only depth 1–2 (never output 3–4).
  - Suggestion: default depth=1, upgrade to 2 if src_count >= 200 OR docs weak (no README) OR multiple languages detected.
- Exit codes: 0 brownfield, 1 greenfield, 2 returning, 3 error.

**Done when (run these):**
- `bash -n .pipe/p12/P12_DETECT.sh`
- `shellcheck .pipe/p12/P12_DETECT.sh` (if shellcheck installed)
- `cd /tank/dump/DEV/deadfish-cli && .pipe/p12/P12_DETECT.sh . | python3 -c 'import json,sys;json.load(sys.stdin)'`

---

## Micro-task 2 — Collection script (1 file)

**Edit/Create exactly this file:**
- Create: `.pipe/p12/P12_COLLECT.sh`

**Requirements:**
- Pure bash; no LLM calls.
- Inputs:
  - positional or flag `--project <dir>` (prefer flags for consistency with P2 runner; but keep a simple positional fallback if you want).
  - optional `--depth <n>` (use 1–2 only; default 1).
- Outputs into: `<project>/.deadf/p12/evidence/` (create dirs as needed).
- Create evidence files exactly as spec names:
  - `tree.txt` (filtered, depth 4, capped 500 entries)
  - `deps-*.txt` (first 100 lines)
  - `config-*.txt` (first 50 lines)
  - `doc-*.md` (first 200 lines)
  - `ci-*.yml` (first 80 lines)
  - `entry-*.txt` (first 80 lines)
- Noise exclusions: same as micro-task 1 plus common vendor dirs (you can centralize an exclude list).
- Tree format: stable and readable; include only relative paths; do not exceed 500 lines.
- Entry point detection heuristics: common filenames (main.*, index.*, app.*) and/or language-specific entries (package.json main, pyproject, etc.)—but keep MVP simple and conservative.

**Done when (run these):**
- `bash -n .pipe/p12/P12_COLLECT.sh`
- `shellcheck .pipe/p12/P12_COLLECT.sh` (if shellcheck installed)
- `rm -rf .deadf/p12 && .pipe/p12/P12_COLLECT.sh --project .`
- Verify it created `.deadf/p12/evidence/tree.txt` and at least one `deps-*.txt` or `doc-*.md` when applicable.

---

## Micro-task 3 — Prompt templates (3 files)

**Edit/Create exactly these files (ONLY these three in this micro-task):**
- Create: `.pipe/p12/prompts/MAPPER_AGENT.md`
- Create: `.pipe/p12/prompts/SYNTHESIZER.md`
- Create: `.pipe/p12/prompts/BROWNFIELD_P2.md`

**Requirements:**
- Contents must match the canonical spec sections (0b → “Prompt Templates”) including the YAML output contracts.
- Do not add repo-specific opinions to these prompts; they are shared core.

**Done when:**
- Files exist with the expected sections and YAML contracts.

---

## Micro-task 4 — Mapping orchestrator + living-docs template (2 files)

**Edit/Create exactly these files:**
- Create: `.pipe/p12/P12_MAP.sh`
- Create: `.pipe/p12/templates/LIVING_DOCS.tmpl`

**P12_MAP.sh requirements (MVP):**
- Must support `--dry-run` (no filesystem writes beyond maybe temp; no LLM calls).
- Orchestrates: collect → analysis → synthesis → write candidate docs (UNCONFIRMED) into `<project>/.deadf/p12/out/` (or similar under `.deadf/p12/`; do NOT write to project root in this step).
- Uses single Claude analysis agent:
  - If `claude` CLI exists: run it non-interactively to produce YAML analysis (per MAPPER_AGENT.md). Save to `<project>/.deadf/p12/analysis.yaml`.
  - If `claude` missing or fails: produce a minimal analysis YAML with unknowns and `confidence: low`.
- GPT-5.2 synthesis:
  - If `codex` exists: run a non-interactive GPT-5.2 call that produces the 7 docs.
  - Implementation detail (allowed): require synthesizer output to include deterministic file boundaries so bash can split stdout into 7 files under `.deadf/p12/out/`.
    - Example boundary markers you may define (choose one and implement):
      - `<<<FILE:TECH_STACK.md>>>` … `<<<END_FILE>>>` (repeat per file), OR
      - `---FILE TECH_STACK.md---` … `---END FILE---`
  - If codex fails: fall back to writing skeleton docs from `LIVING_DOCS.tmpl` with “unknown” content.
- Never fatal: any failure must log a warning and return success-ish so callers can continue to P2 (greenfield degrade).

**LIVING_DOCS.tmpl requirements:**
- Contains minimal valid markdown+yaml fences for all 7 docs (with budget tags) filled with `unknown`/empty lists.
- Used by P12_MAP fallback path.

**Done when (run these):**
- `bash -n .pipe/p12/P12_MAP.sh`
- `shellcheck .pipe/p12/P12_MAP.sh` (if shellcheck installed)
- `bash -n .pipe/p12/templates/LIVING_DOCS.tmpl` is not applicable; just ensure it’s valid markdown.
- `.pipe/p12/P12_MAP.sh --project . --dry-run` prints steps it would take (collect, analyze, synthesize, write out).

---

## Micro-task 5 — Confirmation flow (1 file)

**Edit/Create exactly this file:**
- Create: `.pipe/p12/P12_CONFIRM.sh`

**Requirements:**
- Must support `--dry-run` that shows what would be presented/written without modifying project root.
- Reads the 7 candidate docs from `<project>/.deadf/p12/out/` (or whatever directory you used in Micro-task 4).
- Interactive per-doc loop:
  - Show content
  - Prompt `[C]onfirm / [E]dit / [S]kip`
  - Confirm writes that doc to `<project>/<DOCNAME>.md`
  - Edit opens $EDITOR if set, else uses a heredoc input fallback (keep it simple)
  - Skip leaves root doc untouched
- Writes `<project>/.deadf/p12/P12_DONE` marker when confirmation flow completes (even if some docs skipped, but mark unverified somewhere if you implement that).

**Done when (run these):**
- `bash -n .pipe/p12/P12_CONFIRM.sh`
- `shellcheck .pipe/p12/P12_CONFIRM.sh` (if shellcheck installed)
- `.pipe/p12/P12_CONFIRM.sh --project . --dry-run` prints a reasonable preview of the confirm steps.

---

## Micro-task 6 — Entry point + P2 handoff (3 files)

**Edit/Create exactly these files:**
- Create: `.pipe/p12-init.sh`
- Create: `.pipe/p12/P12_INJECT.sh`
- Modify: `.pipe/p2-brainstorm.sh`

**p12-init.sh requirements:**
- Must support `--dry-run` that shows the whole flow without running LLMs or writing root docs.
- Detect scenario via `.pipe/p12/P12_DETECT.sh`.
- Greenfield: skip mapping and run `.pipe/p2-brainstorm.sh` in greenfield mode.
- Brownfield: run `.pipe/p12/P12_MAP.sh` then `.pipe/p12/P12_CONFIRM.sh` then run `.pipe/p2-brainstorm.sh` in brownfield mode (auto injection).
- Returning: offer interactive choice (C/R/B) per spec; in `--dry-run`, print what it would ask/do.

**P12_INJECT.sh requirements:**
- Produces the “Existing Codebase Context” block exactly per spec, using `.pipe/p12/prompts/BROWNFIELD_P2.md`.
- Must be callable by `.pipe/p2-brainstorm.sh` to prepend context.
- Must extract the YAML code-fence contents from:
  - `<project>/TECH_STACK.md`
  - `<project>/PRODUCT.md`
- Must include an `<open_questions>` block:
  - Prefer extracting from `<project>/WORKFLOW.md` or a dedicated file produced by P12_MAP (you may create `<project>/.deadf/p12/open_questions.txt` in Micro-task 4/5 if needed; but do NOT add extra files in this micro-task).

**Update `.pipe/p2-brainstorm.sh` requirements (brownfield injection):**
- Add flags:
  - `--context-mode greenfield|brownfield` (default: auto; auto-detect brownfield if `<project>/.deadf/p12/P12_DONE` exists and root TECH_STACK.md/PRODUCT.md exist)
  - `--context-files <comma-separated>` (explicit doc injection; if provided, use these paths instead of defaults)
- When in brownfield mode:
  - Prepend output of `.pipe/p12/P12_INJECT.sh` to the P2 prompt *before* existing `.pipe/p2/P2_MAIN.md` content.
  - Do not modify `.pipe/p2/P2_MAIN.md` or subprompts.
- `--dry-run` must show whether it would inject context and from which files.

**Done when (run these):**
- `bash -n .pipe/p12-init.sh`
- `bash -n .pipe/p12/P12_INJECT.sh`
- `bash -n .pipe/p2-brainstorm.sh`
- `.pipe/p12-init.sh --project . --dry-run` shows detect→(map?)→(confirm?)→p2.
- `.pipe/p2-brainstorm.sh --project . --dry-run --context-mode brownfield` shows it would inject.

---

## Micro-task 7 — Wire ralph.sh + CLAUDE.md (2 files)

**Edit exactly these files:**
- Modify: `ralph.sh`
- Modify: `CLAUDE.md`

**ralph.sh requirements:**
- Before launching P2 in research phase, ensure P12 has run when appropriate.
  - Minimal MVP behavior: replace the direct call to `.pipe/p2-brainstorm.sh` with `.pipe/p12-init.sh --project "$PROJECT_PATH"`.
  - Must still end up with P2 outputs (`VISION.md`, `ROADMAP.md`, `.deadf/seed/P2_DONE`) for greenfield/brownfield as before.
  - Preserve existing error handling structure (log + needs_human + notification).

**CLAUDE.md requirements:**
- Document P12 in the contract in the most surgical way:
  - Update `seed_docs` guidance so operators are instructed to run `.pipe/p12-init.sh --project "<project_root>"` (instead of (or before) `.pipe/p2-brainstorm.sh`), because P12 must run before P2 when brownfield.
  - Mention `.deadf/p12/P12_DONE` marker and “graceful degradation” (never fatal).
- Do NOT rewrite unrelated sections of the contract.

**Done when (run these):**
- `bash -n ralph.sh`
- Ensure the P2 dispatch block now calls `.pipe/p12-init.sh` in the right place.

---

## Micro-task 8 — Budget checker (1 file)

**Edit/Create exactly this file:**
- Create: `.pipe/p12/p12-budget-check.sh`

**Requirements:**
- Reads the 7 living docs from project root (TECH_STACK.md, PATTERNS.md, PITFALLS.md, RISKS.md, WORKFLOW.md, PRODUCT.md, GLOSSARY.md).
- Computes total “token estimate” using the proxy: `tokens ≈ words / 0.75` (i.e., `tokens = int(words * 4 / 3)`).
- Prints per-doc breakdown + total.
- Exit 0 if total < 5000 tokens, else exit nonzero.
- Keep it pure bash; avoid dependencies.

**Done when (run these):**
- `bash -n .pipe/p12/p12-budget-check.sh`
- `shellcheck .pipe/p12/p12-budget-check.sh` (if shellcheck installed)
- Running it on a project without the docs should print a clear error and nonzero exit.

