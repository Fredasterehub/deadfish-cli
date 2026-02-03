# P2 Implementation Review — Opus QA

**Reviewer:** Claude Opus 4.5 (subagent)
**Date:** 2025-07-21
**Scope:** P2 Brainstorm Session — all prompt templates, runner script, integration wiring
**Canonical spec:** `.pipe/p2-design-unified.md`

---

## VERDICT: NEEDS_FIXES

Two HIGH findings and several MEDIUM issues. Structurally sound implementation — the modular decomposition is clean and matches the spec architecture. But the sub-prompt loading mechanism is broken and the main prompt is missing key behavioral instructions.

---

## Findings

### F01 — HIGH: Sub-prompts unreachable by the model

**Where:** `p2-brainstorm.sh` + `P2_MAIN.md`

**What:** P2_MAIN references sub-prompts by name ("Use P2_A", "Use P2_B", "Use P2_D", etc.) but the runner script only passes `P2_MAIN.md` content as the codex prompt:

```bash
prompt="$(cat "$PROMPT_FILE")"
codex -m gpt-5.2 --cd "$PROJECT_PATH" "$prompt"
```

The model receives zero information about where P2_A through P2_G live on disk, and no instruction to read `.pipe/p2/P2_*.md` files. The sub-prompts are effectively orphaned.

**Why it matters:** The entire modular architecture breaks. The model will wing it for technique selection (P2_A), domain pivots (P2_B), ledger hygiene (P2_C), organization (P2_D), crystallization (P2_E), output format (P2_F), and adversarial review (P2_G). It may produce reasonable output by inference from P2_MAIN's brief phase descriptions, but the detailed protocols (especially the YAML schemas in P2_F and the ledger format in P2_C) will be lost.

**Fix (pick one):**
- **Option A (simple):** Concatenate all sub-prompts into the main prompt at launch:
  ```bash
  prompt="$(cat "$PROMPT_FILE")"
  for f in "$PROJECT_PATH"/.pipe/p2/P2_{A,A2,B,C,D,E,F,G}.md; do
    [[ -f "$f" ]] && prompt+=$'\n\n'"$(cat "$f")"
  done
  ```
- **Option B (lazy-load):** Add explicit paths to P2_MAIN: "When entering Phase 2, read `.pipe/p2/P2_A.md` for the technique selection interface." Repeat for each phase. Relies on codex having file access (it does with `--cd`), but adds latency per phase.
- **Recommendation:** Option A. Context budget is fine — total P2 content is ~3-4K tokens, well within GPT-5.2 limits. Lazy-loading adds fragility.

---

### F02 — HIGH: Prompt passed as CLI argument — may exceed ARG_MAX

**Where:** `p2-brainstorm.sh:75`

**What:** `codex -m gpt-5.2 --cd "$PROJECT_PATH" "$prompt"` passes the entire prompt as a positional argument. If F01 is fixed with Option A (concatenation), the combined prompt is ~4-5KB. Most systems have ARG_MAX ≥ 128KB so this likely works, but it's fragile. More importantly, some shells or codex internals may truncate or choke on multi-KB arguments with embedded newlines and special characters.

**Why it matters:** Silent truncation = broken session. The user would get a partial prompt with no error.

**Fix:** Use a temp file and `--prompt-file` flag (if codex supports it), or pipe via stdin:
```bash
prompt_file=$(mktemp)
trap 'rm -f "$prompt_file"' EXIT
# ... build prompt ...
echo "$prompt" > "$prompt_file"
codex -m gpt-5.2 --cd "$PROJECT_PATH" < "$prompt_file"
```
Check codex CLI docs for the correct stdin/file-based prompt mechanism.

---

### F03 — MEDIUM: Anti-bias interrupt techniques missing from P2_MAIN

**Where:** `P2_MAIN.md`, Phase 3 section

**What:** P2_MAIN says "Run scheduled anti-bias interrupts at ~20/40/60/80 ideas" but does NOT specify WHAT technique to use at each checkpoint. The spec (§2, Phase 3) is explicit:
- ~20 ideas: Force opposites — Reverse Brainstorm
- ~40 ideas: Force analogies — Cross-Pollination / Biomimetic
- ~60 ideas: Force constraints — Constraint Injection
- ~80 ideas: Force black swans — Failure Analysis

**Why it matters:** Without specific instructions, the model may use generic "let's think differently" prompts instead of the structured interrupts designed to break specific cognitive biases at each stage.

**Fix:** Add the four interrupt descriptions to P2_MAIN's Phase 3 section, or create a P2_B2 sub-prompt for anti-bias interrupts (separate from domain pivots in P2_B).

---

### F04 — MEDIUM: Anti-bias behavioral protocols missing

**Where:** `P2_MAIN.md`

**What:** The spec (§7) lists 6 anti-bias protocols that should be active throughout the session:
1. Anti-anchoring (don't lead with suggestions)
2. Anti-premature-convergence (redirect when narrowing)
3. Anti-recency (reference early ideas periodically)
4. Anti-sycophancy (probe weak ideas)
5. Anti-domain-fixation (track + force shifts)
6. Anti-feasibility-bias (include one "impossible" round)

P2_MAIN's "Non-Negotiables" section covers #1 (facilitator not generator), #5 (domain pivots), and partially #2 (stay in generative mode). But #3, #4, and #6 are absent.

**Why it matters:** These are the behavioral guardrails that make the brainstorm quality high. Without anti-sycophancy, the model will praise every idea. Without anti-recency, early ideas get forgotten. Without anti-feasibility-bias, the session stays in "safe" territory.

**Fix:** Add an "Active Protocols" section to P2_MAIN with all 6 behaviors, or fold them into the Non-Negotiables list.

---

### F05 — MEDIUM: No `command -v codex` preflight in runner script

**Where:** `p2-brainstorm.sh`

**What:** The script checks that `$PROJECT_PATH` exists and that `$PROMPT_FILE` exists, but doesn't verify the `codex` CLI is installed before trying to invoke it. Compare with `ralph.sh` which explicitly checks `command -v claude` and `command -v yq`.

**Why it matters:** Without codex, the script fails with an opaque "command not found" error buried in stderr. A preflight check gives a clear, actionable error message.

**Fix:** Add after the `mkdir -p "$SEED_DIR"` line:
```bash
command -v codex &>/dev/null || { echo "codex CLI required but not found" >&2; exit 1; }
```

---

### F06 — LOW: Sub-prompt files not validated in runner

**Where:** `p2-brainstorm.sh`

**What:** Only `P2_MAIN.md` is validated to exist. If any of P2_A through P2_G are missing (e.g., incomplete deployment), the session will proceed with incomplete instructions. This matters more if F01 is fixed with Option A (concatenation), since missing files would silently produce a partial prompt.

**Fix:** Either validate all 9 files exist, or (if using Option A concat) warn but continue for optional sub-prompts.

---

### F07 — LOW: P2_MAIN Phase 3 missing "5-8 exchanges per technique" guidance

**Where:** `P2_MAIN.md`, Phase 3

**What:** Spec says "Spend 5-8 exchanges per technique before rotating." P2_MAIN says "Rotate 3-5 techniques across the session" but doesn't specify how long to spend on each.

**Fix:** Add "Spend 5-8 exchanges per technique before rotating" to Phase 3.

---

### F08 — LOW: P2_E doesn't include BAD/GOOD examples for success truths and non-goals

**Where:** `P2_E.md`

**What:** The spec provides explicit BAD/GOOD examples:
- Success truth BAD: "The tool is easy to use" → GOOD: "A new user completes [core workflow] within 5 minutes without docs"
- Non-goal BAD: "We won't support everything" → GOOD: "We will not support Windows. Linux and macOS only."

P2_E says "Success truths must be testable" and "Non-goals must be specific, not vague" but omits the concrete examples that help the model calibrate.

**Fix:** Add the BAD/GOOD examples from the spec.

---

### F09 — LOW: `set -e` absent from p2-brainstorm.sh

**Where:** `p2-brainstorm.sh:2`

**What:** Script uses `set -uo pipefail` without `-e`. This is actually correct for this script since it manually checks exit codes after `codex`. However, commands between the option parsing and the codex invocation (like `mkdir -p`) could fail silently.

**Fix:** Either add `set -e` and use explicit `|| true` where needed, or add explicit error checks after `cd` and `mkdir -p`. Current behavior is defensible but could be tightened.

---

## What's Good

**Structural fidelity:** The 9-file modular decomposition (P2_MAIN + P2_A through P2_G) matches the spec's sub-prompt architecture table exactly. Each sub-prompt maps to the correct phase.

**P2_F output schemas:** The VISION.md and ROADMAP.md YAML-in-codefence templates are byte-for-byte faithful to the spec. Line limits (≤80 / ≤120) are specified. The overwrite-check for existing files is present.

**P2_A technique selection:** All 4 approach modes present (user-selected, AI-recommended, random, progressive). Default correctly set to AI-recommended.

**P2_A2 technique library:** All 10 categories with all techniques match the spec exactly. No omissions.

**P2_B domain list:** All 12 domains present, matching spec.

**P2_C ledger format:** ID format (I001, I002...), domain tags, novelty annotations, and ledger hygiene rules (persist after 30+, show only deltas) all match spec.

**P2_D organization:** MoSCoW prioritization, 5-12 themes, sequencing rules, risk surfacing, and the optimization question all present.

**P2_G adversarial review:** 5-15 findings, severity labels, "looks good is NOT allowed" enforcement, all 6 review categories present.

**Quick mode:** Present in P2_MAIN with correct skip behavior (Phases 2-4 → Phase 6 → Phase 7).

**Runner script (p2-brainstorm.sh):** Clean arg parsing, correct flag handling (--project, --force, --dry-run), creates .deadf/seed/, validates outputs, writes P2_DONE marker. `bash -n` passes cleanly.

**ralph.sh integration:** P2 dispatch correctly gated on `phase==research && !P2_DONE`. Failure path correctly sets `needs_human` and writes notification with manual recovery command. No state authority violations.

**CLAUDE.md integration:** `seed_docs` action correctly forbids auto-generation, references P2_DONE and .pipe/p2-brainstorm.sh, and handles both the "not done" and "done" states with correct phase transitions.

---

## Summary

| Severity | Count |
|----------|-------|
| CRITICAL | 0 |
| HIGH     | 2 |
| MEDIUM   | 3 |
| LOW      | 4 |

## Recommendation

Fix F01 and F02 before first use — without them, the sub-prompts are unreachable and the runner may fail on edge cases. F03 and F04 should be addressed to preserve brainstorm quality. The LOW items are polish.

**Estimated fix effort:** ~30 minutes for all findings. F01 is the most important — a 5-line change to concatenate sub-prompts into the main prompt.

---

*Review complete. p2-review-opus.md written 2025-07-21.*
