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
