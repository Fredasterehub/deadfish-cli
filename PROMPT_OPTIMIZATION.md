# PROMPT_OPTIMIZATION.md — deadf(ish) Prompt Optimization Quest

> Ce fichier track la progression de l'optimisation de tous les prompts du pipeline deadf(ish).
> Lire ce fichier + CLAUDE.md suffit pour reprendre le travail dans un contexte vide.

## Status: EN COURS

## Méthodologie
1. Inventorier tous les prompts (P1-P11) ✅
2. Rechercher Ralph Wiggum (original + forks) ✅
3. GPT-5.2 analyse comparative ✅
4. Synthèse et plan d'adoption ✅
5. Implémenter les optimisations (EN COURS)
6. Brainstorm prompt-par-prompt (À FAIRE)

## Recherche Complétée

### Sources analysées
- **snarktank/ralph** — Ryan Carson (PRD-driven, prd.json, progress.txt, AGENTS.md)
- **vercel-labs/ralph-loop-agent** — Vercel SDK (verifyCompletion, stop conditions)
- **ClaytonFarr/ralph-playbook** — PROMPT_plan.md + PROMPT_build.md (0a-0d / 1-4 / 999+ pattern)
- **ghuntley/how-to-ralph-wiggum** — Geoffrey Huntley (original philosophy)
- **GPT-5.2 analyse complète** — `/tmp/ralph-analysis.md` (148 lignes)

### Insights clés adoptés de Ralph
1. **Layered prompt structure** (0a-0d orientation / 1-4 main / 999+ guardrails)
2. **Backpressure earlier** (implementer runs verify.sh before commit)
3. **DET:/LLM: acceptance tagging** (skip LLM verifiers for deterministic criteria)
4. **Plan disposability** (re-plan before escalate)
5. **Evidence bundles** (minimal context per verifier sub-agent)
6. **OPS.md pattern** (split operational cache from CLAUDE.md contract)

---

## Prompt Inventory

### P1 — Cycle Kick (ralph.sh → Claude Code)
- **Quand:** Chaque itération du loop
- **Modèle:** Claude Opus 4.5 (via `claude --print`)
- **Concept:** Trigger mécanique minimal, CLAUDE.md fait le vrai travail
- **Status:** 🔲 À optimiser (Ralph insights: idempotent, cd constraint, reply token constraint)

### P2 — seed_docs (Claude Code → GPT-5.2)
- **Quand:** Phase `research`
- **Modèle:** GPT-5.2 via `codex exec`
- **Concept:** Exploration libre, génère VISION.md / ROADMAP.md
- **Status:** 🔲 À optimiser (brainstorm)

### P3 — pick_track (Claude Code → GPT-5.2)
- **Quand:** Phase `select-track`, aucun track sélectionné
- **Modèle:** GPT-5.2 via `codex exec`
- **Concept:** Sélection du prochain track
- **Status:** 🔲 À optimiser (brainstorm)

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

### Phase 2: Per-Prompt Brainstorm (NEXT)
Go through P1 → P11 one by one, brainstorm with Fred, optimize each.

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

---

### Phase 1.5: GPT-5.2 Review Fixes (DONE)

| # | Fix | Severity | Status |
|---|-----|----------|--------|
| A | DET scope narrowed to verify.sh's 6 actual checks | 🔴 Major | ✅ |
| B | DECIDE table + replan_task action spec added | 🔴 Major | ✅ |
| C | replan_attempted field documented + reset in reflect | 🔴 Major | ✅ |
| D | verify.sh JSON check clarified (exit 0 ≠ pass) | 🟡 Medium | ✅ |
| E | Evidence bundles include ALL changed files | 🟡 Medium | ✅ |

*Last updated: 2026-01-29 21:15 EST*
