# P7 Implementation Review — Opus 4.5

**Reviewer:** Claude Opus 4.5 (subagent)
**Date:** 2026-02-02
**Commit:** 7d855e1 (feat(p6): add generate_task spec + P6_GENERATE_TASK.md prompt template)
**Verdict:** NEEDS_FIXES

---

## File 1: `.pipe/p7/P7_IMPLEMENT_TASK.md` (Main Deliverable)

### Structure Assessment

The template has these sections:
1. IDENTITY (untitled, first 2 lines)
2. TASK PACKET (header + placeholder)
3. DIRECTIVES (7 imperative lines)
4. GUARDRAILS (9 numbered items)
5. DONE CONTRACT (2 lines)

**This matches the required 5-section structure: IDENTITY → TASK PACKET → DIRECTIVES → GUARDRAILS → DONE CONTRACT. ✅**

### Design Decision Compliance

| Design Decision | Status | Notes |
|---|---|---|
| 5-section structure | ✅ | IDENTITY → TASK PACKET → DIRECTIVES → GUARDRAILS → DONE CONTRACT |
| No planning preamble | ✅ | "do not output an upfront plan or explanations" |
| TASK packet injected verbatim | ✅ | `{TASK_PACKET_CONTENT}` placeholder |
| Batch file reads first (FILES_TO_LOAD) | ✅ | Directive 1: "Read ALL files in FILES_TO_LOAD first (batch them in one pass)" |
| 3-iteration test/lint fix cap | ✅ | "max 3 fix cycles" in directives |
| "Commit best-passing state" fallback | ✅ | In DONE CONTRACT |
| Fixed model_reasoning_effort="high" | ✅ | Not in template (correct — dispatch-time param in CLAUDE.md) |
| Git-as-IPC (no stdout parsing) | ✅ | Template has no output format requirement |
| Stateless (retry via TASK packet) | ✅ | "If RETRY CONTEXT is present, address it first" |
| Scope escape valve (TODO comment) | ✅ | Guardrail 999999999 |

### Finding 1 — MEDIUM: Guardrail numbering starts at 999, not 99999

P6_GENERATE_TASK.md uses 99999, 999999, 9999999 (5+ digits). P7 starts at 999 (3 digits). Pipeline convention should be consistent.

**Severity: MEDIUM**

### Finding 2 — MEDIUM: Diff cap references `ESTIMATED_DIFF × 3` inline instead of `max_diff`

The TASK packet format (from CLAUDE.md generate_task) includes a precomputed `max_diff: <3 × ESTIMATED_DIFF>` field. P7's DIRECTIVES say "keep total diff ≤ ESTIMATED_DIFF × 3" — computing inline rather than referencing the precomputed `max_diff`. This couples P7 to the 3× magic number.

**Severity: MEDIUM**

### Finding 3 — LOW: Section headers are bare words vs P6's `--- SECTION ---` style

P7 uses `IDENTITY`, `DIRECTIVES`, `GUARDRAILS` etc. P6 uses `--- ORIENTATION (0a-0c) ---`. Different styles for different models (Codex vs GPT-5.2) — acceptable.

**Severity: LOW**

---

## File 2: `CLAUDE.md` — implement_task action spec

### Assessment

The implement_task action spec was rewritten to:
1. List inputs (STATE.yaml, TASK packet, P7 template) ✅
2. Describe assembly (inject TASK packet, bind TASK_ID/TITLE) ✅
3. Note 5-section structure ✅
4. Fixed reasoning_effort = `high` always ✅
5. codex exec dispatch ✅
6. Git-as-IPC result reading ✅
7. Success/failure handling ✅

### Finding 4 — HIGH: Over-escaped quotes in `codex exec` command

**In implement_task spec:**
```bash
codex exec -m gpt-5.2-codex -c \"model_reasoning_effort=\\\"high\\\"\" --approval-mode full-auto \"<implementation prompt>\"
```

**In Model Dispatch Reference (same file, bottom):**
```bash
codex exec -m gpt-5.2-codex -c 'model_reasoning_effort="high"' --approval-mode full-auto "<implementation prompt>"
```

These are inconsistent within the same file. The over-escaped version appears designed for embedding inside another quoted context but is presented as a standalone reference command. The clean version in the Model Dispatch Reference is correct.

**Severity: HIGH** — Confusing and would break if copy-pasted.

### Finding 5 — LOW: generate_task also rewritten (scope creep)

The generate_task section was completely rewritten to the P6-referencing spec (happy path / drift path / retry path / hard stops / TASK packet format). This is correct and needed but was not scoped as part of "P7 implementation."

**Severity: LOW** — Changes are correct; just noting scope expansion.

### Finding 6 — Bonus: `plan_base_commit` added to `create_plan` STATE updates

A small addition of `track.plan_base_commit: <git rev-parse HEAD>` to the create_plan action's STATE update list. This is needed by the generate_task drift detection logic. Correct and good.

**Severity: N/A** — Correct improvement.

---

## File 3: `.pipe/p2-codex-prompt.md` — Consistency check

### Finding 7 — VERIFIED: Matches CLAUDE.md

The implement_task section in p2-codex-prompt.md was updated identically to CLAUDE.md's version. All fields, steps, and structure match.

**Consistency: ✅**

### Finding 8 — HIGH: Same over-escaped command syntax

Same issue as Finding 4 — the over-escaped `codex exec` command is replicated here.

**Severity: HIGH** (same fix needed in both files)

---

## Cross-Reference: Plans vs. Deliverable

| Feature | plan-conductor | plan-gsd | plan-gpt52 | P7 Template | Verdict |
|---|---|---|---|---|---|
| 5-section structure | ✅ (A-E) | ✅ (0-3+done) | ✅ (1-5) | ✅ | PASS |
| No planning preamble | ✅ | ✅ | ✅ | ✅ | PASS |
| TASK packet verbatim | ✅ | ✅ | ✅ | ✅ | PASS |
| Batch file reads | ✅ | ✅ | ✅ | ✅ | PASS |
| 3 fix iterations | ✅ | ✅ | ✅ | ✅ | PASS |
| Best-passing fallback | ✅ | ✅ | ✅ | ✅ | PASS |
| high only (no xhigh) | ⚠️ plan has xhigh | ✅ | ✅ | ✅ | PASS (Fred override) |
| Git-as-IPC | ✅ | ✅ | ✅ | ✅ | PASS |
| Stateless retry | ✅ | ✅ | ✅ | ✅ | PASS |
| Scope escape valve | ✅ | ✅ | ✅ | ✅ | PASS |

**Note:** plan-conductor.md has a reasoning effort escalation table (high → xhigh on 3rd attempt). Fred's directive overrides this. The implementation correctly uses fixed `high` only.

---

## Findings Summary

| # | File | Severity | Description |
|---|---|---|---|
| 1 | P7_IMPLEMENT_TASK.md | MEDIUM | Guardrail numbering starts at 999 vs P6's 99999 convention |
| 2 | P7_IMPLEMENT_TASK.md | MEDIUM | `ESTIMATED_DIFF × 3` inline vs referencing `max_diff` precomputed field |
| 3 | P7_IMPLEMENT_TASK.md | LOW | Bare-word section headers vs P6's `--- SECTION ---` style |
| 4 | CLAUDE.md | HIGH | Over-escaped quotes in codex exec command; inconsistent with Model Dispatch Reference |
| 5 | CLAUDE.md | LOW | generate_task also rewritten (correct but scope creep) |
| 8 | p2-codex-prompt.md | HIGH | Same over-escaped command syntax as CLAUDE.md |

---

## Verdict: NEEDS_FIXES

### Required Fix (blocking)

**Fix 1: Clean up escaped quotes in `codex exec` command**
- **Files:** `CLAUDE.md` (implement_task action spec, line ~370), `.pipe/p2-codex-prompt.md` (implement_task section)
- **Current:**
  ```bash
  codex exec -m gpt-5.2-codex -c \"model_reasoning_effort=\\\"high\\\"\" --approval-mode full-auto \"<implementation prompt>\"
  ```
- **Fix to:**
  ```bash
  codex exec -m gpt-5.2-codex -c 'model_reasoning_effort="high"' --approval-mode full-auto "<implementation prompt>"
  ```
- **Why:** Over-escaping is confusing, inconsistent with the Model Dispatch Reference in the same file, and would break if used directly in a shell.

### Recommended Fixes (non-blocking)

**Fix 2: Normalize guardrail numbering**
- **File:** `.pipe/p7/P7_IMPLEMENT_TASK.md`
- Change 999→99999, 9999→999999, 99999→9999999, etc. to match P6 convention.

**Fix 3: Reference max_diff instead of computing inline**
- **File:** `.pipe/p7/P7_IMPLEMENT_TASK.md`
- Change "keep total diff ≤ ESTIMATED_DIFF × 3" to "keep total diff ≤ max_diff"

---

## Quality Assessment

**Score: 8/10**

The P7 template is well-crafted, lean (~250 static tokens), and faithfully implements all design decisions. The CLAUDE.md updates are thorough with correct input/output contracts and git-as-IPC patterns. The only blocking issue is a cosmetic escaping bug in the codex exec command reference. Everything else is style consistency polish.
