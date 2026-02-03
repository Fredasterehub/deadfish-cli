# P9.5 Reflect — Design Plan

> Research-backed design for the deadf(ish) reflect step.
> Synthesizes Conductor, GSD, and Lobster approaches with deadfish constraints.

---

## 1. Per-Task vs Per-Track vs Hybrid — Recommendation

### Evidence Matrix

| Approach | Conductor | GSD | Lobster v1.1 | Pros | Cons |
|----------|-----------|-----|-------------|------|------|
| **Per-track** | ✅ Primary. Updates context docs on track completion. `conductor:implement` synchronizes project context files after all tasks in a track finish. | ✅ Primary. Full PROJECT.md evolution review at milestone boundaries (which map to our tracks). | ✅ "Update PATTERNS.md/PITFALLS.md if needed" in reflect step, but reflect runs per-task. | Reduces churn. Batches changes. Ensures docs reflect coherent feature state. | Docs stale during long tracks. Next task in same track misses patterns. |
| **Per-task** | ❌ Not used. Tasks update plan.md status only, not context docs. | ❌ Not used at task level. Tests record results; docs update at milestone. | ⚠️ Implied but vague. | Freshest possible context. Catches patterns immediately. | Noise from trivial tasks. Token churn. 2-task track = 2 doc rewrites for one feature. |
| **Hybrid** | Implicit — plan.md updated per-task (status), context docs per-track. | Explicit — SUMMARY.md per-plan (≈per-task), full review per-milestone. | Suggested but unspecified. | Best of both: state always current, docs updated only when meaningful. | Slightly more complex logic. |

### Recommendation: **Hybrid with Significance Gate**

**State management runs EVERY task** (already in CLAUDE.md):
- Advance `task_current`, update `last_good.*`, reset counters

**Living docs update is CONDITIONAL**, evaluated every task but only triggered when significant:
- Significance gate prevents churn from trivial tasks
- Accumulates observations in a lightweight scratch buffer
- Flushes to living docs when threshold met OR track completes

**Rationale:**
1. Conductor's per-track model works because Conductor tracks are short (spec → plan → implement is one flow). Our tracks have 2-5 tasks, meaning a per-track-only approach delays useful patterns by 1-4 tasks.
2. GSD's milestone-level updates are too coarse for our pipeline — our "milestones" (roadmap phases) can span many tracks.
3. The hybrid matches GSD's SUMMARY.md pattern: capture observations per-task (cheap), synthesize per-milestone (expensive). We capture per-task to a scratch buffer, flush when meaningful.

---

## 2. Template Structure

### Two-Part Reflect

**Part A: State Advance (always, mechanical, no LLM)**
Already defined in CLAUDE.md's `reflect` action. No changes needed.

**Part B: Living Docs Evaluation (conditional, lightweight LLM call)**
Only runs when Part A completes. Uses GPT-5.2 (or Claude directly) to evaluate whether docs need updating.

### P9.5 Prompt Template

```
IDENTITY
You are the reflect agent for the deadf(ish) pipeline.
Your job: extract lessons from a completed task and decide if living docs need updates.
You are precise and economical. No fluff. No restating the obvious.

COMPLETED TASK CONTEXT
Task: {TASK_ID} — {TASK_TITLE}
Track: {TRACK_ID} — {TRACK_NAME} (task {TASK_CURRENT} of {TASK_TOTAL})
Summary: {TASK_SUMMARY}

Changed files:
{GIT_DIFF_STAT}

Key diff patterns (abbreviated):
{ABBREVIATED_DIFF_HUNKS}

Verify results:
{VERIFY_JSON_EXCERPT}

Previous observations (scratch buffer, may be empty):
{SCRATCH_BUFFER_CONTENT}

CURRENT LIVING DOCS (injected)
{LIVING_DOCS_CONTENT}

EVALUATION RULES
1. Scan the completed task for NEW information not already in living docs:
   - New dependency or tool? → TECH_STACK.md
   - New code pattern, naming convention, or testing approach? → PATTERNS.md
   - Gotcha, workaround, or tech debt introduced? → PITFALLS.md
   - New systemic risk discovered? → RISKS.md
   - Feature behavior changed or clarified? → PRODUCT.md
   - Process/CI/deploy change? → WORKFLOW.md
   - New domain term used? → GLOSSARY.md

2. If NO new information: output REFLECT_NOP (no updates needed).

3. If new information exists but is MINOR (single small pattern, trivial dep):
   - Add to scratch buffer only (will be flushed on track completion or accumulation).
   - Output REFLECT_BUFFER with the observation.

4. If new information is SIGNIFICANT (new architectural pattern, major dep,
   breaking gotcha, risk):
   - Output REFLECT_UPDATE with specific edits.
   - Also flush any pending scratch buffer items.

5. If this is the LAST TASK in the track (task_current == task_total):
   - ALWAYS flush scratch buffer to living docs (even if current task is NOP).
   - Output REFLECT_UPDATE (or REFLECT_FLUSH if only buffer items).

SIGNIFICANCE CRITERIA
An observation is SIGNIFICANT if any of:
- Introduces a dependency not in TECH_STACK.md
- Establishes a pattern that future tasks should follow
- Documents a gotcha that cost ≥1 retry or would surprise a developer
- Identifies a risk that could affect multiple tracks
- Changes how the project is built, tested, or deployed

An observation is MINOR if:
- Reinforces an existing pattern (already documented)
- Trivial internal naming choice
- Single-use workaround unlikely to recur

TOKEN BUDGET RULES
- Each living doc MUST stay under 700 tokens (7 docs × 700 = 4900 < 5000 combined)
- When a doc approaches 600 tokens: COMPRESS existing content before adding
- Compression strategy: merge similar entries, remove stale items, tighten prose
- If compression insufficient: flag in output as TOKEN_PRESSURE for orchestrator
- NEVER exceed 700 tokens per doc. Trim least-relevant entries if forced.

OUTPUT FORMAT
Exactly one of these blocks:

<<<REFLECT:V1:NONCE={nonce}>>>
ACTION=NOP
REASON="No new patterns or information discovered."
<<<END_REFLECT:NONCE={nonce}>>>

<<<REFLECT:V1:NONCE={nonce}>>>
ACTION=BUFFER
OBSERVATIONS:
- doc=PATTERNS.md entry="Prefer named exports for CLI command modules"
- doc=PITFALLS.md entry="jest.mock must be called before import in ESM mode"
<<<END_REFLECT:NONCE={nonce}>>>

<<<REFLECT:V1:NONCE={nonce}>>>
ACTION=UPDATE
EDITS:
- doc=TECH_STACK.md action=append section="Dependencies" content="zod@3.22 — runtime schema validation for CLI input"
- doc=PATTERNS.md action=append section="Testing" content="Use `jest.mock()` before `import` for ESM modules; see src/auth/__tests__/ for pattern"
- doc=PITFALLS.md action=replace section="Known Issues" old="Placeholder" content="ESM mock hoisting requires top-of-file jest.mock calls; CJS pattern does not work"
BUFFER_FLUSH:
- doc=PATTERNS.md entry="Prefer named exports for CLI command modules"
REASON="New dependency (zod) and ESM testing pattern discovered during auth implementation."
<<<END_REFLECT:NONCE={nonce}>>>

Rules:
- One block only. No prose outside the block.
- EDITS use action=append|replace|remove.
- For replace: include `old` key with text to find (substring match).
- For remove: include `old` key with text to remove.
- Each `content` value must be ≤100 tokens.
- BUFFER_FLUSH includes accumulated minor observations being promoted.
```

---

## 3. Significance Threshold Criteria

### Decision Tree

```
Task completed + verified
         │
         ├── Is this the LAST task in the track?
         │        YES → ALWAYS flush buffer + evaluate current task → UPDATE or FLUSH
         │        NO  ↓
         │
         ├── Does the task introduce a new dependency?
         │        YES → SIGNIFICANT → UPDATE
         │
         ├── Did the task require ≥1 retry before passing?
         │        YES → Check if failure reveals a gotcha → likely SIGNIFICANT
         │
         ├── Does the diff touch ≥3 files not in the original plan?
         │        YES → Possible architectural shift → SIGNIFICANT
         │
         ├── Does the task establish a pattern first used in this project?
         │        YES → SIGNIFICANT (future tasks should follow)
         │
         ├── Does the scratch buffer have ≥3 pending observations?
         │        YES → Flush buffer as batch → UPDATE
         │
         └── None of the above → MINOR or NOP
                   │
                   ├── Any new information at all? → BUFFER
                   └── No new information → NOP
```

### Comparison with Conductor

Conductor has NO significance threshold — it updates context docs after every track completes (unconditionally). This works because:
1. Conductor tracks are human-supervised (the human reviews the sync)
2. Conductor's context is loaded per-session (not per-cycle with token budgets)
3. Conductor doesn't have our 5000-token constraint

Our significance gate is necessary because:
1. We run autonomously (no human reviewing doc updates)
2. Every token in living docs is loaded every cycle
3. Noise in docs degrades planning quality

### Comparison with GSD

GSD records success patterns at milestone level via full PROJECT.md evolution review (complete-milestone workflow). This is comprehensive but expensive — GSD's review touches every section of PROJECT.md including requirements, decisions, and context.

Our approach is lighter: targeted doc updates, not a full review. We borrow GSD's "accumulate then synthesize" pattern but at a finer granularity.

---

## 4. Which Docs Get Updated and When

### Update Frequency Matrix

| Doc | Per-Task Triggers | Track-End Triggers | Typical Frequency |
|-----|-------------------|-------------------|-------------------|
| **TECH_STACK.md** | New dep added, build command changed | Always reviewed | Rare (1-2 per track) |
| **PATTERNS.md** | New code pattern established | Buffer flush | Moderate (1-3 per track) |
| **PITFALLS.md** | Retry caused by gotcha, workaround used | Buffer flush | Moderate (0-2 per track) |
| **RISKS.md** | Systemic risk discovered | Always reviewed | Rare (0-1 per track) |
| **PRODUCT.md** | Feature behavior differs from spec | Track summary | Rare (0-1 per track) |
| **WORKFLOW.md** | CI/deploy/process change | Only if changed | Very rare |
| **GLOSSARY.md** | New domain term appears in code | Buffer flush | Rare |

### Smart Loading (from WORKFLOW.md)

Not all docs need to be loaded for reflect. The reflect prompt needs:
- **Always:** TECH_STACK.md, PATTERNS.md, PITFALLS.md (most frequently updated)
- **If retry occurred:** PITFALLS.md, RISKS.md
- **If feature task:** PRODUCT.md
- **Track-end only:** All 7 docs

This reduces reflect's input token cost from ~5000 to ~2100 for typical tasks.

---

## 5. Token Budget Management

### Per-Doc Token Budgets

| Doc | Max Tokens | Typical | Content Strategy |
|-----|-----------|---------|------------------|
| TECH_STACK.md | 800 | 400-600 | Structured: stack table + commands list + deps list |
| PATTERNS.md | 800 | 400-700 | Bullet list grouped by category (code, testing, naming) |
| PITFALLS.md | 700 | 200-500 | Bullet list with one-line gotchas |
| RISKS.md | 500 | 100-300 | Bullet list, severity-tagged |
| PRODUCT.md | 700 | 300-500 | Short paragraphs: what it is, key features, recent changes |
| WORKFLOW.md | 700 | 200-400 | Structured: CI commands, deploy process, preferences |
| GLOSSARY.md | 500 | 100-300 | Term: definition pairs |
| **TOTAL** | **4700** | **1800-3200** | **Buffer of 300 tokens below 5000 limit** |

### Compression Protocol

When a doc exceeds 80% of its budget (token_pressure threshold):

1. **Merge similar entries:** "Use async/await for DB calls" + "Use async/await for API calls" → "Use async/await for all I/O (DB, API, file)"
2. **Remove stale entries:** If a pattern was superseded by a later one, remove the old
3. **Tighten prose:** "When writing tests, always make sure to use" → "Tests must use"
4. **Graduated eviction:** Remove least-referenced entries first (entries not cited in recent tasks)

### Token Counting

The orchestrator (Claude Code) counts tokens before injecting docs into prompts:
```bash
# Approximate: 1 token ≈ 4 chars for English text
wc -c .deadf/docs/PATTERNS.md | awk '{print int($1/4)}'
```

If any doc exceeds budget after a REFLECT_UPDATE, the orchestrator:
1. Logs a warning
2. Applies compression heuristics
3. If still over: truncates from the bottom (oldest entries)

---

## 6. Integration with Current Reflect Step

### Current CLAUDE.md Reflect (unchanged — Part A)

```yaml
# Existing behavior (mechanical, no LLM)
1. Update last_good.commit, last_good.task_id, last_good.timestamp
2. Advance to next task or track
3. Reset counters
```

### New Addition (Part B — after Part A succeeds)

```yaml
# New behavior (conditional LLM call)
4. IF living docs exist (.deadf/docs/*.md):
   a. Read scratch buffer (.deadf/docs/.scratch.yaml)
   b. Determine if this is last task in track
   c. Assemble reflect prompt (P9.5 template)
   d. Dispatch to GPT-5.2 (or Claude directly — lightweight call)
   e. Parse REFLECT sentinel block
   f. Execute action:
      - NOP: no-op, proceed
      - BUFFER: append to .deadf/docs/.scratch.yaml
      - UPDATE: apply edits to living docs, clear relevant scratch entries
      - FLUSH: apply buffer to living docs (track-end)
   g. Verify token budgets post-update
5. Proceed with state advance (already done in Part A)
```

### File Layout

```
.deadf/
├── docs/
│   ├── TECH_STACK.md
│   ├── PATTERNS.md
│   ├── PITFALLS.md
│   ├── RISKS.md
│   ├── PRODUCT.md
│   ├── WORKFLOW.md
│   ├── GLOSSARY.md
│   └── .scratch.yaml    # Buffer for minor observations
├── tracks/
│   └── {track_id}/
│       ├── SPEC.md
│       ├── PLAN.md
│       └── tasks/
└── ...
```

### Scratch Buffer Format

```yaml
# .deadf/docs/.scratch.yaml
observations:
  - task: auth-01-02
    doc: PATTERNS.md
    entry: "Prefer named exports for CLI command modules"
    timestamp: "2026-02-01T15:30:00Z"
  - task: auth-01-02
    doc: PITFALLS.md
    entry: "jest.mock must precede import in ESM"
    timestamp: "2026-02-01T15:30:00Z"
```

---

## 7. Edge Cases

### Empty Diff (task produced no code changes)
- Can happen if task was documentation-only or config-only
- Reflect Part A still runs (advance state)
- Part B: likely NOP (no code patterns to extract)
- Skip diff injection in prompt; include note "No code changes in this task"

### No New Patterns (common case)
- REFLECT_NOP is the expected default for most tasks
- This is fine — most tasks implement known patterns
- The scratch buffer accumulates gradually; no pressure to find novelty

### Doc Approaching Token Limit
- Reflect prompt includes current doc content → LLM can see it's near limit
- TOKEN_BUDGET_RULES in prompt explicitly instruct compression
- Orchestrator validates post-update; if still over, applies mechanical compression
- Worst case: orchestrator truncates oldest entries and logs warning

### Scratch Buffer Overflow
- Buffer has no hard limit but is evaluated every task
- If buffer reaches ≥3 observations → auto-flush as SIGNIFICANT
- Prevents unbounded accumulation

### Track With Single Task
- `task_current == task_total` on first (and only) task
- Track-end flush triggers immediately
- No buffer accumulation possible — directly evaluate for UPDATE

### Reflect LLM Call Fails (parse error, timeout)
- Part A (state advance) already completed — task is committed
- Part B failure is NON-FATAL: log warning, skip doc update
- Living docs slightly staler but pipeline continues
- This matches the "degrade gracefully" philosophy from P12

### Living Docs Don't Exist Yet
- For greenfield projects before P12 runs
- Part B skips entirely (no docs to update)
- Part A runs normally

### Conflicting Observations
- Buffer says "Use pattern X"; new task contradicts with "Use pattern Y"
- LLM resolves during FLUSH: replaces old entry with new (most recent wins)
- The prompt sees both the buffer and current docs, can reconcile

---

## 8. Comparison with Conductor and GSD

### Feature Comparison

| Feature | Conductor | GSD | deadf(ish) P9.5 |
|---------|-----------|-----|-----------------|
| **Update timing** | Per-track (on `/conductor:implement` completion) | Per-milestone (complete-milestone workflow) | Hybrid: per-task evaluation, conditional update |
| **Significance gate** | None (always updates on track completion) | None (always does full review at milestone) | Yes: NOP/BUFFER/UPDATE trichotomy |
| **What gets updated** | product.md, tech-stack.md, workflow.md, product-guidelines.md | PROJECT.md (monolithic: requirements, decisions, context, core value) | 7 focused docs (TECH_STACK, PATTERNS, PITFALLS, RISKS, PRODUCT, WORKFLOW, GLOSSARY) |
| **Token awareness** | None (human-supervised, context window managed by session) | None (milestone review is a standalone workflow, context window fresh) | Core constraint: 5000 combined tokens, per-doc budgets, compression protocol |
| **Scratch buffer** | None | Phase SUMMARY.md serves similar purpose (accumulates per-phase) | Explicit .scratch.yaml with structured observations |
| **Human involvement** | Required (review plan, verify phases) | Required (UAT, milestone confirmation) | None (fully autonomous) |
| **Failure mode** | Human fixes doc issues | Human reviews at milestone | Graceful degradation: skip Part B, continue pipeline |

### What We Borrow

| From | Pattern | Adaptation |
|------|---------|------------|
| **Conductor** | Context docs as first-class artifacts alongside code | Living docs in `.deadf/docs/`, loaded per-cycle |
| **Conductor** | Per-track sync point for context refresh | Track-end forced flush of scratch buffer |
| **Conductor** | Plan.md status updates per-task, context per-track | State per-task (Part A), docs conditional (Part B) |
| **GSD** | SUMMARY.md as intermediate accumulation layer | .scratch.yaml buffer for minor observations |
| **GSD** | Full evolution review at milestone boundaries | Not adopted — too expensive for autonomous pipeline |
| **GSD** | Severity-based issue tracking | Significance criteria for deciding UPDATE vs BUFFER |
| **Lobster v1.1** | "Update PATTERNS.md/PITFALLS.md if needed" | Formalized with sentinel-based LLM output and structured edits |

### What We Don't Borrow

| Pattern | Why Not |
|---------|---------|
| Conductor's unconditional sync | No human review = need quality gate |
| GSD's full PROJECT.md evolution | Too token-expensive for per-task/per-track frequency |
| GSD's UAT verification loop | Our verify.sh + P9 handles this |
| Conductor's human phase verification | We're fully autonomous |

---

## 9. Implementation Priority

1. **Sentinel parser for REFLECT blocks** — extend extract_plan.py or new script
2. **Scratch buffer YAML management** — read/write/flush .scratch.yaml
3. **P9.5 prompt template** — finalize from Section 2 above
4. **CLAUDE.md reflect action update** — add Part B conditional logic
5. **Token budget checker** — simple char-count validation post-update
6. **Integration test** — verify NOP/BUFFER/UPDATE paths

### Estimated Effort
- Prompt template: 1 task (P9.5 prompt file)
- Sentinel parser extension: 1 task
- CLAUDE.md update: 1 task
- Scratch buffer logic: 1 task
- Token budget management: bundled with CLAUDE.md update
- **Total: 4 tasks** (one track)

---

*Design: 2026-02-02. Based on Conductor v0.2.0, GSD complete-milestone + verify-work workflows, Lobster v1.1, and FINAL_ARCHITECTURE v2.4.2.* 🐟
