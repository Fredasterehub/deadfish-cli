# P9.5 Reflect — Synthesis Review (GPT‑5.2)

## Overall Verdict: NEEDS_CHANGES

The synthesis captures the broad hybrid cadence + scratch-buffer idea well, but it contains a few contract-level contradictions (ordering, responsibility for edits/commits, and token-budget definitions) that will cause ambiguous or incorrect orchestrator behavior unless fixed.

---

## Section Findings

### Where Both Plans Agree (Locked) — HIGH
- **Issue:** “Part A (state advance) … already in CLAUDE.md — unchanged” is fine, but the synthesis later places “Part B (docs)” **after** Part A. In the current contract, documentation update is step 1 of `reflect` and **must happen before** updating `last_good.*` and advancing state (so `last_good.commit` can include any docs commit). See `CLAUDE.md` `reflect` ordering.
- **Fix:** Treat “docs evaluation/update” as **part of reflect step 1** and run it **before** baselines/state advance. If docs update creates a commit, `last_good.commit` must be updated to that new HEAD.

### Opus Contributions (Adopted) — MEDIUM
- **Good:** NOP/BUFFER/UPDATE plus scratch buffer and structured EDITS are the right shape.
- **Issue:** The “three-level gate” is presented, but synthesis also introduces **ACTION=FLUSH**, making it effectively a 4-action protocol. That’s OK, but it needs explicit semantics so implementers don’t special-case inconsistently.
- **Fix:** Define FLUSH precisely: “track-end and **no new current-task findings**; apply buffer only”. Also clarify UPDATE-at-track-end: “apply buffer + current task edits”.

### GPT‑5.2 Contributions (Adopted) — HIGH
- **Issue (dropped/changed):** My plan intentionally made large diffs/retries **forcing evaluation**, not **forcing UPDATE**. In the synthesis, the “deterministic triggers — if ANY is true, treat as SIGNIFICANT” set includes `diff_lines >= 120` and `retry_count > 0`, which will over-trigger doc churn (“docs theater”).
- **Fix:** Change “SIGNIFICANT triggers” to “SIGNIFICANCE CANDIDATES” and add a hard rule: **UPDATE requires at least one concrete, non-trivial doc entry not already present**; otherwise ACTION=NOP (or BUFFER if minor-but-new).
- **Issue (contradiction):** “Reflect agent performs edits + commits” conflicts with the later “orchestrator executes action … apply edits … commit docs”.
- **Fix:** Choose one model and make it consistent:
  1) **LLM-only emits EDITS; orchestrator applies + commits** (recommended for deterministic IO), or
  2) **Reflect sub-agent edits files + commits**, and sentinel is only logging.
  If (1), remove “reflect agent commits” language. If (2), update the contract to allow/require that behavior and include commit SHA in the sentinel.

### Per-Doc Token Budgets — CRITICAL
- **Issue:** The synthesis says “~700 tokens per doc” in “Locked”, but later sets maxima like 800 and totals 4700. That’s internally inconsistent and will cause “budget enforcement” disputes.
- **Issue:** “Validate token budgets … (mechanical char-count)” is not a token budget; char count will drift and can violate the <5000 combined-token invariant.
- **Fix:** Decide and state one canonical budgeting scheme:
  - Either **700 per doc hard cap** (simple) or **per-doc varied caps** (fine, but then remove the “~700” claim).
  - Define the enforcement metric: either true tokenization (preferred; via a deterministic tokenizer available to the orchestrator) or rename to “char budget” if you really mean chars.

### Significance Decision Tree — MEDIUM
- **Good:** The overall flow is correct and includes track-end flush + scratch threshold.
- **Issue (dropped Opus trigger):** Opus included “diff touches ≥3 files not in original plan → possible architectural shift”. This is useful when `diff_lines` is low but scope drift is high.
- **Fix:** Re-add this trigger (or an equivalent “scope drift” heuristic) if the orchestrator can cheaply compute “planned vs changed files”.

### Merged Prompt Template — HIGH
- **Parseability:** The block is close to the pipeline DSL style, but it is not strict enough yet for a future `build_reflect.py`-style parser.
- **Fix:** Add explicit syntax constraints similar to `build_verdict.py` / `P9_VERIFY_CRITERION.md`:
  - Sentinel lines are **line-anchored**; exactly one opener and one closer; nonce must match `^[0-9A-F]{6}$`.
  - For each ACTION, specify **required/optional sections** (e.g., BUFFER must have OBSERVATIONS; UPDATE must have EDITS; NOP must not include OBSERVATIONS/EDITS).
  - For key/value lines: require `KEY=VALUE` with a fixed allowed key set; define quoting rules (e.g., REASON must be quoted; ACTION unquoted).
  - For list items: define exact grammar (no tabs; no blank lines; `- ` prefix; allowed fields).
  - Remove ambiguous guidance like “Do not use double quotes inside content values” unless you also formalize quoting/escaping rules for `content=...`.

### Integration with CLAUDE.md — CRITICAL
- **Issue:** “Part B — after Part A” conflicts with the current reflect spec ordering (`reflect` step 1 is doc update; baselines after). This also risks updating `last_good.commit` to the wrong commit if docs were committed later.
- **Fix:** Update the integration section to: doc evaluation/update (including scratch buffer IO and any commit) → then baselines/state advance/resets.
- **Issue:** The synthesis says “Part A unchanged” but also claims “already in CLAUDE.md — no LLM”. That’s true today, but once Part B exists, reflect is no longer purely mechanical.
- **Fix:** Wording: “Part A remains mechanical; Part B is new and optional”.

### Scratch Buffer Format (.scratch.yaml) — LOW
- **Good:** Minimal YAML structure is fine.
- **Suggested hardening:** Add an explicit `id` (stable hash of doc+entry) to support dedupe, and specify ordering (append-only) + eviction rules when flushing.

### Implementation Scope / Edge Cases — MEDIUM
- **Good:** Non-fatal behavior on reflect failure is consistent with keeping the pipeline moving.
- **Issue:** If reflect fails after Part A but before docs update (as currently described), docs updates can be skipped while state advances, compounding stale docs. This is another reason to fix the ordering description.
- **Fix:** Clarify that reflect failure affects only Part B; Part A still runs and commits state, but only after any intended docs commit decision point is passed (or explicitly skipped).

---

## Exact Changes Requested (to reach APPROVED)
1. **Fix reflect ordering**: docs eval/update + any docs commit must occur before updating `last_good.*` and advancing `task_current`/track status.
2. **Choose one “who edits/commits” model** and remove contradictory statements; update sentinel fields accordingly (include `COMMIT_SHA` only if the reflect agent itself commits).
3. **Make budgets internally consistent** (700-per-doc vs varied caps) and define a deterministic enforcement metric (true tokens vs chars).
4. **Refine significance triggers** so `diff_lines >= 120` / `retry_count > 0` do not force UPDATE unless there is at least one concrete, new, non-trivial doc entry.
5. **Formalize the REFLECT block grammar** (required keys/sections per ACTION, quoting rules, list-item grammar, no-tabs/no-blank-lines policy) to be safely parseable like existing sentinels.
6. (Optional but recommended) Re-add Opus “scope drift” trigger (changed files not in plan) if feasible.

