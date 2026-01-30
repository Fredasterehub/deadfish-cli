# PROMPT_OPTIMIZATION.md — deadf(ish) Prompt Optimization Quest

> Ce fichier track la progression de l'optimisation de tous les prompts du pipeline deadf(ish).
> Lire ce fichier + CLAUDE.md suffit pour reprendre le travail dans un contexte vide.

## Status: EN COURS

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

## Prompt Inventory

### P1 — Cycle Kick (ralph.sh → Claude Code)
- **Quand:** Chaque itération du loop
- **Modèle:** Claude Opus 4.5 (via `claude --print`)
- **Concept:** Trigger mécanique minimal, CLAUDE.md fait le vrai travail
- **Status:** 🔲 À optimiser (Ralph insights: idempotent, cd constraint, reply token constraint)

### P2 — seed_docs / Brainstorm Session (Claude Code → GPT-5.2)
- **Quand:** Phase `research`
- **Modèle:** GPT-5.2 via `codex exec`
- **Concept:** BMAD-style facilitated brainstorming session. AI is facilitator, human generates ideas. Structured flow: Session Setup → Technique Selection → Guided Ideation (anti-bias, domain shifts, 50-100+ ideas) → Organization (themes, prioritization) → Action Plans → seed docs (VISION.md / ROADMAP.md)
- **Status:** ✅ Implemented (commit `2653d4c`)

### P3 — pick_track (Claude Code → GPT-5.2)
- **Quand:** Phase `select-track`, aucun track sélectionné
- **Modèle:** GPT-5.2 via `codex exec`
- **Concept:** Sélection du prochain track
- **Status:** 🔲 À optimiser — **IN PROGRESS (next brainstorm session)**

### P4 — create_spec (Claude Code → GPT-5.2)
- **Quand:** Phase `select-track`, track choisi mais pas de spec
- **Modèle:** GPT-5.2 via `codex exec`
- **Concept:** Rédaction spec technique
- **Status:** 🔲 À optimiser (brainstorm)

### P5 — create_plan (Claude Code → GPT-5.2)
- **Quand:** Phase `select-track`, spec existe mais pas de plan
- **Modèle:** GPT-5.2 via `codex exec`
- **Concept:** Sentinel DSL plan block
- **Status:** 🔲 À optimiser (Ralph: 0a/0b/0c + don't assume + FILES min + DET:/LLM: tagging)

### P6 — generate_task (Claude Code → GPT-5.2)
- **Quand:** Phase `execute`, sub_step `generate`
- **Modèle:** GPT-5.2 via `codex exec`
- **Concept:** Sentinel DSL task generation
- **Status:** 🔲 À optimiser (same as P5)

### P7 — implement_task (Claude Code → GPT-5.2-Codex)
- **Quand:** Phase `execute`, sub_step `implement`
- **Modèle:** GPT-5.2-Codex (high reasoning) via `codex exec --approval-mode full-auto`
- **Concept:** "Feed the full spec" — TASK.md complet + fichiers existants
- **Status:** 🔲 À optimiser (Ralph: 0a/0b/0c structure + self-backpressure verify.sh)

### P8 — verify.sh (Déterministe)
- **Quand:** Phase `execute`, sub_step `verify`, Stage 1
- **Modèle:** Aucun (bash pur)
- **Concept:** 6 checks déterministes → JSON
- **Status:** ✅ Solide (deadf(ish) supérieur à Ralph ici)

### P9 — LLM Verification (Claude Code → Sub-agents)
- **Quand:** Phase `execute`, sub_step `verify`, Stage 2 (si verify.sh PASS)
- **Modèle:** Claude Opus 4.5 sub-agents via Task tool
- **Concept:** Sentinel Verdict DSL, un sub-agent par AC
- **Status:** 🔲 À optimiser (Ralph: evidence bundles + DET:/LLM: skip logic)

### P10 — Format-Repair Retry
- **Quand:** Quand extract_plan.py ou build_verdict.py fail
- **Modèle:** Même que le prompt original
- **Concept:** One-retry-max avec erreur exacte
- **Status:** 🔲 À optimiser (brainstorm)

### P11 — QA Review (Optionnel)
- **Quand:** Post-implémentation, validation croisée
- **Modèle:** GPT-5.2 via `codex exec`
- **Concept:** Multi-model cross-validation
- **Status:** 🔲 À optimiser (brainstorm)

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
| 1 | P2 — seed_docs / Brainstorm Session | ✅ Implemented (`2653d4c`) |
| 2 | P12 — Codebase Mapper / Brownfield | ✅ Implemented + QA fixed (`a7a924b`) |
| 3 | P3 — pick_track | 🔄 **NEXT** |
| 4 | P4 — create_spec | 🔲 |
| 5 | P5 — create_plan | 🔲 |
| 6 | P6 — generate_task | 🔲 |
| 7 | P7 — implement_task | 🔲 |
| 8 | P9 — LLM Verification | 🔲 |
| 9 | P10 — Format-Repair Retry | 🔲 |
| 10 | P11 — QA Review | 🔲 |
| — | P8 — verify.sh | ✅ Already solid |

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

---

### Phase 1.5: GPT-5.2 Review Fixes (DONE)

| # | Fix | Severity | Status |
|---|-----|----------|--------|
| A | DET scope narrowed to verify.sh's 6 actual checks | 🔴 Major | ✅ |
| B | DECIDE table + replan_task action spec added | 🔴 Major | ✅ |
| C | replan_attempted field documented + reset in reflect | 🔴 Major | ✅ |
| D | verify.sh JSON check clarified (exit 0 ≠ pass) | 🟡 Medium | ✅ |
| E | Evidence bundles include ALL changed files | 🟡 Medium | ✅ |

*Last updated: 2026-01-30 14:30 EST*
