# P9.5 Reflect — Synthesis Design

## Where Both Plans Agree (Locked)
- Hybrid cadence: reflect runs per-task (state always), doc updates conditional on significance
- **Execution order: Part B (docs) BEFORE Part A (state advance)** — so last_good.commit includes any docs commit
- Part A (state advance) = mechanical, no LLM, already in CLAUDE.md
- Part B (living docs) = conditional LLM call, non-fatal (pipeline continues if it fails)
- **Who edits/commits: LLM emits EDITS only; orchestrator applies edits + commits deterministically** (sentinel is structured instruction, not direct file access)
- Track-end = forced flush of all accumulated observations regardless of significance
- Compression protocol: merge → prune stale → tighten prose → evict least-relevant
- 7 living docs: TECH_STACK.md, PATTERNS.md, PITFALLS.md, RISKS.md, PRODUCT.md, WORKFLOW.md, GLOSSARY.md

## Opus Contributions (Adopted)
1. **Three-level gate: NOP / BUFFER / UPDATE** — avoids binary update-or-not
2. **Scratch buffer** (`.deadf/docs/.scratch.yaml`) — accumulates minor observations, flushes at track-end or when ≥3 items accumulate
3. **Structured EDITS in sentinel output** — action=append|replace|remove with doc/section/content keys
4. **Smart loading** — not all 7 docs needed every reflect (typically just TECH_STACK + PATTERNS + PITFALLS)
5. **Detailed prompt template** with IDENTITY/CONTEXT/RULES/CRITERIA/BUDGET/OUTPUT sections

## GPT-5.2 Contributions (Adopted)
1. **Concrete deterministic trigger rules** for significance:
   - Manifest/lockfile changed → SIGNIFICANT
   - diff_lines >= 120 → evaluate for SIGNIFICANT
   - New CLI command / script / CI config → SIGNIFICANT
   - ≥1 retry before passing → check for gotcha → likely SIGNIFICANT
   - ≥3 items in scratch buffer → auto-flush as UPDATE
2. **Track-completion super-pass** — reconcile, deduplicate, compact all docs
3. **Per-doc budget allocation** (explicit numbers, not just "~700 each")
4. **Clear responsibility model** — LLM emits structured EDITS, orchestrator applies + commits deterministically

## Per-Doc Token Budgets (varied caps, enforced by char count ÷ 4)

| Doc | Max Tokens | Max Chars (~) | Typical | Content Strategy |
|-----|-----------|---------------|---------|------------------|
| TECH_STACK.md | 800 | 3200 | 400-600 | Stack table + commands + deps list |
| PATTERNS.md | 800 | 3200 | 400-700 | Bullet list by category (code, testing, naming) |
| PITFALLS.md | 700 | 2800 | 200-500 | One-line gotchas, bullet list |
| RISKS.md | 500 | 2000 | 100-300 | Severity-tagged bullet list |
| PRODUCT.md | 700 | 2800 | 300-500 | Short paragraphs: what, features, recent changes |
| WORKFLOW.md | 700 | 2800 | 200-400 | CI commands, deploy process, preferences |
| GLOSSARY.md | 500 | 2000 | 100-300 | Term: definition pairs |
| **TOTAL** | **4700** | **18800** | **1800-3200** | **300 token buffer below 5000** |

**Enforcement:** Orchestrator uses `wc -c <file> | awk '{print int($1/4)}'` as approximate token count. This is deterministic and reproducible. If a doc exceeds its max after edits, orchestrator applies compression before committing.

## Significance Decision Tree

```
Task completed + verified (P8+P9 PASS)
         │
         ├── Last task in track? (task_current == task_total)
         │        YES → ALWAYS flush buffer + evaluate → UPDATE or FLUSH
         │        NO  ↓
         │
         ├── Manifest/lockfile changed?
         │        YES → SIGNIFICANT → UPDATE
         │
         ├── diff_lines >= 120?
         │        YES → Evaluate for new patterns/deps → likely SIGNIFICANT
         │
         ├── New CLI/script/CI config added?
         │        YES → SIGNIFICANT → UPDATE
         │
         ├── Task required ≥1 retry before passing?
         │        YES → Gotcha discovered → SIGNIFICANT (update PITFALLS)
         │
         ├── Scratch buffer has ≥3 pending observations?
         │        YES → Batch flush → UPDATE
         │
         ├── New pattern/dep/gotcha found but minor?
         │        YES → BUFFER (save to .scratch.yaml)
         │
         └── None of the above → NOP
```

## Merged Prompt Template

```
IDENTITY
You are the reflect agent for the deadf(ish) pipeline.
Your job: evaluate a completed task for lessons and decide if living docs need updates.
You are precise and economical. No fluff. No restating the obvious.
Do not modify source code. Docs only.

COMPLETED TASK CONTEXT
Task: {task_id} — {task_title}
Track: {track_id} — {track_name} (task {task_current} of {task_total})
Summary: {task_summary}
Retries before pass: {retry_count}

Changed files:
{git_diff_stat}

Key diff patterns:
{abbreviated_diff_hunks}

Verify results:
{verify_json_excerpt}

Previous observations (scratch buffer):
{scratch_buffer_content}

CURRENT LIVING DOCS
{living_docs_content}

EVALUATION RULES
1. Scan the completed task for NEW information not already in living docs:
   - New dependency or tool? → TECH_STACK.md
   - New code pattern, naming convention, testing approach? → PATTERNS.md
   - Gotcha, workaround, or tech debt introduced? → PITFALLS.md
   - Systemic risk discovered? → RISKS.md
   - Feature behavior changed or clarified? → PRODUCT.md
   - Process/CI/deploy change? → WORKFLOW.md
   - New domain term? → GLOSSARY.md

2. If NO new information: output ACTION=NOP.

3. If new but MINOR (single small pattern, trivial detail):
   - Output ACTION=BUFFER with the observation.

4. If SIGNIFICANT (new dep, architectural pattern, costly gotcha, risk):
   - Output ACTION=UPDATE with specific edits.
   - Also flush any pending scratch buffer items.

5. If LAST TASK in track (task_current == task_total):
   - ALWAYS flush scratch buffer + evaluate current task.
   - Output ACTION=UPDATE or ACTION=FLUSH.

SIGNIFICANCE CRITERIA
These triggers indicate you SHOULD EVALUATE for doc updates (significance candidates).
However: UPDATE requires at least one concrete, new, non-trivial doc entry not already present.
A trigger alone is NOT sufficient — you must identify a specific addition/change to make.

Triggers (if ANY is true, evaluate carefully):
- Manifest/lockfile/dependency file changed in diff
- diff_lines >= 120
- New CLI command, script, or CI config added
- Task required ≥1 retry (retry_count > 0) — gotcha likely discovered
- Scratch buffer has ≥3 pending observations
- Changed files outside planned FILES list (scope drift)
- New architectural pattern that future tasks should follow
- Breaking change, migration requirement, or security behavior change

Even with triggers present: if you cannot identify a concrete new doc entry → NOP or BUFFER.
Do not create "docs theater" — empty or trivial updates just because a trigger fired.

An observation is MINOR if:
- Reinforces existing documented pattern
- Trivial internal naming choice unlikely to recur
- Single-use workaround

TOKEN BUDGET (STRICT)
- Each doc MUST stay under its max (see budget table in CLAUDE.md)
- When a doc exceeds 80% capacity: COMPRESS before adding
- Compression: merge similar → prune stale → tighten prose → evict least-relevant
- If compression insufficient: include TOKEN_PRESSURE=doc_name in output
- NEVER exceed budget. Trim least-relevant entries if forced.

OUTPUT FORMAT (exactly one block, no prose outside)

For NOP:
<<<REFLECT:V1:NONCE={nonce}>>>
ACTION=NOP
REASON="No new patterns or information discovered."
<<<END_REFLECT:NONCE={nonce}>>>

For BUFFER:
<<<REFLECT:V1:NONCE={nonce}>>>
ACTION=BUFFER
OBSERVATIONS:
- doc=PATTERNS.md entry="Prefer named exports for CLI command modules"
- doc=PITFALLS.md entry="jest.mock must precede import in ESM mode"
REASON="Minor observations buffered for track-end flush."
<<<END_REFLECT:NONCE={nonce}>>>

For UPDATE:
<<<REFLECT:V1:NONCE={nonce}>>>
ACTION=UPDATE
EDITS:
- doc=TECH_STACK.md action=append section="Dependencies" content="zod@3.22 — runtime schema validation"
- doc=PATTERNS.md action=append section="Testing" content="Use jest.mock() before import for ESM modules"
- doc=PITFALLS.md action=replace section="Known Issues" old="Placeholder" content="ESM mock hoisting requires top-of-file calls"
BUFFER_FLUSH:
- doc=PATTERNS.md entry="Prefer named exports for CLI command modules"
REASON="New dependency (zod) and ESM testing pattern discovered."
<<<END_REFLECT:NONCE={nonce}>>>

For FLUSH (track-end, buffer only, no new findings):
<<<REFLECT:V1:NONCE={nonce}>>>
ACTION=FLUSH
EDITS:
- doc=PATTERNS.md action=append section="Conventions" content="Prefer named exports for CLI command modules"
- doc=PITFALLS.md action=append section="Known Issues" content="jest.mock must precede import in ESM mode"
REASON="Track complete. Flushing 2 buffered observations."
<<<END_REFLECT:NONCE={nonce}>>>

GRAMMAR RULES (strict — for deterministic parsing):
- Exactly one opener line: <<<REFLECT:V1:NONCE={nonce}>>>
- Exactly one closer line: <<<END_REFLECT:NONCE={nonce}>>>
- Nonce format: ^[0-9A-F]{6}$ (6-char uppercase hex)
- No blank lines inside the block.
- No tabs — spaces only.
- No prose outside the block.

Required/optional sections per ACTION:
  NOP:    ACTION (required), REASON (required). No OBSERVATIONS, EDITS, or BUFFER_FLUSH.
  BUFFER: ACTION (required), OBSERVATIONS (required, ≥1 item), REASON (required). No EDITS.
  UPDATE: ACTION (required), EDITS (required, ≥1 item), BUFFER_FLUSH (optional), REASON (required).
  FLUSH:  ACTION (required), EDITS (required, ≥1 item from buffer), REASON (required). No OBSERVATIONS.

Key=value rules:
  ACTION — unquoted, exactly one of: NOP|BUFFER|UPDATE|FLUSH
  REASON — quoted string, single line, ≤500 chars, no internal double quotes

List item rules:
  OBSERVATIONS items: "- doc=<filename> entry=<quoted string>"
  EDITS items: "- doc=<filename> action=append|replace|remove section=<quoted string> content=<quoted string>"
  For replace/remove: add old=<quoted string> (substring to find)
  Each content/entry value ≤100 tokens
  Use single quotes or backticks inside quoted values — no double quotes
  BUFFER_FLUSH items: "- doc=<filename> entry=<quoted string>"
```

## Integration with CLAUDE.md

### Execution Order (Part B runs BEFORE Part A)

**Part B: Living Docs Evaluation (new, optional, non-fatal)**
1. IF living docs exist (.deadf/docs/*.md):
   a. Read scratch buffer (.deadf/docs/.scratch.yaml)
   b. Determine if last task in track
   c. Smart-load relevant docs (always: TECH_STACK + PATTERNS + PITFALLS; conditional: others)
   d. Assemble P9.5 prompt with evidence bundle
   e. Dispatch to GPT-5.2 (lightweight call)
   f. Parse REFLECT sentinel block
   g. Orchestrator executes action:
      - NOP: no-op, proceed
      - BUFFER: append observations to .deadf/docs/.scratch.yaml
      - UPDATE: orchestrator applies EDITS to living docs, flushes buffer entries, commits docs
      - FLUSH: orchestrator applies buffer to living docs, commits docs
   h. Validate token budgets post-update (char-count ÷ 4)
   i. If parse fails or LLM errors: log warning, skip Part B entirely (non-fatal)

**Part A: State Advance (existing, mechanical, always runs)**
2. Update last_good.commit (NOW includes any docs commit from Part B), last_good.task_id, last_good.timestamp
3. Advance to next task or track
4. Reset counters

**Key invariant:** Part B before Part A ensures last_good.commit points to the correct HEAD (including any docs commit). If Part B fails, Part A still runs with the implementation commit as HEAD.

### Scratch Buffer Format (.deadf/docs/.scratch.yaml)
```yaml
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

## Implementation Scope (3 files for Codex)
1. **CREATE .pipe/p9.5/P9_5_REFLECT.md** — prompt template from above
2. **UPDATE CLAUDE.md** — add Part B to reflect action, add doc budget table, reference P9.5 template
3. **UPDATE .pipe/p2-codex-prompt.md** — consistency mirror

Note: Scratch buffer management and REFLECT sentinel parser are orchestrator-side logic, not prompt template concerns. They'll be implemented when the pipeline integration happens.

## Edge Cases
- **No living docs yet** (greenfield before P12): Part B skips entirely
- **Empty diff**: NOP, Part A still runs
- **Doc at token limit**: compress before adding, TOKEN_PRESSURE flag if insufficient
- **Scratch buffer overflow** (≥3 items): auto-flush as UPDATE
- **Single-task track**: track-end flush triggers immediately on first task
- **Reflect LLM fails**: non-fatal, Part A already committed, docs slightly staler
- **Conflicting observations**: LLM resolves during flush (most recent wins, replace old entry)
