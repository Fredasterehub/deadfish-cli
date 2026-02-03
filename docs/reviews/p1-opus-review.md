# P1 Implementation QA Review (Opus 4.5)

> Reviewer: Claude Opus 4.5 (subagent)
> Date: 2026-02-02T12:30Z
> Files reviewed: P1_CYCLE_KICK.md, p1-cron-kick.sh, CLAUDE.md, PROMPT_OPTIMIZATION.md
> Reference: synthesis-opus-orchestrator.md (approved synthesis v2)

## Verdict: MINOR_FIXES

---

## Findings

### F1 — BUG: awk reserved keyword `in` causes syntax error [MEDIUM]

**File:** `p1-cron-kick.sh` (template extraction awk command)
**Line:** `kick_template=$(awk 'BEGIN{in=0} /^```text[[:space:]]*$/ {in=1; next} /^```/ {if(in){exit}} in{print}' "$TEMPLATE_FILE")`

`in` is a reserved keyword in POSIX awk (used in `for (x in array)` construct). This causes a hard syntax error on gawk, mawk, and POSIX awk:

```
awk: line 1: syntax error at or near in
```

**Verified:** Tested on the host. Confirmed crash with exit code 2. The template extraction will always fail, meaning **no kick message will ever be constructed**. This is a blocker for runtime.

**Fix:** Replace `in` with any non-reserved variable name (e.g., `f`, `found`, `p`):
```bash
kick_template=$(awk 'BEGIN{f=0} /^```text[[:space:]]*$/ {f=1; next} /^```/ {if(f){exit}} f{print}' "$TEMPLATE_FILE")
```

Tested — works correctly.

---

### F2 — MINOR: Missing `Skill: deadfish` line from approved synthesis

**File:** `P1_CYCLE_KICK.md` (kick message text block)
**Reference:** synthesis-opus-orchestrator.md, "Final P1 Template" section

The approved synthesis includes `Skill: deadfish` in the kick message. The implemented template omits it. This line was part of the ~135 token budget and is referenced in the synthesis token breakdown (15 tokens for "Skill + reply contract").

The `Skill:` line activates CLAUDE.md skill context loading. Without it, the orchestrator relies solely on the `DEADF_CYCLE` sentinel for skill identification, which works but is less explicit.

**Impact:** Low — CLAUDE.md contract is triggered by the `DEADF_CYCLE` sentinel regardless. But the synthesis approved it, so it should either be included or explicitly documented as a deliberate omission.

**Fix:** Add `Skill: deadfish` line before the `Reply:` block in the kick message, or document the omission rationale.

---

### F3 — COSMETIC: Template wording diverges from synthesis (non-functional)

**File:** `P1_CYCLE_KICK.md`

| Synthesis | Template | Impact |
|-----------|----------|--------|
| `1. cd {PROJECT_PATH} — if fails, print CYCLE_FAIL and exit` | `1) cd {PROJECT_PATH} or print CYCLE_FAIL and exit` | None |
| `→` arrows | `->` arrows | None |
| `—` em-dashes | `--` double dashes | None |
| `Contract: CLAUDE.md (binding)` | (not in synthesis) | Positive — adds clarity |

These are cosmetic. The template's `Contract: CLAUDE.md (binding)` addition is a net improvement over the synthesis. No action needed.

---

## Check Results

### ✅ Check 1: P1_CYCLE_KICK.md

| Criterion | Result | Notes |
|-----------|--------|-------|
| Uses `DEADF_CYCLE` (not `DEADFISH_CYCLE`) | ✅ PASS | Line 1 of kick: `DEADF_CYCLE {CYCLE_ID}` |
| State hint with advisory caveat | ✅ PASS | `(advisory -- STATE.yaml is authoritative; ignore hint if it conflicts)` |
| BOOTSTRAP section | ✅ PASS | 3 steps: cd, require files, acquire flock |
| EXECUTE section | ✅ PASS | Points to CLAUDE.md iteration contract |
| ~135 token budget | ✅ PASS | Compact; consistent with synthesis budget table |

### ⚠️ Check 2: p1-cron-kick.sh

| Criterion | Result | Notes |
|-----------|--------|-------|
| Bash syntax valid | ❌ FAIL | F1: awk `in` keyword causes runtime crash |
| Uses `.deadf/cron.lock` | ✅ PASS | `lock_file="$DEADF_DIR/cron.lock"` with `flock -n 9` |
| Stale recovery | ✅ PASS | Checks `cycle_status == running` + `P1_CYCLE_TIMEOUT_S` (default 600s), repairs to `timed_out`/`needs_human` under `STATE.yaml.flock` |
| Quick-exit checks with structured log | ✅ PASS | needs_human→11, complete→12, cycle_running→13, stale→14; all emit JSON log |
| State hint extraction | ✅ PASS | Full extraction: status, phase, sub_step, iteration, task_id, retry_count, max_retries |
| Cycle ID generation | ✅ PASS | `cycle-{iteration+1}-{8hex}` via `/dev/urandom` |
| Log rotation | ✅ PASS | `P1_MAX_LOGS` (default 50), find+sort+rm pattern |

### ✅ Check 3: CLAUDE.md

| Criterion | Result | Notes |
|-----------|--------|-------|
| `DEADF_CYCLE` documented | ✅ PASS | Identity section, Cycle Protocol, Cycle Kick section all use `DEADF_CYCLE` |
| Dual-lock model | ✅ PASS | "Cycle Kick / Launcher" section: process lock (`.deadf/cron.lock`) + state lock (`STATE.yaml.flock`) |
| Early-exit contract | ✅ PASS | "If the orchestrator is invoked, it MUST end with exactly one of: CYCLE_OK \| CYCLE_FAIL \| DONE"; launcher emits structured `skip` log line |

### ✅ Check 4: PROMPT_OPTIMIZATION.md

| Criterion | Result | Notes |
|-----------|--------|-------|
| P1 marked implemented | ✅ PASS | Inventory entry: `Status: ✅ Implemented`; Phase 2 table: `✅ Implemented` |

### ✅ Check 5: Consistency

| Cross-reference | Result | Notes |
|-----------------|--------|-------|
| Sentinel name across all files | ✅ PASS | `DEADF_CYCLE` everywhere |
| Dual-lock: template ↔ launcher ↔ CLAUDE.md | ✅ PASS | Template: flock on STATE.yaml.flock; Launcher: .deadf/cron.lock; CLAUDE.md: documents both |
| State hint format: template ↔ launcher | ✅ PASS | Both use `{cycle.status} {phase}:{sub_step} #{iteration} task={task_id} retry={retry_count}/{max_retries}` |
| Exit codes: launcher ↔ CLAUDE.md | ✅ PASS | Launcher has structured exits (10-14, 20-21); CLAUDE.md documents early-exit contract |
| Reply tokens: template ↔ CLAUDE.md | ✅ PASS | Both: `CYCLE_OK | CYCLE_FAIL | DONE` |
| Lock file descriptor: launcher state write ↔ CLAUDE.md pattern | ✅ PASS | Launcher uses FD 8 on `STATE.yaml.flock` for stale recovery; matches CLAUDE.md's documented pattern |

---

## Summary

Implementation is solid and faithful to the approved synthesis. The architecture (dual-lock, structured exits, state hint extraction, log rotation) is well-designed and consistent across all three files.

**One blocker (F1):** The awk reserved keyword bug prevents the launcher from ever constructing a kick message. This is a one-character fix (`in` → `f`) but must be applied before any runtime use.

**One minor (F2):** Missing `Skill: deadfish` line from synthesis — low impact, should be reconciled.

After fixing F1, this is ready for integration testing.
