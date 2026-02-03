# P12 Design — Codebase Mapper / Brownfield Detection (GPT‑5.2)

This document designs **P12** for the deadf(ish) pipeline: a **single entrypoint** that detects **greenfield / brownfield / returning** and, for brownfield, performs a **multi-pass codebase map** that yields **machine-optimized living docs (<5000 tokens combined)** and then **hands off cleanly into P2**.

Canonical spec source: `/tank/dump/AGENTS/junior/memory/gsd-integration/FINAL_PLAN_v5.1.md`.

Targets required:
1) **deadfish-cli** (Claude Code CLI orchestrator + `codex exec`)
2) **deadfish-pipeline** (Clawdbot + `sessions_spawn`, heartbeat sessions)
3) **deadfish skill** (portable prompt pack + scripts)

---

## 0) Core Goal & Constraints (from v5.1)

P12 must:
- Provide **ONE entry point** with **THREE scenarios**: `greenfield`, `brownfield`, `returning`.
- Detect brownfield via **2+ signals** (e.g., `.git`, source files, deps manifests, CI config).
- Run **dynamic analysis depth**: **1–4 passes** (selected by complexity).
- Generate **living docs** (TECH_STACK, PATTERNS, etc.) that are **machine-optimized YAML** and **<5000 tokens combined**.
- Support **smart loading** (track-type → docs subset).
- Perform **existing doc intake** (README distillation; “hints not truth”).
- Use **git history signals** (hot vs stale) to drive confidence + prioritization.
- Run **interactive confirmation** with operator (per-category validation).
- Provide **seamless transition into P2 brainstorm** (context-enriched).
- Use **Claude sub-agents for mapping**, **GPT‑5.2 for planning/doc synthesis**.
- **Gracefully degrade** when signals/tools are missing.

---

## 1) What in FINAL_PLAN_v5.1 is directly implementable vs needs refinement

### 1.1 Directly implementable (can ship as written)

1) **3-scenario preflight** (`greenfield/brownfield/returning`) with a single entrypoint wrapper.
2) **Brownfield detection heuristic** with “2+ signals” threshold.
3) **Dynamic depth (1–4 passes)** selection based on repo size / signals / ambiguity.
4) **Existing doc intake**: README + common docs → distilled notes + explicit “confidence” markers.
5) **Git history signals**: hot vs stale detection to bias mapping (what to read first) and confidence scoring.
6) **Living docs in YAML** with explicit token budgets per doc + combined cap.
7) **Smart loading mapping** (track type → doc subset) expressed as a tiny YAML map.
8) **Interactive confirmation**: ask operator to confirm/correct extracted claims before proceeding.
9) **Graceful degradation**: partial map ok; fall back to P2 with “we’re missing X” rather than blocking.
10) **Multi-model split**: Claude subagents map; GPT‑5.2 consolidates into docs.

### 1.2 Needs refinement (v5.1 intent is clear, but details must be nailed)

1) **Where P12 lives relative to the pipeline “research/seed_docs” phase**
   - `deadfish-cli` currently auto-runs `.pipe/p2-brainstorm.sh` from `ralph.sh` when `phase: research` and `P2_DONE` missing, which bypasses the “Claude orchestrator decides” contract style in `CLAUDE.md`.
   - Recommendation: P12 should be **owned by the init entrypoint** (preferred), or by the **orchestrator’s research action** (second best), not by Ralph.

2) **Doc set naming vs current pipeline artifacts**
   - v5.1 lists `STATE.md` as a living doc, but the pipeline’s primary state is `STATE.yaml`.
   - Recommendation: keep `STATE.yaml` as authority; introduce a small `STATE.md` only if needed, or embed “current position” in `WORKFLOW.md` / `.deadf/context.json` instead.

3) **“No new files by default” vs “must generate living docs”**
   - Brownfield repos will often not have `TECH_STACK.md`, `PATTERNS.md`, etc.
   - Recommendation: interpret “no new files” as “no *extra* doc sprawl”; i.e., generate only the standard living doc set, avoid arbitrary new names, and if the repo already has equivalents, update by appending a `deadf_*_yaml<=...:` block rather than overwriting.

4) **Interactive confirmation in non-interactive targets**
   - `deadfish-pipeline` is heartbeat-driven; it cannot block for interactive Q&A mid-session.
   - Recommendation: confirmation becomes an **approval gate** via notifications + `phase: needs_human` until operator acknowledges, with a “fast accept” option.

5) **P2 in brownfield mode**
   - Current P2 prompt (`.pipe/p2/P2_MAIN.md`) is phrased as “NEW project brainstorming”.
   - Recommendation: introduce a **P2 brownfield adapter**: same facilitation stance, but the setup questions become “what is this project / what do we want to change / constraints”, seeded by P12 map + doc intake.

---

## 2) P12 ↔ P2 Integration (entrypoint, handoff, context enrichment)

### 2.1 Single entrypoint contract

Define an entrypoint `deadf:init <project_root>` (exact transport differs per target; see §6). The entrypoint performs:

1) **Preflight scenario detection**
2) Branch:
   - **greenfield** → go to **P2** (seed docs) immediately
   - **brownfield** → run **P12 map + confirmation** → then **P2**
   - **returning** → offer options:
     - “Continue” (skip P2, go `select-track`)
     - “Refresh map” (run P12 again at depth 1–2)
     - “Re-brainstorm” (rerun P2, optionally preserving existing VISION/ROADMAP)

### 2.2 Handoff artifacts (what P12 produces for P2)

P12 produces two layers of artifacts:

**A) Living docs (loaded often, must fit <5000 tokens combined):**
- `TECH_STACK.md` (YAML block)
- `PATTERNS.md` (YAML block)
- `PITFALLS.md` (YAML block)
- `RISKS.md` (YAML block)
- `WORKFLOW.md` (YAML block; includes smart-load map)
- `PRODUCT.md` (YAML block; “what exists today”)
- `GLOSSARY.md` (YAML block)

Plus, in brownfield, P12 should create or update:
- `VISION.md` (distilled current purpose + “operator can revise in P2”)
- `ROADMAP.md` (initial draft: suggested tracks derived from map + operator intent in P2)

**B) Evidence cache (NOT loaded every cycle; safe to be large):**
- `.deadf/p12/evidence/` (snapshots: `tree.txt`, `deps.json`, `ci.txt`, `git_hotspots.json`, `readme_distill.md`, etc.)
- `.deadf/p12/report.md` (human-readable narrative; optional)

P2 consumes:
- a **short P12 summary block** (top 20–40 lines max)
- references to living docs (`TECH_STACK.md`, `PRODUCT.md`, etc.)
- “open questions” list to drive facilitation

### 2.3 “Seamless transition” UX

After confirmation, P12 ends with a single, explicit prompt:
- **“What do you want to do next?”**
  - Continue into P2 (default for greenfield/brownfield)
  - Skip to track selection (returning)
  - Refresh map at deeper depth

In `deadfish-cli`, “seamless” can mean: the entrypoint script launches the Codex P2 session immediately.
In `deadfish-pipeline`, “seamless” means: P12 writes a notification telling the operator to run the P2 command (or acknowledges that P2 is deferred).

---

## 3) Brownfield detection & dynamic depth

### 3.1 Brownfield detection (2+ signals)

Signals (examples; treat as boolean or scored):
- `sig_git`: `.git/` exists OR `git rev-parse` succeeds
- `sig_source`: ≥ N source files in known languages (`*.ts`, `*.py`, `*.go`, `*.rs`, `*.java`, etc.)
- `sig_deps`: dependency manifests present (`package.json`, `pyproject.toml`, `requirements.txt`, `go.mod`, `Cargo.toml`, etc.)
- `sig_ci`: CI config present (`.github/workflows/*`, `.gitlab-ci.yml`, `circleci`, etc.)
- `sig_build`: build tooling present (`Makefile`, `Dockerfile`, `compose.yaml`, `turbo.json`, etc.)

Rule:
- **brownfield if ≥ 2** of: `sig_git`, `sig_source`, `sig_deps`, `sig_ci` (v5.1).

Returning detection:
- `.deadf/` exists AND at least one of: `.deadf/seed/P2_DONE`, `STATE.yaml` with non-empty history fields, or existing living docs present.

Greenfield detection:
- Not returning AND not brownfield.

### 3.2 Dynamic analysis depth (1–4 passes)

Define “pass” as a bounded unit of work (time + breadth) with explicit outputs:

**Pass 1 — Quick Map (2–5 min)**
- Deterministic scan (tree + manifests + CI presence + rough languages)
- README intake (if exists)
- Minimal `TECH_STACK.md` + `PRODUCT.md` skeleton + “open questions”

**Pass 2 — Standard Map (10–20 min)**
- Add: entry points (main binaries/servers), test runner, lint, build commands inference
- Add: code conventions sampling (naming, folder conventions)
- Add: initial patterns + pitfalls

**Pass 3 — Deep Map (20–45 min)**
- Add: cross-cutting architecture map (module graph by folder + imports sampling)
- Add: git hotspots (top changed files, last touched times)
- Add: risk inventory (security/auth/config, “footguns”)

**Pass 4 — Intensive Map (45–90 min)**
- Add: multi-agent mapping (Claude subagents parallel domains)
- Add: “brownfield debt” classification (stale vs hot, brittle vs stable)
- Add: “change impact heuristics” (what areas are safest to modify)

Depth selection heuristic (deterministic, tunable):
- `repo_size_small`: < 200 source files
- `repo_size_medium`: 200–2000
- `repo_size_large`: > 2000
- `languages_count`: 1 vs many
- `monorepo_signal`: `pnpm-workspace.yaml`, `turbo.json`, `bazel`, multi package managers
- `doc_quality_signal`: presence of README + architecture docs
- `git_signal`: active commits within last 90 days

Default:
- small + good docs → pass 1–2
- medium or mixed signals → pass 2–3
- large/monorepo/low docs → pass 3–4

---

## 4) Living docs (schemas, budgets, and smart loading)

### 4.1 Living docs rules (machine-optimized)

Each living doc:
- Contains exactly one YAML block (inside a code fence).
- Uses a single top-level key with budget tag, e.g. `tech_stack_yaml<=400t:`.
- Uses short keys, compact lists, and avoids prose.
- Includes `sources:` and `confidence:` fields to indicate what is inferred vs confirmed.

Combined budget:
- Sum of all living-doc YAML blocks must be **<5000 tokens**.
- Enforcement mechanism: simple word-count proxy + re-compress loop (see scripts §5).

### 4.2 Recommended doc set (v5.1 aligned, pipeline-friendly)

Minimum set to ship P12 MVP (covers >80% value):
- `TECH_STACK.md` (~400t)
- `PRODUCT.md` (~400t)
- `PATTERNS.md` (~400t)
- `PITFALLS.md` (~300t)
- `RISKS.md` (~300t)
- `WORKFLOW.md` (~400t; includes smart-loading map)
- `GLOSSARY.md` (~200t)

Optional (only if budget allows):
- `VISION.md` (~300t) and `ROADMAP.md` (~500t) drafts if not present

### 4.3 Smart loading map (track-type → docs)

Store a tiny map in `WORKFLOW.md`:

```yaml
smart_load_yaml<=200t:
  by_track_type:
    ui_frontend: [VISION, PATTERNS, WORKFLOW]
    api_backend: [VISION, PATTERNS, TECH_STACK]
    database: [VISION, TECH_STACK, PRODUCT]
    auth_security: [VISION, PATTERNS, RISKS]
    refactor: [VISION, PITFALLS, PATTERNS]
    ambiguous: [VISION, PATTERNS, RISKS, PITFALLS]
  file_map:
    VISION: VISION.md
    ROADMAP: ROADMAP.md
    TECH_STACK: TECH_STACK.md
    PRODUCT: PRODUCT.md
    PATTERNS: PATTERNS.md
    PITFALLS: PITFALLS.md
    RISKS: RISKS.md
    WORKFLOW: WORKFLOW.md
    GLOSSARY: GLOSSARY.md
```

Downstream usage:
- P3 (pick_track) or P4 (create_spec) can classify `track.type` and load only the mapped docs.

---

## 5) Proposed prompt templates and scripts

### 5.1 Transport-agnostic “core” (recommended)

Create a transport-agnostic core that produces a single JSON “map object” plus living docs:

**Core outputs**
- `.deadf/p12/evidence/p12_scan.json` (deterministic)
- `.deadf/p12/evidence/readme_distill.md` (deterministic + optional LLM)
- Living docs in repo root (LLM-generated YAML blocks)

**Core scripts (portable across targets)**
1) `p12-scan.sh` (or `p12_scan.py`)
   - Input: repo path
   - Output: `p12_scan.json` with:
     - signals, languages, key manifests, ci files, likely commands
     - file counts, folder topography
     - candidate entry points

2) `p12-git-signals.sh` (optional; degrades if no git)
   - Output: `git_hotspots.json` (top files by churn + recency)

3) `p12-budget-check.py`
   - Input: list of living doc files
   - Output: pass/fail + “largest docs” report (word-count proxy)

4) `p12-runner.(sh|py)` (adapter calls core + LLM)
   - Does scenario detection
   - Chooses depth
   - Coordinates subagents + GPT‑5.2 synthesis
   - Runs confirmation gate
   - Hands off to P2

### 5.2 LLM prompt pack (P12)

P12 uses **Claude subagents** for mapping and **GPT‑5.2** for consolidation.

Recommended prompt files (names are suggestions; exact path differs per target):
- `P12_MAIN.md` (orchestrator-facing: what to run, flow, stop conditions)
- `P12_AGENT_STACK.md` (deps + runtime + build/CI)
- `P12_AGENT_ARCH.md` (architecture + entry points + modules)
- `P12_AGENT_PATTERNS.md` (coding conventions + tests + linting)
- `P12_AGENT_RISKS.md` (security, config, pitfalls, dangerous areas)
- `P12_SYNTH_GPT52.md` (GPT‑5.2 consolidation into living docs + draft VISION/ROADMAP)
- `P12_CONFIRM.md` (interactive confirmation script/prompt)

#### Mapping agent output format (low-entropy YAML block)

Each mapper returns **one YAML block** (no prose) to reduce merge friction:

```text
```yaml
p12_map_yaml:
  agent: stack
  confidence: {overall: medium, notes: ["deps detected via package.json", "commands inferred from scripts"]}
  claims:
    runtime: node@20
    package_manager: pnpm
    ci: github-actions
  key_files:
    manifests: ["package.json", "pnpm-lock.yaml"]
    ci: [".github/workflows/ci.yml"]
  open_questions:
    - "Is node version pinned anywhere (.nvmrc/.tool-versions)?"
```
```

#### GPT‑5.2 synthesis prompt (high level)

GPT‑5.2 receives:
- `p12_scan.json`
- git hotspots (if present)
- distilled docs intake (if present)
- mapper YAML blocks

It must output:
- Updated/created living docs YAML blocks (budgeted)
- A short **P12 summary** + **operator questions** for confirmation

Hard guardrails:
- Do not invent commands; label inferred commands with `confidence: low`.
- Keep combined size under budget; if too big, compress/omit optional docs.

### 5.3 Scripts for P2 handoff (brownfield-aware)

Extend the P2 launcher concept to support brownfield enrichment:

- `p2-brainstorm.sh` additions (design):
  - `--context-mode greenfield|brownfield`
  - `--context-files TECH_STACK.md,PRODUCT.md,PATTERNS.md,...` (default: auto)
  - prepend a short “P12 context header” to the P2 prompt:
    - detected stack
    - confirmed commands
    - open questions
    - “do not overwrite existing docs without asking”

P2 prompt changes (design only):
- In brownfield mode, Phase 1 setup questions become:
  1) “What is this project today (your words)?”
  2) “What do you want to achieve next?”
  3) “Constraints (don’t break X, keep Y stable)?”
  4) “Success in 90 days?”
  5) “Non-goals / protected areas?”

---

## 6) Modular architecture (core vs target-specific adapters)

### 6.1 Core (transport-agnostic)

Responsibilities:
- scenario detection (via deterministic scan)
- depth selection (deterministic heuristic)
- evidence collection (tree/deps/ci/git)
- unified internal map schema (`p12_scan.json`)
- doc budget enforcement (word-count proxy)

Core must NOT:
- depend on Claude Code Task tool or `sessions_spawn`
- assume Discord/Clawdbot exists
- assume Codex MCP exists (shell `codex exec` is the common denominator)

### 6.2 deadfish-cli adapter

Mechanics:
- Orchestrator is **Claude Code CLI**.
- Subagents: **Claude Task tool** (parallel tasks).
- GPT‑5.2 calls: `codex exec -m gpt-5.2 --cd <repo>`.
- Confirmation: real interactive CLI prompts (operator in terminal).
- Handoff: can directly launch `.pipe/p2-brainstorm.sh` (Codex interactive session).

Integration placement:
- Preferred: `deadf:init` script run once before `ralph.sh`.
- Acceptable: extend `ralph.sh` preflight in `phase: research` to run P12 before P2 (but this makes Ralph “smarter” than desired).

### 6.3 deadfish-pipeline adapter

Mechanics:
- Orchestrator is **Clawdbot session** (fresh isolated session each heartbeat).
- Subagents: `sessions_spawn` for mapper agents (parallel).
- GPT‑5.2 calls: via Codex MCP wrapper script (per pipeline conventions).
- Confirmation: cannot block; write `.deadf/notifications/p12-confirm.md` and set `phase: needs_human` until operator acknowledges (or approves via a command).
- Handoff: notify operator to run the P2 session (or if P2 is automated in that target, run in “brownfield mode” non-interactively with a strict “don’t overwrite” rule).

### 6.4 deadfish skill (portable)

Deliverable form:
- a prompt pack + scripts that can be copied into any repo:
  - `p12-scan.sh`, `p12-runner.sh` (or python equivalents)
  - `p12-prompts/` markdown templates
  - minimal README: invocation + outputs

Constraints:
- must not assume project-specific helpers (no Clawdbot).
- should work with either `claude` CLI or “copy/paste prompts into chat”.

---

## 7) Implementation micro-tasks (atomic, 1–3 files each)

These are intentionally sized to match deadf(ish) “atomic execution” and to be implementable by gpt‑5.2‑codex later.

### Phase 1 (MVP): detection + single-pass map + docs

1) Add deterministic scanner output
   - Add `scripts/p12_scan.py` (or `p12-scan.sh`)
   - Add `scripts/p12_schema.md` (document the JSON schema)

2) Add git hotspot extractor (optional, degrade gracefully)
   - Add `scripts/p12_git_signals.py`

3) Add budget checker
   - Add `scripts/p12_budget_check.py`

4) Add P12 prompt pack (templates only)
   - Add `.pipe/p12/P12_AGENT_STACK.md`
   - Add `.pipe/p12/P12_AGENT_ARCH.md`
   - Add `.pipe/p12/P12_SYNTH_GPT52.md`

5) Add CLI runner (deadfish-cli adapter)
   - Add `.pipe/p12-map.sh` (calls scan → LLM synth → writes docs)
   - Update `.pipe/p2-brainstorm.sh` to accept `--context-mode` and auto-prepend context header

6) Add confirmation gate (deadfish-cli)
   - Add `.pipe/p12-confirm.sh` (prompts operator; writes “confirmed” marker file)

### Phase 2: multi-pass + parallel subagents + polish

7) Implement depth selection logic
   - Update `.pipe/p12-map.sh` (or python runner) with pass 1–4 selection

8) Add Claude subagent mapping wave
   - Add `.pipe/p12/P12_MAIN.md` to orchestrate subagents
   - Add remaining agent templates (`PATTERNS`, `RISKS`)

9) Add doc intake distillation
   - Add `scripts/p12_doc_intake.py` (README/CHANGELOG/ARCH docs distill)

10) Add returning scenario options UX
   - Update `deadf:init` (or runner) to show Restart/Refine/Continue choices

### Phase 3: target parity (pipeline + skill)

11) Add pipeline adapter glue (deadfish-pipeline)
   - Add equivalent runner + prompts under `deadfish-pipeline/.pipe/p12/`
   - Add notification-based confirmation gate

12) Package portable skill version
   - Update `SKILL.md` (or add `skills/deadfish/p12/` folder) with install + usage

---

## 8) Failure modes & graceful degradation

Design principle: **never block on missing signals**; downgrade confidence and ask the operator.

Common degradations:
- No git available → skip hotspots; rely on file heuristics; mark `confidence.git: none`.
- No dependency manifests → infer language/runtime from file extensions; mark low confidence.
- No CI config → infer “local-only”; ask operator if CI exists elsewhere.
- Repo too large → cap analysis; prioritize hotspots and entry points; suggest pass 4 only if needed.
- LLM call fails → still write deterministic evidence files + a minimal skeleton `TECH_STACK.md` with “unknown” values.

Confirmation gate is the safety valve:
- If confidence is low in critical categories (build/test commands, env vars), require explicit operator confirmation before transitioning to P2 (or annotate prominently in P2 context header).

---

## 9) Summary (what “done” looks like for P12)

P12 is complete when:
- Scenario is correctly detected and displayed.
- Brownfield mapping yields living docs that fit the combined budget.
- Operator has a clear confirmation path and can correct mistakes.
- The system can transition into P2 with enriched context and without overwriting existing docs unexpectedly.
- The implementation works in all three targets via a shared core + thin adapters.

