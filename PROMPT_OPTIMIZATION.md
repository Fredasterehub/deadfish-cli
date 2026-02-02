# PROMPT_OPTIMIZATION.md — deadf(ish) Prompt Optimization Quest

> Ce fichier track la progression de l'optimisation de tous les prompts du pipeline deadf(ish).
> Lire ce fichier + CLAUDE.md suffit pour reprendre le travail dans un contexte vide.

## Status: ✅ COMPLETE — All 13 prompts (P1-P12 + P9.5) optimized

## Méthodologie
1. Inventorier tous les prompts (P1-P11) ✅
2. Rechercher Ralph Wiggum (original + forks) ✅
3. GPT-5.2 analyse comparative ✅
4. Synthèse et plan d'adoption ✅
5. Implémenter les optimisations Ralph (Phase 1 + 1.5) ✅
6. Brainstorm prompt-par-prompt — BMAD-style facilitated sessions (EN COURS)

## Recherche Complétée

### Reference Frameworks (Fred's directive — priority order)

#### 🏆 GSD (Get Shit Done) — MAIN REFERENCE for optimal prompts
- **Source:** `/tank/dump/DEV/prompt-research/gsd/`
- **Key patterns adopted:**
  1. **Plans ARE prompts** — no transformation step between plan and execution prompt
  2. **Context quality degrades at 50%+ usage** — aggressive atomicity (2-3 tasks per plan)
  3. **Goal-backward verification** — check truths, not task completion
  4. **Three-level artifact checks** — exists → substantive → wired
  5. **Deviation rules with priority escalation**
  6. **Task sizing for Codex** — GPT-5.2 planner must structure everything knowing Codex needs atomic 2-3 task chunks that complete within 50% context

#### 🧠 BMAD — Brainstorm methodology
- **Source:** `/tank/dump/DEV/prompt-research/bmad/`
- **Used for:** Interactive brainstorm phase (P2 seed_docs) — one-time session with operator
- **Key principles:**
  1. **Facilitator, not generator** — ideas come from the human, AI guides exploration
  2. **Anti-semantic-clustering** — consciously shift creative domains every ~10 ideas
  3. **Quantity over quality first** — first 20 ideas are obvious, magic at 50-100+
  4. **Generative mode as long as possible** — resist organizing too early
  5. **60+ creativity techniques** available for guided ideation
  6. **Anti-bias protocols** — prevent anchoring, groupthink, recency bias

#### 🎼 Google Conductor — Dynamic task generation & context persistence
- **Source:** `/tank/dump/DEV/prompt-research/conductor/`
- **Used for:** Task generation (P6), evaluation patterns, context persistence across cycles

### Analysis Documents
- **Opus analysis:** `/tank/dump/DEV/prompt-research/ANALYSIS.md` (31KB — read 30+ files across all 3 frameworks)
- **GPT-5.2 analysis:** `/tank/dump/DEV/prompt-research/GPT52-ANALYSIS.md` (22KB — focused on prompt architecture patterns)

### Ralph Wiggum Sources (Phase 1 research)
- **snarktank/ralph** — Ryan Carson (PRD-driven, prd.json, progress.txt, AGENTS.md)
- **vercel-labs/ralph-loop-agent** — Vercel SDK (verifyCompletion, stop conditions)
- **ClaytonFarr/ralph-playbook** — PROMPT_plan.md + PROMPT_build.md (0a-0d / 1-4 / 999+ pattern)
- **ghuntley/how-to-ralph-wiggum** — Geoffrey Huntley (original philosophy)
- **GPT-5.2 analyse complète** — `/tmp/ralph-analysis.md` (148 lignes)

### Insights clés adoptés de Ralph (Phase 1)
1. **Layered prompt structure** (0a-0d orientation / 1-4 main / 999+ guardrails)
2. **Backpressure earlier** (implementer runs verify.sh before commit)
3. **DET:/LLM: acceptance tagging** (skip LLM verifiers for deterministic criteria)
4. **Plan disposability** (re-plan before escalate)
5. **Evidence bundles** (minimal context per verifier sub-agent)
6. **OPS.md pattern** (split operational cache from CLAUDE.md contract)

### Key Design Decisions from Research
- **Brainstorming is ONE-TIME** interactive phase with operator, not a per-prompt template
- **After brainstorm, pipeline rolls autonomously** (only approval gates at vision/roadmap)
- **GPT-5.2-Codex needs super small, extremely well-defined tasks** → planner must optimize for Codex's granular digestion
- **GSD's plans-as-prompts** is strictly better than our current transform-then-execute pattern

---

## End-to-End Lifecycle Status

| Phase | What It Does | Components | Status |
|-------|-------------|------------|--------|
| **1. INIT (P12)** | Detect green/brown/returning, map codebase → living docs, confirm with operator | `p12-init.sh`, `P12_DETECT.sh`, `P12_COLLECT.sh`, `P12_MAP.sh`, `P12_CONFIRM.sh`, `P12_INJECT.sh`, 3 prompts, budget checker | ✅ Implemented |
| **2. RESEARCH (P2)** | BMAD brainstorm → VISION.md + PROJECT.md + REQUIREMENTS.md + ROADMAP.md + STATE.yaml | `p2-brainstorm.sh`, P2_MAIN + P2_A through P2_G (9 prompts), P2_PROJECT_TEMPLATE, P2_REQUIREMENTS_TEMPLATE, P2_ROADMAP_TEMPLATE | ✅ Restructured (5-doc output) |
| **3. SELECT-TRACK (P3-P5)** | Pick track (phase-aware), create JIT spec, create plan (plans-as-prompts) | P3_PICK_TRACK.md, P4_CREATE_SPEC.md, P5_CREATE_PLAN.md + CLAUDE.md contract | ✅ Implemented (sentinel TRACK/SPEC/PLAN blocks) |
| **4. EXECUTE (P6-P7)** | Generate task, implement (Codex), self-backpressure verify | Contract in CLAUDE.md | ⚠️ Contract only |
| **5. VERIFY (P8-P9)** | Deterministic checks (bash) + LLM verification (sub-agents) | `verify.sh` (P8) | ✅ P8 implemented / ⚠️ P9 contract only |
| **6. REFLECT** | Commit/retry/replan/escalate, track completion | Contract in CLAUDE.md | ⚠️ Contract only |
| **SUPPORT** | Loop controller, parsers, state, policy | `ralph.sh`, `extract_plan.py`, `build_verdict.py`, `CLAUDE.md`, `STATE.yaml`, `POLICY.yaml` | ✅ All implemented |

*Updated as prompts are optimized. "Contract only" = logic defined in CLAUDE.md but no dedicated prompt templates or scripts yet.*

---

## Prompt Inventory

### P1 — Cycle Kick (ralph.sh → Claude Code)
- **Quand:** Chaque itération du loop
- **Modèle:** Claude Opus 4.5 (via `claude --print`)
- **Concept:** Trigger mécanique minimal, CLAUDE.md fait le vrai travail
- **Implémentation:** `.pipe/p1/P1_CYCLE_KICK.md`, `.pipe/p1/p1-cron-kick.sh`
- **Status:** ✅ Implemented

### P2 — seed_docs / Brainstorm Session (Claude Code → GPT-5.2)
- **Quand:** Phase `research`
- **Modèle:** GPT-5.2 via `codex exec`
- **Concept:** BMAD-style facilitated brainstorming session. AI is facilitator, human generates ideas. Structured flow: Session Setup → Technique Selection → Guided Ideation (anti-bias, domain shifts, 50-100+ ideas) → Organization (themes, prioritization) → Crystallize (5 blocks: VISION/PROJECT/REQUIREMENTS/ROADMAP/STATE) → Output (5 docs) → Adversarial Review (all 5 docs)
- **Outputs:** VISION.md (constitution), PROJECT.md (living context), REQUIREMENTS.md (checkable reqs w/ IDs + DET/LLM criteria), ROADMAP.md (phases-only, no tracks), STATE.yaml (init)
- **Templates:** P2_PROJECT_TEMPLATE.md, P2_REQUIREMENTS_TEMPLATE.md, P2_ROADMAP_TEMPLATE.md
- **Status:** ✅ Restructured (commits `2653d4c` → `ee996cd`)

### P3 — pick_track (Claude Code → GPT-5.2)
- **Quand:** Phase `select-track`, aucun track sélectionné
- **Modèle:** GPT-5.2 via Codex MCP
- **Prompt:** `.pipe/p3/P3_PICK_TRACK.md`
- **Concept:** Phase-aware track selection. Reads STATE.yaml + ROADMAP.md + REQUIREMENTS.md. Outputs sentinel TRACK block (<<<TRACK:V1:NONCE=...>>>). Supports PHASE_COMPLETE and PHASE_BLOCKED signals for phase transitions. Rules: maximize progress on unmet criteria, prefer unblocked reqs, 2-5 tasks/track, never outside current phase.
- **Status:** ✅ Implemented (commit `1d8c237`)

### P4 — create_spec (Claude Code → GPT-5.2)
- **Quand:** Phase `select-track`, track choisi mais pas de spec
- **Modèle:** GPT-5.2 via Codex MCP
- **Prompt:** `.pipe/p4/P4_CREATE_SPEC.md`
- **Concept:** JIT spec generation (Conductor-style "search first"). Reads STATE.yaml + ROADMAP.md + REQUIREMENTS.md + PROJECT.md + OPS.md + codebase search evidence. Outputs sentinel SPEC block (<<<SPEC:V1:NONCE=...>>>) with AC→REQ traceability, DET/LLM tagging, anti-hallucination guardrails for EXISTING_CODE. Writes to `.deadf/tracks/{track_id}/SPEC.md`.
- **Status:** ✅ Implemented (commit `1d8c237`)

### P5 — create_plan (Claude Code → GPT-5.2)
- **Quand:** Phase `select-track`, spec existe mais pas de plan
- **Modèle:** GPT-5.2 via Codex MCP
- **Prompt:** `.pipe/p5/P5_CREATE_PLAN.md`
- **Concept:** Plans-as-prompts (GSD pattern). SUMMARY field IS the gpt-5.2-codex implementation prompt — no transformation step. Reads STATE.yaml + SPEC.md + PROJECT.md + OPS.md. Outputs sentinel PLAN block (<<<PLAN:V1:NONCE=...>>>) with 2-5 tasks, ≤200 diff lines each, ≤5 files/task. Every SPEC AC appears in exactly one task. Writes to `.deadf/tracks/{track_id}/PLAN.md`.
- **Status:** ✅ Implemented (commit `1d8c237`)

### P6 — generate_task (Claude Code → GPT-5.2)
- **Quand:** Phase `execute`, sub_step `generate`
- **Modèle:** GPT-5.2 via Codex MCP
- **Prompt:** `.pipe/p6/P6_GENERATE_TASK.md`
- **Concept:** Sentinel DSL task generation with drift detection. Happy path: next task from PLAN. Drift path: re-plan if plan_base_commit diverged. Retry path: inject retry context from failed verify. Hard stops: 3 consecutive failures → needs_human.
- **Status:** ✅ Implemented (commit `7d855e1`)

### P7 — implement_task (Claude Code → GPT-5.2-Codex)
- **Quand:** Phase `execute`, sub_step `implement`
- **Modèle:** GPT-5.2-Codex (high reasoning) via `codex exec --approval-mode full-auto`
- **Prompt:** `.pipe/p7/P7_IMPLEMENT_TASK.md`
- **Concept:** 5-section template (IDENTITY/TASK PACKET/DIRECTIVES/GUARDRAILS/DONE CONTRACT). No planning preamble. TASK packet injected verbatim from P6. Batch FILES_TO_LOAD reads first. 3-iteration fix cap with best-passing fallback. Fixed reasoning_effort=high (no xhigh). Git-as-IPC. Stateless (retry via TASK packet). Scope escape valve via TODO comments.
- **Status:** ✅ Implemented (commit `4e0631e`, reviewed by Opus + GPT-5.2)

### P8 — verify.sh (Déterministe)
- **Quand:** Phase `execute`, sub_step `verify`, Stage 1
- **Modèle:** Aucun (bash pur)
- **Concept:** 6 checks déterministes → JSON
- **Status:** ✅ Solide (deadf(ish) supérieur à Ralph ici)

### P9 — LLM Verification (Claude Code → Sub-agents)
- **Quand:** Phase `execute`, sub_step `verify`, Stage 2 (si verify.sh PASS)
- **Modèle:** Claude Opus 4.5 sub-agents via Task tool
- **Prompt:** `.pipe/p9/P9_VERIFY_CRITERION.md`
- **Concept:** Per-criterion sub-agent verification with three-level check (Exists → Substantive → Wired from GSD). One sub-agent per LLM: criterion, parallel fan-out (up to 7). Evidence bundles (~4K tokens): verify.sh JSON + git stat + relevant diff hunks + task context. Block-only sentinel VERDICT output. Conservative default (uncertain → NO). Pre-parse regex + one format-repair retry. DET: criteria auto-skip. Untagged → LLM: with warning.
- **Status:** ✅ Implemented (commit `d8b073c`, dual-brain synthesis + 3 review rounds)

### P9.5 — Reflect (Claude Code → GPT-5.2)
- **Quand:** Phase `execute`, sub_step `reflect`, after verify PASS
- **Modèle:** GPT-5.2 via Codex MCP (or Claude Code directly)
- **Concept:** Conductor-inspired living docs update. After each completed task: extract lessons learned, update PATTERNS.md/PITFALLS.md/TECH_STACK.md with new conventions/gotchas/deps discovered during implementation. Re-evaluate project understanding based on what was just built. Feed enriched context back into next cycle. Dynamic vs static — docs evolve with the codebase.
- **Status:** ✅ Implemented (commit `233dbf5`, dual-brain synthesis + 2 review rounds)

### P10 — Format-Repair Retry + Auto-Diagnose (3-Tier Escalation)
- **Quand:** When any sentinel parser rejects LLM output (extract_plan.py, pre-parse regex for VERDICT/REFLECT/QA_REVIEW)
- **Modèle:** Tier 1: same model as original. Tier 2: GPT-5.2-high diagnostic agent
- **Prompts:** `.pipe/p10/P10_FORMAT_REPAIR.md` (Tier 1), `.pipe/p10/P10_AUTO_DIAGNOSE.md` (Tier 2)
- **Concept:** 3-tier escalation: Tier 1 = universal format-repair template with per-block FORMAT_CONTRACT injection, 9-item repair checklist, 16-entry common fixes cookbook, one retry max. Tier 2 = auto-diagnose agent (GPT-5.2-high) that reads parser source + both failed outputs, either fixes the block or reports structural mismatch → queued tooling repair task. Tier 3 = per-block failure policy (planner→CYCLE_FAIL, verdict→NEEDS_HUMAN, reflect→non-fatal, QA_REVIEW→accept with warnings). Empty output guard (<50 chars → skip P10). Traceback detection (skip P10 on parser bugs). P10 attempts tracked separately from task.retry_count.
- **Status:** ✅ Implemented (Tier 1: commit `244aa1e`, Tier 2+3: commit `dbaf2c0`)

### P11 — QA Review (Track-Level Quality Gate)
- **Quand:** After last task's reflect, before track completion (sub_step: qa_review)
- **Modèle:** GPT-5.2 (primary) via Codex MCP, Claude Opus 4.5 (second opinion on FAIL+HIGH)
- **Prompt:** `.pipe/p11/P11_QA_REVIEW.md`
- **Concept:** Track-level holistic review enforcing living docs compliance, cross-task consistency, architectural coherence, scope sanity, safety, and track completeness. 6 categories (C0-C5), fixed-shape QA_REVIEW sentinel block with FINDINGS_COUNT/REMEDIATION_COUNT. Default ON with smart skips (single-task tracks, empty docs, trivial diffs). Bounded remediation (max 1 task, then accept with warnings). Second opinion from Opus on FAIL+HIGH findings. C5 CRITICAL safety findings cannot be casually overridden. Integrated via DECIDE table row 13.5 with explicit state transitions.
- **Status:** ✅ Implemented (commit `dbaf2c0`, dual-brain synthesis + 2 GPT-5.2 review rounds + Opus QA)

### P12 — Codebase Mapper / Brownfield Detection (Preflight → Claude Code sub-agents)
- **Quand:** Phase `research`, before P2, when brownfield detected
- **Modèle:** Claude sub-agents (dynamic count) for mapping, GPT-5.2 for doc generation
- **Concept:** Transparent preflight that detects greenfield/brownfield/returning. For brownfield: scans repo (structure, deps, patterns, git history), generates machine-optimized living docs (TECH_STACK.md, PATTERNS.md, PITFALLS.md, etc.), runs interactive confirmation with operator, then seamlessly transitions into P2 brainstorm with enriched context. Both green and brownfield converge into same brainstorm entry point.
- **Spec:** `memory/gsd-integration/FINAL_PLAN_v5.1.md`
- **Status:** ✅ Implemented + QA fixed (`a7a924b`)

---

## Implementation Plan (Ralph Optimizations)

### Phase 1: Ralph Adaptations (CURRENT)

| # | Action | Impact | Effort | Status |
|---|--------|--------|--------|--------|
| 1 | Restructurer P5/P6 avec 0a/0b/0c + "don't assume, search first" | 🔴 Élevé | Moyen | ✅ |
| 2 | Ajouter verify.sh dans P7 (Codex self-backpressure) | 🔴 Élevé | Faible | ✅ |
| 3 | DET:/LLM: tagging dans acceptance criteria | 🟡 Moyen | Faible | ✅ |
| 4 | "Re-plan" action avant needs_human | 🟡 Moyen | Moyen | ✅ |
| 5 | Evidence bundles pour P9 verifiers | 🟡 Moyen | Moyen | ✅ |
| 6 | OPS.md pattern (split CLAUDE.md) | 🟢 Faible | Faible | ✅ |

### Phase 2: Per-Prompt Brainstorm (CURRENT)

BMAD-style facilitated sessions with Fred, one prompt at a time.
Each session follows the structured flow:

1. **Session Setup** — define the prompt's purpose, goals, constraints, current gaps
2. **Technique Selection** — pick ideation approach (user-selected, AI-recommended, random, progressive)
3. **Technique Execution** — guided ideation with creativity techniques, anti-bias protocols, anti-semantic-clustering (domain shift every ~10 ideas), quantity over quality (push past obvious 20 → aim for 50-100+)
4. **Idea Organization** — theming & prioritization (ONLY after generative phase exhausted)
5. **Action Plans** — top ideas become concrete prompt changes

**Key principles:**
- AI = facilitator, not generator. Ideas come from Fred, AI guides exploration.
- Stay in generative mode as long as possible. Resist organizing too early.
- Anti-semantic-clustering: consciously shift creative domains to avoid 50 variations of the same concept.
- First 20 ideas are obvious. Magic happens at 50-100.

**Review order:**

| # | Prompt | Status |
|---|--------|--------|
| 1 | P2 — seed_docs / Brainstorm Session | ✅ Implemented + Restructured 5-doc output (`2653d4c` → `ee996cd`) |
| 2 | P12 — Codebase Mapper / Brownfield | ✅ Implemented + QA fixed (`a7a924b`) |
| 3 | P3 — pick_track | ✅ Implemented — phase-aware sentinel TRACK (`1d8c237`) |
| 4 | P4 — create_spec | ✅ Implemented — JIT spec sentinel SPEC (`1d8c237`) |
| 5 | P5 — create_plan | ✅ Implemented — plans-as-prompts sentinel PLAN (`1d8c237`) |
| 6 | P6 — generate_task | ✅ Implemented (`7d855e1`) |
| 7 | P7 — implement_task | ✅ Implemented (`4e0631e`) |
| 8 | P9 — LLM Verification | ✅ Implemented (`d8b073c`) |
| 9 | P10 — Format-Repair Retry + Tier 2 Auto-Diagnose | ✅ Tier 2+3 added (`dbaf2c0`) |
| 10 | P11 — QA Review | ✅ Implemented (`dbaf2c0`) |
| — | P8 — verify.sh | ✅ Already solid |
| — | P1 — Cycle Kick | ✅ Implemented |

### Phase 3: Integration Testing
Run the optimized pipeline on a real project, verify improvements.

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-01-29 | Adopt Ralph layered prompt structure (0a/1/999) | Farr playbook + GPT-5.2 both recommend; proven to reduce "agent wandering" |
| 2026-01-29 | Keep Sentinel DSL (don't switch to Ralph's simpler format) | Our parser strictness > Ralph's freeform; nonce integrity is a real advantage |
| 2026-01-29 | Keep verify.sh as primary gate | deadf(ish) deterministic verification is strictly better than Ralph's generic "run tests" |
| 2026-01-29 | Add self-backpressure to Codex | Ralph's key insight: implementer should validate before handing off |
| 2026-01-29 | GPT-5.2 NO TIMEOUT rule | Fred directive: GPT-5.2 is slow, that's normal. Never set timeouts. |
| 2026-01-30 | GSD = main prompt reference | GSD's plans-as-prompts, context budgets, aggressive atomicity are the primary patterns |
| 2026-01-30 | BMAD = brainstorm methodology only | One-time interactive facilitation for P2 seed_docs, not a per-prompt template |
| 2026-01-30 | Conductor = task generation/context persistence | Informs P6 (generate_task) and cross-cycle context management |
| 2026-01-30 | Brainstorm is interactive with Fred | BMAD-style facilitated sessions, not automated — AI facilitates, Fred generates ideas |
| 2026-01-30 | P2 outputs 5 files (not 2) | VISION + PROJECT + REQUIREMENTS + ROADMAP + STATE.yaml — GSD-inspired split for token efficiency and semantic clarity |
| 2026-01-30 | VISION/PROJECT split | VISION = constitution (rarely changes), PROJECT = living context (accumulates decisions) — different change frequencies justify separate files |
| 2026-01-30 | Skip STATE.md, enrich STATE.yaml | Autonomous pipeline doesn't need human-readable state file; project header in STATE.yaml |
| 2026-01-30 | ROADMAP = phases only | Tracks planned JIT at P3/P4; roadmap stays strategic (success criteria + requirement refs) |
| 2026-01-30 | REQUIREMENTS.md with DET/LLM pre-tagging | Acceptance criteria tagged at P2 time, inherited downstream to verify.sh — no re-classification |
| 2026-01-30 | P3 = phase-aware track selection | Sentinel TRACK block with PHASE_COMPLETE/PHASE_BLOCKED signals for automatic phase transitions |
| 2026-01-30 | P4 = Conductor JIT adapted | Codebase search replaces interactive Q&A; requirement tracing replaces user input |
| 2026-01-30 | P5 = plans-as-prompts | GSD pattern: SUMMARY field IS the Codex implementation prompt, zero transformation |
| 2026-01-30 | Track artifacts in .deadf/tracks/ | Per-track ephemeral storage (SPEC.md, PLAN.md, tasks/) — not polluting project root |

---

### Phase 1.5: GPT-5.2 Review Fixes (DONE)

| # | Fix | Severity | Status |
|---|-----|----------|--------|
| A | DET scope narrowed to verify.sh's 6 actual checks | 🔴 Major | ✅ |
| B | DECIDE table + replan_task action spec added | 🔴 Major | ✅ |
| C | replan_attempted field documented + reset in reflect | 🔴 Major | ✅ |
| D | verify.sh JSON check clarified (exit 0 ≠ pass) | 🟡 Medium | ✅ |
| E | Evidence bundles include ALL changed files | 🟡 Medium | ✅ |

*Last updated: 2026-01-30 21:40 EST*
