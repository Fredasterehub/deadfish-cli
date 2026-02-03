# P10 Implementation Prompt for GPT-5.2-Codex

You are **GPT-5.2-Codex**. Your job is to implement **P10 format-repair contract updates** exactly as specified below.

Work in: `/tank/dump/DEV/deadfish-cli`.

## Scope (Hard-Bounded)

You MUST change **exactly 3 files**:
1. Create: `.pipe/p10/P10_FORMAT_REPAIR.md`
2. Update: `CLAUDE.md` (format-repair policy + per-block trigger table; reference the P10 template)
3. Update: `.pipe/p2-codex-prompt.md` (mirror the same format-repair policy changes for consistency)

Do **NOT** modify any other files (including `extract_plan.py` and `build_verdict.py`).

## Inputs You MUST Read (in this repo)

Read these files before editing:
- `.pipe/p10/synthesis-opus-orchestrator.md` (approved design; follow exactly)
- `.pipe/p9/P9_VERIFY_CRITERION.md` (style reference)
- `.pipe/p9.5/P9_5_REFLECT.md` (style reference + REFLECT grammar context)
- `extract_plan.py` (PLAN parser error format + constraints; do not change)
- `build_verdict.py` (VERDICT parser error format + constraints; do not change)
- `CLAUDE.md` (current contract to update)
- `.pipe/p2-codex-prompt.md` (must mirror CLAUDE changes)

## Goal

P10 standardizes **one universal format-repair prompt** for sentinel blocks, and formalizes when/if the orchestrator retries after parsing/validation failures.

P10 is **format repair only**:
- Do not change meaning.
- Do not add “improvements”.
- Only make the smallest edits needed to satisfy the sentinel grammar/contract.

## Non-Negotiables (Locked from Approved P10 Synthesis)

- One universal repair template: `.pipe/p10/P10_FORMAT_REPAIR.md`
- One retry maximum per failing block (no infinite loops)
- Same nonce, same model as the original failed output
- Repair prompt must include: verbatim parser error + verbatim original output + authoritative format contract
- Repair output must be **block-only**: output ONLY the corrected sentinel block; no prose; no code fences
- Not a semantic improvement pass — preserve content/meaning
- Track P10 attempts separately from `task.retry_count` (policy + metrics/logging; do not change state schema here)
- Empty-output guard: if original output is `< 50 chars`, skip P10 and follow per-block failure policy
- Large original output handling: head+tail truncation to an 8K total cap (first 4K + last 4K with `"[...truncated...]"`)
- Unicode quote guard: require ASCII `"` only (convert curly quotes)
- Parser traceback guard: if the “parser error” contains a Python traceback/crash, do **not** invoke P10 (tooling bug) → follow per-block failure policy

---

# Deliverable 1 — Create `.pipe/p10/P10_FORMAT_REPAIR.md` (Universal Template)

Create the file using the same template style as `.pipe/p9/P9_VERIFY_CRITERION.md` and `.pipe/p9.5/P9_5_REFLECT.md` (plain-text sections, strict rules, placeholder-driven).

The file MUST be a universal template that can be used for multiple block types. It MUST:
- Take the block type as `{BLOCK_TYPE}`.
- Take the cycle nonce as `{NONCE}`.
- Take `{CRITERION_ID}` only when repairing VERDICT blocks.
- Take `{PARSER_ERROR}` as verbatim (often `ParseError: ...` and/or `line N: ...`).
- Optionally include a one-line `{MICRO_HINT}` (when empty, it must be omitted entirely; orchestrator responsibility, but template must support it cleanly).
- Include `{ORIGINAL_OUTPUT}` verbatim (may be truncated).
- Include `{FORMAT_CONTRACT}` as the authoritative contract for that block type.
- Include a “COMMON FIXES” cookbook mapping frequent error strings to actions (per synthesis).
- Include a “REPAIR CHECKLIST” (per synthesis) and explicitly include:
  - Exactly one opener and one closer line
  - Nonce usage must match `{NONCE}` (both opener and closer)
  - ASCII quotes only; no internal `"` inside quoted fields; no escapes
  - No tabs; spaces only
  - No backslashes at all
  - For planner/path fields: no absolute paths and no `..` traversal
- Require the model to output ONLY the corrected sentinel block (no prose, no code fences).

## `.pipe/p10/P10_FORMAT_REPAIR.md` content (verbatim except placeholders)

IDENTITY
You are a format-repair agent. You do not change meaning. You only fix sentinel formatting.

TASK
Your previous output could not be parsed.
Produce ONE corrected {BLOCK_TYPE} block that satisfies the format contract below.
Make the smallest edits needed. Preserve original meaning and content.

HARD CONSTRAINTS
- Output ONLY the corrected sentinel block. No prose. No code fences.
- Use NONCE: {NONCE}
- Block type: {BLOCK_TYPE}
- Criterion ID (if VERDICT): {CRITERION_ID}
- One block only — exactly one opener line and one closer line.

PARSER ERROR (verbatim)
{PARSER_ERROR}

{MICRO_HINT}

ORIGINAL OUTPUT (verbatim, may be truncated)
{ORIGINAL_OUTPUT}

FORMAT CONTRACT (authoritative — your output MUST match this exactly)
{FORMAT_CONTRACT}

COMMON FIXES
- "found 0 blocks" or "found 2 blocks" or "expected exactly 1" → ensure exactly one opener + closer pair, and no text outside
- "opener must appear before closer" → reorder so opener line comes first, closer line comes last
- "nonce mismatch" → use {NONCE} in both opener and closer lines
- "criterion mismatch" → ensure opener/closer criterion id equals {CRITERION_ID} (VERDICT only)
- "ANSWER must be YES or NO" → ANSWER must be unquoted, exactly YES or NO
- "ANSWER must be unquoted" → remove quotes around ANSWER
- "REASON must be quoted" → REASON must be double-quoted with ASCII " and be single-line
- "REASON cannot be empty" → provide a short non-empty reason consistent with original content
- "REASON exceeds 500 chars" → shorten to ≤500 chars without changing meaning
- "REASON must be single-line" → remove newlines from REASON
- "unknown field" / "unknown key" → remove any key not in the format contract
- "duplicate field" → keep only one instance; preserve original meaning
- "missing required field" → add it using content from the original output
- "tab character" → replace tabs with spaces
- Code fences (```) wrapping the block → remove all code fences
- Curly quotes / unicode quotes → convert to ASCII " only

REPAIR CHECKLIST (verify before outputting)
1. Exactly one opener line and one closer line; opener appears first.
2. Opener/closer text matches the contract exactly (block name/version/ids/nonce).
3. No text outside the block.
4. All required keys present; no unknown keys.
5. Quoting matches contract (quoted fields use ASCII " only; no internal "). Do not escape quotes. Use single quotes or backticks inside quoted strings.
6. No tabs — spaces only.
7. Respect any per-field length limits stated in the format contract or reported by the parser error.
8. Avoid backslashes entirely.
9. For planner blocks: no absolute paths and no `..` traversal in path fields.

OUTPUT
Output ONLY the corrected sentinel block.

---

# Deliverable 2 — Update `CLAUDE.md` (Format-Repair Policy, P10 Reference, Trigger Table)

Update `CLAUDE.md` to formalize the P10 format-repair policy and to reference `.pipe/p10/P10_FORMAT_REPAIR.md` as the canonical repair template.

## Required contract changes in `CLAUDE.md`

1. Replace/upgrade existing “Format-Repair Retry” language so it is **P10-driven**, not ad-hoc.
2. Add the **per-block trigger table** (policy) with the exact semantics from the P10 synthesis:
   - One retry max
   - Same nonce + same model
   - Skip on `<50 chars` original output
   - Skip on Python traceback/tool crash
   - Head+tail truncate original output to 8K cap
   - Output must be block-only (no prose, no code fences)
3. Ensure policy is explicit about **after P10 failure** behavior per block type:
   - Planner/PLAN parse failure after P10 retry → `CYCLE_FAIL`
   - VERDICT per-criterion parse/validation failure after P10 retry → that criterion `NEEDS_HUMAN` (no further retries)
   - REFLECT parse/validation failure after P10 retry → non-fatal degrade (ACTION=NOP) + log warning (do not fail the cycle)
   - TRACK/SPEC/multi-PLAN: acknowledge current parser mismatch; no P10 until deterministic parser exists; once added, then P10 once (document as “not yet implemented”)
4. Add/keep the “parser mismatch warning” note (extract_plan.py doesn’t match TRACK/SPEC/multi-task PLAN today) to prevent churn and misattribution to P10.

## Minimum required content to add (can be placed under “Sentinel Parsing” near existing retry text)

### P10: Format-Repair (Universal; One Retry Max)

When a sentinel block fails parsing/validation, the orchestrator MAY attempt a single format-repair retry using:
- Template: `.pipe/p10/P10_FORMAT_REPAIR.md`
- Inputs: verbatim parser/validator error + verbatim original output + injected per-block format contract
- Constraints: same nonce (same cycle), same model, one retry maximum
- Output: block-only corrected sentinel block (no prose, no code fences)

#### Guards (skip P10)
- If original output is `< 50 chars`: skip P10; follow the per-block failure policy.
- If the error contains a Python traceback/crash: skip P10; follow the per-block failure policy (tooling bug).

#### Truncation
- If original output is > 8K chars: include first 4K + last 4K with `"[...truncated...]"`.

#### Per-block trigger & failure policy

| Block Type | Validation Mechanism (Current) | Invoke P10 When | After P10 Retry Fails |
|-----------|---------------------------------|-----------------|------------------------|
| PLAN (single-task) | `extract_plan.py` exit 1 + actionable stderr | parse fails with `ParseError` | `CYCLE_FAIL` |
| TRACK / SPEC / multi-PLAN | **not yet supported by deterministic parser** | N/A (skip P10 until parser exists) | `CYCLE_FAIL` (if validation required) |
| VERDICT (per-criterion) | pre-parse regex/shape validation (don’t key on `build_verdict.py` exit code) | verdict block malformed for that criterion | That criterion → `NEEDS_HUMAN` |
| REFLECT | grammar validation per `.pipe/p9.5/P9_5_REFLECT.md` | reflect block malformed | Non-fatal degrade: treat as `ACTION=NOP`, log warning |

Also preserve any existing details about why `build_verdict.py` exit codes are not a repair trigger (it exits 0 for per-criterion parse failures).

Keep wording consistent with the P10 synthesis; do not introduce new semantics.

---

# Deliverable 3 — Update `.pipe/p2-codex-prompt.md` (Mirror CLAUDE.md Changes)

`.pipe/p2-codex-prompt.md` duplicates sentinel parsing + repair policy. Mirror the `CLAUDE.md` P10 format-repair policy changes into `.pipe/p2-codex-prompt.md`:
- Reference `.pipe/p10/P10_FORMAT_REPAIR.md`
- Add the same guards (empty output, traceback)
- Add the same truncation rule
- Add the same per-block trigger table
- Ensure existing VERDICT repair logic remains correct (pre-parse validation; one retry; then `NEEDS_HUMAN`)
- Ensure REFLECT non-fatal behavior is preserved (repair once, then degrade)

Keep wording consistent between `CLAUDE.md` and `.pipe/p2-codex-prompt.md`.

---

# Parser Error Format References (Do Not Change Parsers)

You must keep contracts compatible with the parser realities:

## `extract_plan.py` (PLAN)
- Failures are actionable and emitted on stderr as `ParseError(...)`, often prefixed with `line N: ...`.
- Typical messages include:
  - `line N: ...` (field/key/quote/tab issues)
  - `tab character at start of line`
  - `invalid path characters`, `absolute path not allowed`, `path traversal not allowed`

## `build_verdict.py` (VERDICT)
- Failures are actionable and raised as `ParseError(...)` with messages like:
  - `expected exactly 1 <<<VERDICT: block, found N`
  - `expected exactly 1 <<<END_VERDICT: block, found N`
  - `opener must appear before closer`
  - `nonce mismatch: ...`
  - `criterion mismatch: ...`
  - `unknown field '...'`
  - `duplicate field '...'`
  - `ANSWER must be YES or NO, got '...'`
  - `ANSWER must be unquoted`
  - `REASON must be quoted` / `REASON exceeds 500 chars` / `REASON must be single-line`
- Exit code caveat: the script can still exit 0 while returning `NEEDS_HUMAN` for criteria; do not use exit status alone as the repair trigger.

---

# Acceptance Checklist (for your own verification before finishing)

Before you stop:
- Exactly 3 files changed (1 add, 2 updates).
- `.pipe/p10/P10_FORMAT_REPAIR.md` matches the required template structure and includes COMMON FIXES + REPAIR CHECKLIST.
- `CLAUDE.md` references the P10 template and includes the per-block trigger table + guards + truncation rule.
- `.pipe/p2-codex-prompt.md` mirrors the same P10 format-repair policy language.
- No changes to `extract_plan.py` or `build_verdict.py`.
