# P9.5 Reflect — Research & Design Plan (GPT‑5.2)

P9.5 runs **after** P8+P9 verification PASS and before the next task/track. Today, `reflect` in `CLAUDE.md` mostly advances state and resets counters. This design upgrades `reflect` into a **Conductor‑inspired living-docs sync** step while avoiding doc churn and staying under the **<5000 tokens combined** living-doc budget.

## 1) Per‑task vs per‑track vs hybrid — recommendation (with evidence)

### What the references actually do

- **Conductor:** updates project context docs **after the track is complete**, i.e. once the track is `[x]`. It is explicitly “SYNCHRONIZE PROJECT DOCUMENTATION” after completion, and the protocol is **conditional on significance** (e.g. “determine if significant changes in tech stack are detected”) and then **commits** doc sync work. (See Conductor `implement.toml` section 4.0 + README “Project context files (Synchronized on completion)”.)
- **Lobster (v1.1):** has `reflect` **per task** (triggered when verify passed) and explicitly updates `PATTERNS.md/PITFALLS.md if needed`, then advances state.
- **deadf(ish) v2.4.2:** already models `reflect` as a **per-task sub-step** (generate→implement→verify→reflect), and delays `last_good.*` until after `reflect` completes.

### Tradeoffs in our pipeline context

**Per‑task reflect (doc updates every task)**
- Pros: freshest context; next task generation gets immediate learning; better drift control during long tracks; aligns with deadf(ish) “one cycle = one sub-step”.
- Cons: noisy churn for small diffs; harder to keep docs compact; can “thrash” style/pattern docs on tiny changes.

**Per‑track reflect (doc updates only when track completes)**
- Pros: less churn; better holistic synthesis; closer to Conductor; easier to keep docs consistent.
- Cons: context may lag; planner/implementer repeatedly rediscover the same pitfalls inside the track; drift can accumulate until end-of-track.

### Recommendation: **Hybrid cadence**

1. **Reflect ALWAYS runs per-task** (because state advancement, baseline update, counters reset must always happen).
2. **Doc updates are conditional per-task** (significance‑gated) to keep docs fresh without churn.
3. **A stronger “track sync” mode runs at track completion** (still inside the final task’s reflect cycle) to reconcile/compact docs and enforce token budgets.

This matches:
- deadf(ish) state model (per-task reflect is already a sub-step),
- Lobster’s per-task learning loop,
- Conductor’s per-track doc synchronization (we replicate it as “track-completion reflect escalation”).

## 2) Reflect prompt template — structure

P9.5 should look like other deadf(ish) prompts: **identity → inputs → directives → guardrails → output**. It is a **doc-sync agent**, not a code implementer and not a verifier.

### Template skeleton (high-level)

**IDENTITY**
- You are GPT‑5.2 running the `reflect` sub-step.
- Your job: (a) decide if living docs need updates, (b) apply minimal updates if needed, (c) keep combined doc size < 5000 tokens, (d) report a structured summary.

**INPUTS (injected by orchestrator)**
- `STATE.yaml` excerpt (task/track ids, current counters, nonce)
- “Evidence bundle” from verify PASS:
  - verify.sh JSON excerpt (especially `diff_lines`, `test_count`, `git_clean`, `paths_ok`, `secrets_found`)
  - `git show --stat` for the implementation commit (and optionally key diff hunks)
  - task metadata: `task.id`, title, summary, acceptance criteria IDs
- Current living docs (if present): `TECH_STACK.md`, `PATTERNS.md`, `PITFALLS.md`, `RISKS.md`, `PRODUCT.md`, `WORKFLOW.md`, `GLOSSARY.md`

**DIRECTIVES**
1. Compute `significance` (low/medium/high) and which docs are impacted.
2. If no doc updates needed: do not edit docs; do not commit.
3. If updates needed:
   - edit only the impacted docs (minimal diff),
   - keep doc schemas stable (prefer compact YAML blocks),
   - ensure combined tokens < 5000 (compress/prune if needed),
   - commit doc changes as a single commit.
4. Never modify source code; docs only.

**OUTPUT**
- A single sentinel summary block for the orchestrator to log into STATE.

### Proposed sentinel output (V1)

```
<<<REFLECT:V1:NONCE={nonce}>>>
SIGNIFICANCE=low|medium|high
DOC_UPDATES=YES|NO
UPDATED_DOCS=TECH_STACK.md,PATTERNS.md
COMMIT_CREATED=YES|NO
COMMIT_SHA=abcdef1|NONE
NOTES="One short paragraph: what changed and why."
<<<END_REFLECT:NONCE={nonce}>>>
```

Notes:
- The reflect agent should **actually perform the edits + commit**; the sentinel is for logging and deterministic parsing (no JSON).
- If docs are missing, reflect may create them using the canonical format (see §5).

## 3) What triggers doc updates (significance threshold)

### Significance levels (deterministic heuristic)

**High (always update docs)**
- New/changed dependencies or runtime requirements (manifest/lockfile changes).
- New build/test/lint commands, CI changes, new external service integration, secrets/env var additions (names only).
- Security/auth behavior change, data model change, breaking change, migration requirement.

**Medium (update docs if it teaches something reusable)**
- New cross-cutting pattern introduced (error handling, logging strategy, testing convention, CLI UX convention).
- New pitfall discovered and fixed (flake, platform issue, nondeterminism, encoding, path issues).
- New domain term introduced in code/docs that will recur.

**Low (usually skip doc edits)**
- Tiny diffs (e.g., `diff_lines` below a small threshold) without new patterns/pitfalls/deps.
- Cosmetic changes, comment-only changes, rename-only changes with no behavior change.

### Concrete trigger rules (simple, explainable)

Doc updates trigger if **any** is true:
- `verify.diff_lines >= 120` (tunable) **OR**
- any dependency manifest/lockfile changed **OR**
- any new CLI command / script / CI config changed **OR**
- reflect can point to at least **one** new item for PATTERNS/PITFALLS/RISKS/WORKFLOW/GLOSSARY that is:
  - specific (not generic advice),
  - likely to recur,
  - grounded in the just-merged change.

Otherwise: `DOC_UPDATES=NO`.

## 4) Which docs get updated and when

### Per-task (conditional)

- `TECH_STACK.md`: only when deps/tools/build commands/external services change.
- `PATTERNS.md`: only when a reusable convention was introduced (naming, testing, module layout, error handling, CLI UX).
- `PITFALLS.md`: only when a new gotcha was discovered (or an old one was resolved and should be demoted/removed).
- `RISKS.md`: only for systemic risk changes (security, data integrity, scalability, brittleness).
- `PRODUCT.md`: only when user-facing behavior or scope changes.
- `WORKFLOW.md`: only when dev workflow changes (commands, CI, review gates, verify expectations).
- `GLOSSARY.md`: only when a new term/abbrev shows up and is likely to recur.

### Track completion (strong sync mode)

When reflect detects “this was the last task in the track” (from `STATE.yaml`), run an additional consolidation pass:
- Deduplicate/merge overlapping items across docs.
- Enforce per-doc budgets (see §5).
- Remove stale/contradicted guidance.
- Ensure `WORKFLOW.md` smart-load map remains correct (if we maintain one).

## 5) Token budget management (<5000 combined)

### Budget allocation (default; tunable)

- `TECH_STACK.md` ≤ ~600 tokens
- `PATTERNS.md` ≤ ~900 tokens
- `PITFALLS.md` ≤ ~600 tokens
- `RISKS.md` ≤ ~450 tokens
- `PRODUCT.md` ≤ ~700 tokens
- `WORKFLOW.md` ≤ ~700 tokens
- `GLOSSARY.md` ≤ ~350 tokens

Total target: ~4300 tokens, leaving headroom.

### Compression strategy (in order)

1. **No prose drift:** prefer compact bullet lists or compact YAML blocks; avoid narrative paragraphs.
2. **Deduplicate:** merge items that say the same thing.
3. **Keep “now” not “history”:** store stable current guidance; avoid task-by-task logs in living docs.
4. **Prune weakest items:** drop low-specificity or one-off items first.
5. **Collapse examples:** keep at most one short example per recurring pattern.
6. **Track-sync compaction:** do aggressive pruning only at track completion to avoid oscillation.

## 6) Integration with current `reflect` step in `CLAUDE.md`

`CLAUDE.md` already defines reflect responsibilities (advance state, reset counters, update `last_good.*`). P9.5 should be inserted as the “Update documentation if needed” clause:

Proposed reflect execution order:
1. Run P9.5 reflect agent (GPT‑5.2) with evidence bundle + current living docs.
2. If the agent created a docs commit:
   - ensure repo is clean after commit,
   - set `last_good.commit` to the new HEAD (docs commit).
3. Advance `task_current` / mark track complete / set next phase, exactly as today.
4. Reset `task.retry_count`, `loop.stuck_count`, `task.replan_attempted` as today.

Key invariant: `last_good.*` updates only after reflect completes; reflect may legitimately advance HEAD by creating a docs commit.

## 7) Edge cases

- **Empty diff / no-op task:** `DOC_UPDATES=NO`, `COMMIT_CREATED=NO`. Reflect still advances state.
- **No new patterns:** skip updates even if medium diff; avoid “docs theater”.
- **Docs missing:** create minimal skeleton docs (only the relevant ones) with stable schema and budget tags.
- **Docs at/over budget:** do compaction (merge/prune) and prefer track-completion compaction over per-task churn.
- **Conflicting guidance discovered:** update the doc to reflect the new truth; remove the old item instead of adding a contradictory one.

## 8) Comparison: Conductor vs GSD vs deadf(ish) P9.5

**Conductor**
- Doc sync is **per-track** and explicitly gated on significance + user confirmation (for sensitive docs).
- It makes doc sync a first-class step and ensures changes are **committed**.

**GSD**
- Uses “plans are prompts” and relies on periodic consolidation/archiving to keep planning docs bounded.
- Emphasizes context-budget discipline and aggressive pruning when docs become large.

**deadf(ish) P9.5 (this design)**
- Keeps deadf(ish) per-task state machine intact.
- Adopts Conductor’s “sync on completion” as a **track-completion super-pass**, while still allowing **significance-gated per-task freshness**.
- Explicitly enforces the <5000 token cap via per-doc budgets + compaction rules.

