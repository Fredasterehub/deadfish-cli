# Phase 4 QA Review — CLAUDE.md Restructure

**Reviewer:** Claude Opus 4.5 (sub-agent)  
**Date:** 2026-02-03  
**Old version:** v2.4.2 (1,239 lines)  
**New version:** v3.0 (142 lines) + 4 rules files (85 lines)  

---

## Overall Verdict: NEEDS_FIXES

**2 MEDIUM issues, 2 LOW issues. No CRITICAL or HIGH.**

The restructure is excellent — a massive 10:1 compression that preserves essentially all behavioral semantics. The inline compression approach (action invariants as dense prose paragraphs) is effective and the DECIDE table is well-constructed. However, there are a few gaps.

---

## Criterion 1: Completeness — PASS (with notes)

### Preserved ✅
- All 15 actions and their full behavioral specifications
- 6-step cycle protocol (LOAD → VALIDATE → DECIDE → EXECUTE → RECORD → REPLY)
- Identity / role boundaries
- Write authority table
- Nonce derivation (hex vs sha256 fallback, regex)
- Budget checks (exceeded + 75% warning)
- State locking (flock, atomic R-M-W, bounded wait)
- Dual-lock model (cron.lock + STATE.yaml.flock)
- All sentinel parsing rules (PLAN, VERDICT, REFLECT, QA_REVIEW block formats)
- P10 3-tier escalation with all tier details and per-block policies
- P9.5 reflect (Part A + Part B, smart loading, 4-action protocol, budgets, scratch buffer)
- QA review (evidence caps, parser rules, R2 rule, remediation logic, C5 arbitration)
- Task Management (gate, naming, dedup, recovery/backfill, sub_step→action mapping, steps_before)
- Stuck detection (replan → escalate progression)
- Plan disposability rationale
- Notification matrix (yolo/hybrid/interactive)
- Model dispatch table
- verify.sh contract (DET:/LLM: tagging, 6 checks, combined verdict logic)
- rollback_and_escalate (stash, rescue branch, suffix logic)
- generate_task (happy/drift/retry paths, hard stops)
- implement_task (codex exec dispatch, git facts capture, first-commit edge case)
- All state transition rules (baselines, stuck_count, retry_count resets)
- No-progress definition
- Sub-agent dispatch via Task tool (up to 7 parallel)
- Pre-parse regex validation for verdicts
- One repair retry for malformed verdicts
- Task list lifecycle (cron-kick.sh, rotation, reset procedures)

### Path Migration (old → new) ✅
All `.pipe/pN/` paths correctly migrated to `.deadf/templates/` and `.deadf/contracts/` paths. Verified all 22 referenced paths exist on disk.

### Minor Gaps (not behavioral):
- **Sentinel block format examples** (PLAN block format, VERDICT block format, QA_REVIEW block format) — the old CLAUDE.md had full code-block examples with field-by-field syntax. The new version compresses these into prose. This is acceptable because the authoritative format lives in `.deadf/contracts/sentinel/*.v1.md` which are read at execution time. However, the `build_verdict.py` stdin format (JSON array of pairs) is preserved only implicitly.
- **Cycle Kick / Launcher section** — the old had a dedicated section with CLI invocation reference. The new version covers the key points (dual-lock, task list lifecycle) in other sections. The canonical kick template path (`.deadf/templates/kick/cycle-kick.md`) exists on disk but isn't explicitly referenced in the new CLAUDE.md. Non-blocking since the launcher operates independently.
- **Sub-Agent Dispatch section** — the old had a dedicated section. The new inlines this into verify.facts. Adequate.

---

## Criterion 2: DECIDE Table — PASS

### Row count: 15 ✅
Exactly 15 rows, matching the spec requirement.

### All actions present ✅
| # | Old Action | New Action | Status |
|---|-----------|-----------|--------|
| 1 | escalate | needs_human | ✅ Renamed (semantic improvement) |
| 2 | escalate | needs_human | ✅ Renamed |
| 3 | replan_task | replan_task | ✅ |
| 4 | rollback_and_escalate | rollback_and_escalate | ✅ |
| 5 | retry_task | retry_task | ✅ |
| 6 | seed_docs | seed_docs | ✅ |
| 7 | pick_track | pick_track | ✅ |
| 8 | create_spec | create_spec | ✅ |
| 9 | create_plan | create_plan | ✅ |
| 10 | generate_task | generate_task | ✅ |
| 11 | implement_task | implement_task | ✅ |
| 12 | verify_task | verify.facts | ✅ Renamed (semantic improvement) |
| 13 | reflect | reflect | ✅ |
| 13.5→14 | qa_review | qa_review | ✅ Renumbered from 13.5 to 14 |
| 14→15 | summarize | summarize | ✅ Renumbered from 14 to 15 |

### Template paths — PASS ✅
All Template column paths verified to exist on disk. N/A entries are correct for actions that don't use templates (needs_human, replan_task, retry_task, rollback_and_escalate, seed_docs, summarize, verify.facts, implement_task output).

### Output Grammar paths — PASS ✅
All Output Grammar paths verified to exist on disk.

### Note on rows 1-2 naming
Old CLAUDE.md row 1 was `escalate` and row 2 was `escalate`. New version uses `needs_human` for both. This is a semantic rename — the behavior described in the action invariants section matches (set `phase: needs_human`, notify). The standalone `escalate` action still exists in the action invariants for explicit escalation cases. **Acceptable.**

---

## Criterion 3: Rules Files — PASS

### Complement without duplication ✅
- **core.md** (24 lines): Role boundaries, one-cycle-one-action, write authority, state mutability, worker roles. These are invariants that apply to every cycle. Minimal overlap with CLAUDE.md § Identity — the CLAUDE.md section is a brief summary while the rules file is the authoritative invariant list.
- **state-locking.md** (26 lines): Flock discipline, atomic R-M-W pattern (with code example), nonce timing, dual-lock, timeout behavior. Complements the brief "Nonce & Locking" section in CLAUDE.md.
- **safety.md** (20 lines): Blocked paths, tool/role restrictions, verifier precedence, determinism preference. Replaces the old "Safety Constraints" numbered list.
- **output-contract.md** (15 lines): Final line token rule, sentinel block-only rules, CYCLE_OK/CYCLE_FAIL/DONE conditions. Clean extraction.

### Accurate extractions ✅
All content in the rules files traces back to specific sections of the old CLAUDE.md (Identity, State Write Authority, Safety Constraints, Reply step).

### Total: 85 lines ✅

---

## Criterion 4: Spec Compliance — PASS (with note)

Comparing against Section C of synthesis-v2-final.md:

| Spec Requirement | New CLAUDE.md | Status |
|-----------------|---------------|--------|
| Identity & Role Boundaries (~25 lines) | Lines 1-12 | ✅ |
| Setup: Multi-Model via Codex MCP (~15 lines) | Lines 14-22 | ✅ |
| Cycle Protocol (~50 lines) | Lines 24-80+ (action invariants inline) | ✅ Exceeded but justified |
| DECIDE Table (~40 lines) | Lines 96-117 | ✅ |
| State Schema Reference (~15 lines) | Lines 119-126 | ✅ |
| Model Dispatch Reference (~20 lines) | Lines 128-136 | ✅ |
| Nonce & Locking (~15 lines) | Lines 138-143 | ✅ (trimmed) |
| Task Management (~15 lines) | Within Cycle Protocol | ✅ Integrated |
| Quick Reference (~15 lines) | Lines 132-142 | ✅ |
| .claude/rules/ belt-and-suspenders in LOAD | Line 35-39 | ✅ |
| No @import anywhere | Verified | ✅ |
| Explicit read references to templates | DECIDE table + action invariants | ✅ |
| Total ≤300 lines | 142 lines | ✅ |

**Note:** The spec suggested ~210-250 lines. The actual is 142 — even more compressed. The action invariants are extremely dense prose paragraphs. This is aggressive but functional since the templates/contracts are the authoritative source and are read at execution time.

---

## Criterion 5: Line Count — PASS ✅

- CLAUDE.md: **142 lines** (well under 300 limit)
- Rules files: 85 lines total (24 + 26 + 20 + 15)
- Combined: 227 lines

---

## Criterion 6: Path Accuracy — NEEDS_FIXES

### Verified paths (all exist on disk) ✅
All 22 `.deadf/` paths referenced in the DECIDE table and action invariants verified via `find` + individual `test -f`:
- All 10 template paths exist
- All 6 sentinel contract paths exist  
- All 3 schema paths exist
- verify.sh, build-verdict.py, cron-kick.sh exist

### Issues Found:

#### MEDIUM-1: `extract_plan.py` path ambiguity
The new CLAUDE.md references `extract_plan.py` 4 times (lines 48, 51, 65, 135) without a `.deadf/bin/` prefix. The actual file is at **repo root** (`./extract_plan.py`), not under `.deadf/bin/`. Meanwhile `build_verdict.py` is correctly referenced as living in `.deadf/bin/` (it exists at `.deadf/bin/build-verdict.py` — note the **hyphen** vs underscore discrepancy).

**Evidence:**
- `./extract_plan.py` exists (repo root)
- `.deadf/bin/extract_plan.py` does NOT exist
- `.deadf/bin/build-verdict.py` exists (hyphenated filename)
- CLAUDE.md line 56: `build combined verdict with python3 build_verdict.py` (underscore)
- Actual file: `.deadf/bin/build-verdict.py` (hyphen)

**Impact:** Orchestrator would fail to find scripts if using the paths as written.

#### MEDIUM-2: `build_verdict.py` vs `build-verdict.py` naming mismatch
CLAUDE.md references `build_verdict.py` (underscore) but the actual file on disk is `.deadf/bin/build-verdict.py` (hyphen). This is inherited from the old CLAUDE.md (same issue existed there) but should be fixed in the rewrite.

---

## Issues Summary

| # | Severity | Issue | Location | Suggested Fix |
|---|----------|-------|----------|---------------|
| 1 | MEDIUM | `extract_plan.py` referenced without path; file is at repo root not `.deadf/bin/` | Lines 48, 51, 65, 135 | Use `./extract_plan.py` or move to `.deadf/bin/` and reference as `.deadf/bin/extract_plan.py` |
| 2 | MEDIUM | `build_verdict.py` (underscore) vs actual `build-verdict.py` (hyphen) | Lines 56, 135 | Use `.deadf/bin/build-verdict.py` consistently |
| 3 | LOW | Old CLAUDE.md row 1 action was `escalate` (distinct from rows 2-3 `needs_human` pattern); new version merges rows 1+2 as `needs_human` and keeps a separate `escalate` action in invariants. The DECIDE table no longer has an explicit `escalate` row, yet the action invariants section still defines `escalate` as a standalone action. Minor inconsistency. | DECIDE table rows 1-2 vs action invariants | Either add `escalate` as a note under the `needs_human` rows or fold the `escalate` invariant into `needs_human` |
| 4 | LOW | `init.sh` path: new CLAUDE.md references `.deadf/bin/init.sh --project` in seed_docs; old referenced `.pipe/p12-init.sh`. The new path exists and is correct. However, the old also mentioned `.pipe/p1/p1-cron-kick.sh` which is now `.deadf/bin/cron-kick.sh` — this migration is correct but the Quick Reference could be clearer about cron-kick.sh's full path. | seed_docs invariant | Already correct; informational only |

---

## What Was Preserved vs What Changed

### Preserved (comprehensive)
- ALL 15 actions with complete behavioral specifications
- ALL state transition rules
- ALL sentinel parsing rules and 3-tier escalation
- ALL safety constraints
- ALL Task Management integration rules
- ALL notification matrix behavior
- ALL model dispatch rules
- ALL locking and nonce rules
- ALL edge cases (first commit, drift detection, hard stops, QA remediation limits)

### Changed (intentional)
- **Path namespace**: `.pipe/pN/` → `.deadf/templates/` + `.deadf/contracts/` (correct migration)
- **Action names**: `escalate` → `needs_human` (rows 1-2), `verify_task` → `verify.facts` (row 12) — semantic improvements
- **Row numbering**: old 13.5 → new 14, old 14 → new 15 — clean integer sequence
- **Format**: expanded prose sections → dense compressed paragraphs (10:1 compression)
- **Sentinel format examples**: moved to contract files (authoritative source)
- **Safety constraints**: moved to `.claude/rules/safety.md` (auto-loaded)
- **State locking details**: moved to `.claude/rules/state-locking.md` (auto-loaded)

### Format Quality Note
The action invariants are extremely dense — single paragraphs covering what was 50-100 lines in the original. While this works for a model (which can parse dense text), human readability is significantly reduced. This is an acceptable trade-off given the stated goal of compression, and the templates/contracts serve as the authoritative detailed reference.
