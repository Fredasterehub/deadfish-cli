# P9 Implementation Prompt for GPT-5.2-Codex

You are **GPT-5.2-Codex**. Your job is to implement **P9 verification orchestration contract updates** exactly as specified below.

Work in: `/tank/dump/DEV/deadfish-cli`.

## Scope (Hard-Bounded)

You MUST change **exactly 3 files**:
1. Create: `.pipe/p9/P9_VERIFY_CRITERION.md`
2. Update: `CLAUDE.md` (only the `verify_task` section + related verdict/repair/sub-agent output contract text needed for consistency)
3. Update: `.pipe/p2-codex-prompt.md` (mirror the same `verify_task`/verdict/repair changes for consistency)

Do **NOT** modify any other files (including `build_verdict.py`).

## Inputs You MUST Read (in this repo)

Read these files before editing:
- `.pipe/p9/synthesis-opus-orchestrator.md` (approved design; follow exactly)
- `.pipe/p9/synthesis-review-gpt52-r2.md` (required fixes to apply in contracts)
- `CLAUDE.md` (current contract to update)
- `.pipe/p2-codex-prompt.md` (must mirror CLAUDE changes)
- `.pipe/p7/P7_IMPLEMENT_TASK.md` (style reference)
- `.pipe/p6/P6_GENERATE_TASK.md` (style reference)
- `build_verdict.py` (parser contract you must remain compatible with)

## Goal

P9 introduces a per-criterion LLM verification prompt template (one sub-agent per `LLM:` criterion, max 7 parallel), with a strict sentinel verdict block that is parsed by `build_verdict.py`.

Your work here is purely **contract/template plumbing**:
- Add the new template file used to prompt sub-agents.
- Update `CLAUDE.md` and `.pipe/p2-codex-prompt.md` so the verification contract matches P9 synthesis and the parser realities.

## Non-Negotiables (From Approved P9 Synthesis)

- Conservative default: uncertain → `ANSWER=NO`.
- Use Opus’s 3-level verification gates: **EXISTS → SUBSTANTIVE → WIRED** (all must pass for YES).
- Evidence bundles per criterion are capped (~4K tokens target).
- No changes to `build_verdict.py`.
- Format repair: **one retry max per criterion**.
- Output must be **block-only** (no prose outside the verdict block).
- Untagged criteria behavior: treat as `LLM:` but emit an orchestrator warning log (contract update required).
- DET criteria: deterministic-only; if **all** criteria are DET (or there are no LLM criteria after tagging), skip P9 entirely.

---

# Deliverable 1 — Create `.pipe/p9/P9_VERIFY_CRITERION.md` (Exact Template)

Create the file exactly with the following content (verbatim except placeholders). Do not rename placeholders.

Required placeholders (must appear exactly as written):
`{criterion_id}`, `{criterion_text}`, `{nonce}`, `{task_id}`, `{task_title}`, `{task_summary}`, `{planned_files}`, `{verify_json_excerpt}`, `{git_show_stat}`, `{out_of_scope_section}`, `{diff_hunks}`, `{test_output_section}`

## `.pipe/p9/P9_VERIFY_CRITERION.md` content

IDENTITY
You are a verification sub-agent for the deadf(ish) pipeline.
Decide whether ONE acceptance criterion is satisfied using ONLY the evidence below.
You are a judge, not an implementer. Do not suggest fixes or improvements.
Output ONLY the verdict block — no other text.

CRITERION
{criterion_id}: "{criterion_text}"

DECISION RULES (LOCKED RUBRIC)
Verify using three levels — all must pass for YES:
  Level 1 — EXISTS: Do the diff hunks show the artifact/behavior described?
  Level 2 — SUBSTANTIVE: Is it real implementation, not any of these:
    - TODO, FIXME, PLACEHOLDER, HACK comments
    - `return null`, `return {}`, `pass`, `...` stubs
    - trivial assertions like `expect(true).toBe(true)`
    - empty function/method bodies
  Level 3 — WIRED: Is it connected via at least one of:
    - import/use-site in calling code
    - export surface update (module index, __init__, barrel file)
    - route/handler/middleware registration
    - config entry, CLI command wiring, or dependency injection
    If wiring evidence is not in the provided hunks: NO with "insufficient evidence: wiring not shown"

Additional rules:
- Use ONLY the evidence bundle. Never infer what's not shown.
- If evidence is insufficient: NO with REASON "insufficient evidence: <what's missing>"
- If non-trivial out-of-scope changes exist: NO with REASON "out-of-scope modification: <path>"
- If criterion is ambiguous/undecidable from code: NO with REASON "ambiguous criterion: <issue>"
- If criterion requires runtime verification: NO with REASON "requires runtime verification: <what>"
- If uncertain at any level: NO. False negatives retry; false positives ship broken code.
- REASON must name the specific file, function, or behavior that's missing or wrong.

EVIDENCE BUNDLE
Task: {task_id} — {task_title}
Summary: {task_summary}
Planned FILES: {planned_files}

verify.sh (fields: pass, test_summary, lint_exit, diff_lines, secrets_found, git_clean):
{verify_json_excerpt}

Changed files:
{git_show_stat}

{out_of_scope_section}

Relevant diff hunks:
{diff_hunks}

{test_output_section}

OUTPUT (STRICT — output ONLY this block, nothing else)
<<<VERDICT:V1:{criterion_id}:NONCE={nonce}>>>
ANSWER=YES
REASON="One sentence, ≤500 chars, naming the specific gap or confirmation."
<<<END_VERDICT:{criterion_id}:NONCE={nonce}>>>

Choose exactly one: ANSWER=YES if all three levels pass, ANSWER=NO otherwise.
Output exactly two lines inside the block: ANSWER and REASON. No other keys, no blank lines, no commentary.
Do not use double quotes inside REASON — use single quotes or backticks for filenames/symbols.
Do not use backslashes — use forward slashes in paths.
Do not use code fences anywhere in your output.

---

# Deliverable 2 — Update `CLAUDE.md` (`verify_task` contract + related sections)

Update `CLAUDE.md` so the orchestrator’s `verify_task` spec matches P9 synthesis + `build_verdict.py` reality.

## Required `CLAUDE.md` changes

### A) Reference the P9 template
- `verify_task` must explicitly reference `.pipe/p9/P9_VERIFY_CRITERION.md` as the per-criterion sub-agent prompt template.

### B) Verdict block format (parser-safe)
Replace the old, parse-risky block example:
- Remove the literal `ANSWER=YES or NO` wording everywhere.
- Add explicit rule: choose exactly one (`YES` or `NO`).
- Add explicit rule: inside the block there must be **exactly two lines**: `ANSWER=...` then `REASON="..."` (no other keys, no blank lines).
- Add `REASON` escaping rules aligned to `build_verdict.py`:
  - `REASON` must be double-quoted; it must be a single line; ≤500 chars.
  - Do **not** include `"` inside REASON (avoid escaping footguns); prefer `'` or backticks.
  - Do **not** use backslashes; use forward slashes in paths.
  - No code fences; no extra commentary outside the block.

### C) Repair trigger fix (do NOT rely on `build_verdict.py` exit code)
Update `verify_task` to specify **pre-parse regex validation** of each raw sub-agent response **before** feeding it to `build_verdict.py`.

Why: `build_verdict.py` returns **exit 0** even when a criterion block is malformed; it emits `NEEDS_HUMAN` in-band per criterion. The old contract (“retry only if build_verdict exits 1”) is wrong.

Spec to implement in the contract:
- For each criterion response:
  1) Run a lightweight regex/string-structure check requiring:
     - exactly one opener line and one closer line for that criterion id and nonce
     - exactly two payload lines: `ANSWER=YES|NO` and `REASON="..."` (no extra lines outside the block)
  2) If the check fails: send **one** repair retry prompt to the same sub-agent: “Your output could not be parsed. Please output ONLY the corrected verdict block, no other text.” (same nonce).
  3) If still malformed after one retry: mark that criterion as `NEEDS_HUMAN`.

Optionally (recommended in contract): after `build_verdict.py`, if any criterion is `NEEDS_HUMAN` with a parse-ish reason, do **not** loop repairs beyond the single retry above.

### D) Untagged criteria behavior (contract alignment)
Update the acceptance-criteria tagging rules:
- `DET:` criteria: deterministic-only; auto-pass if `verify.sh.pass == true`.
- `LLM:` criteria: require P9 sub-agent verification.
- **Untagged** criteria: treat as `LLM:` **and** log a warning in orchestrator logs (fail-safe).

### E) DET fast-path
Update `verify_task` to include:
- If `verify.sh.pass == true` **and** there are **no** LLM criteria after applying tagging rules (including the “untagged → LLM” rule), then skip P9 entirely and proceed as if LLM verification PASS.

### F) Evidence bundle composition (must match synthesis)
Update `verify_task` to specify each per-criterion evidence bundle includes:
- Criterion id + verbatim text
- Task id/title/summary + planned FILES list
- verify.sh JSON excerpt: `pass`, `test_summary`, `lint_exit`, `diff_lines`, `secrets_found`, `git_clean`
- `git show --stat` (full)
- Relevant diff hunks (criterion-specific)
- Out-of-scope diff hunks section (if any out-of-scope edits occurred) + strict rule: non-trivial out-of-scope change → `ANSWER=NO` with `out-of-scope modification: <path>`
- Test output section (if applicable)
- Truncation rule: if evidence was truncated such that decisive hunks may be missing → sub-agent MUST `ANSWER=NO` with `insufficient evidence: truncated`
- Mapping heuristic: criterion-to-file mapping via keyword match against planned FILES rationale; fallback to all hunks; always include likely wiring surfaces if changed (index/init modules, registries, routers, CLI entrypoints, config).

### G) Nonce constraints
Reassert nonce format where relevant: exactly 6-char uppercase hex `^[0-9A-F]{6}$`.

### H) Sub-agent output contract alignment
Update any “Sub-Agent Output Contract” text that currently permits/proposes extra prose:
- Must be **block-only** output (the template already says this).

---

# Deliverable 3 — Update `.pipe/p2-codex-prompt.md` (Mirror CLAUDE.md)

`.pipe/p2-codex-prompt.md` currently duplicates the older `verify_task` / verdict / repair language.

Mirror **all** changes from `CLAUDE.md` into `.pipe/p2-codex-prompt.md`:
- Reference `.pipe/p9/P9_VERIFY_CRITERION.md`
- Updated verdict block example and strict rules
- Pre-parse regex repair trigger (not exit code)
- Untagged criteria behavior
- DET fast-path
- Evidence bundle composition + truncation + mapping heuristic
- Nonce constraint
- Block-only sub-agent output

Keep wording consistent between the two files.

---

# `build_verdict.py` Parser Contract (You MUST remain compatible)

Do not change the script. Your templates/contracts must respect these rules:

## Sentinel format
- Opener line must match:
  - `<<<VERDICT:V1:(AC[0-9]+):NONCE=([0-9A-F]{6})>>>`
- Closer line must match:
  - `<<<END_VERDICT:(AC[0-9]+):NONCE=([0-9A-F]{6})>>>`
- Exactly **one** opener and **one** closer must appear.
- Criterion id and nonce must match between opener/closer, must match expected `--criteria` and `--nonce`.

## Payload format
- Only keys allowed: `ANSWER`, `REASON` (no others).
- `ANSWER` must be **unquoted** and exactly `YES` or `NO` (case-insensitive accepted, but normalizes).
- `REASON` must be **double-quoted**, non-empty, single line, max 500 chars.
- Inside a quoted REASON, unescaped `"` is forbidden.
- Escapes allowed in quoted strings: `\\`, `\"`, `\t` only (no `\n` / `\r`).
- Payload size cap: 16,000 chars.

## Exit code reality (important)
- Per-criterion parse errors produce `answer: NEEDS_HUMAN` for that criterion but the script still exits **0**.
- Exit **1** is reserved for CLI/input-level errors (invalid JSON, invalid nonce, invalid criteria list, etc.).

This is why the repair trigger must be pre-parse (and/or inspect the JSON output), not keyed to exit status.

---

# Style References (Keep Consistent Tone/Structure)

These are included only so you keep style consistent with existing pipeline templates/contracts.

## `.pipe/p7/P7_IMPLEMENT_TASK.md` (verbatim)

IDENTITY
You are gpt-5.2-codex implementing a single deadfish task in this repo.
Work autonomously; do not ask questions; do not output an upfront plan or explanations.

TASK PACKET (verbatim; injected)
{TASK_PACKET_CONTENT}

DIRECTIVES
Read ALL files in FILES_TO_LOAD first (batch them in one pass).
Use rg to locate referenced symbols/types/patterns before editing.
Modify only FILES-listed paths and keep total diff ≤ max_diff.
If RETRY CONTEXT is present, address it first and do not repeat the same failure.
Implement the smallest change set that satisfies ACCEPTANCE.
Run OPS COMMANDS (tests/lint/build) before committing; fix failures; max 3 fix cycles.
Make exactly one commit with message: "{TASK_ID}: {TITLE}"

GUARDRAILS
99999. Scope: change only files listed in FILES (no out-of-scope edits).
999999. Diff cap: treat max_diff as a hard ceiling.
9999999. Blocked paths: never touch .env*, *.pem, *.key, .ssh/, .git/, node_modules/, __pycache__/.
99999999. Do not run verify.sh (the orchestrator runs it post-commit).
999999999. Do not introduce secrets (keys, tokens, credentials) in code or logs.
9999999999. Do not do drive-by refactors or cleanup; only implement what SUMMARY/ACCEPTANCE require.
99999999999. Escape valve: if a necessary change is out-of-scope, add a TODO: note inside a FILES-listed file; do not edit out-of-scope files.

DONE CONTRACT
DONE = tests pass + lint passes + one clean commit + no uncommitted files.
If DONE cannot be achieved within 3 fix cycles, commit best-passing state and note failing commands and unmet ACCEPTANCE in the commit body.

## `.pipe/p6/P6_GENERATE_TASK.md` (verbatim)

--- ORIENTATION (0a-0c) ---
0a. Read STATE.yaml: track info, task_current, task_count, retry_count, last_result, plan_base_commit.
0b. Read PLAN.md at track.plan_path. Extract TASK[task_current]. If retry, read existing .deadf/tracks/{track.id}/tasks/TASK_{NNN}.md.
0c. Read OPS.md. Check current HEAD vs plan_base_commit. Search codebase for planned file paths.

--- OBJECTIVE (1) ---
1. Produce an adapted execution packet for TASK[task_current]. This prompt is used ONLY on drift or retry paths (no happy-path usage).
   - If drift: resolve file path changes, update integration points, adjust files_to_load.
   - If retry: analyze last_result.details, add retry context (what failed, what to change, what not to repeat).
   - Keep acceptance criteria IMMUTABLE - never weaken on retry.
   - Keep SUMMARY from PLAN as primary prompt - append adaptations, do not replace.

Output: a structured markdown TASK file (not sentinel).

--- OUTPUT FORMAT (2) ---
Emit exactly ONE of the following:

A) TASK markdown (optional YAML frontmatter allowed):

---
(optional frontmatter)
---

# TASK — <TASK_ID>

## Meta
- task_id: <TASK_ID>
- attempt: <retry_count + 1>
- track_id: <track.id>
- task_index: <task_current> of <task_count>

## TITLE
<TITLE from PLAN>

## SUMMARY (verbatim)
<SUMMARY from PLAN, verbatim>
<If drift or retry, append a short "Adaptations" paragraph after the verbatim SUMMARY.>

## FILES (verbatim)
- path: <resolved path> | action: <add|modify|delete> | rationale: <from PLAN>
- path: <resolved path> | action: <add|modify|delete> | rationale: <from PLAN>
- missing_or_invalid: <path> | reason: <why it no longer makes sense>  (only if applicable)

## ACCEPTANCE (verbatim)
<ACCEPTANCE from PLAN, verbatim and ordered>

## ESTIMATED_DIFF (verbatim)
<ESTIMATED_DIFF>
max_diff: <3 × ESTIMATED_DIFF>

## DEPENDS_ON (verbatim)
<DEPENDS_ON>

## OPS COMMANDS
<commands from OPS.md>

## FILES_TO_LOAD (ordered by priority, ≤3000 tokens)
- <path> | why: <reason>
- <path> | why: <reason>

## HARD STOPS / SIGNALS
- REPLAN_REQUIRED: <true|false + reason>
- REQUEST_SPLIT: <true|false + reason>

B) REPLAN_REQUIRED signal only:
REPLAN_REQUIRED: <short reason(s) for why drift or missing files block safe adaptation>

If REPLAN_REQUIRED is emitted, do not output any TASK markdown.

C) REQUEST_SPLIT signal only:
REQUEST_SPLIT: <short reason why adapted task would exceed 3× ESTIMATED_DIFF>

If REQUEST_SPLIT is emitted, do not output any TASK markdown.

--- RULES ---
- Pass through TASK_ID, TITLE, SUMMARY, FILES, ACCEPTANCE, ESTIMATED_DIFF, DEPENDS_ON from PLAN.
- On drift: update FILES paths to current reality; flag any that no longer make sense.
- On retry: append retry guidance AFTER the original SUMMARY (do not replace or edit the SUMMARY).
- files_to_load priority: modify targets -> entrypoints -> tests -> config -> style anchors.
- Cap files_to_load at 3000 tokens.
- max_diff is always 3 × ESTIMATED_DIFF. If adaptation would exceed this, output REQUEST_SPLIT.
- If modify/delete targets are missing and cannot be resolved -> output REPLAN_REQUIRED (do not guess).

--- GUARDRAILS (999+) ---
99999. Do not re-plan. Only adapt bindings and context.
999999. Acceptance criteria are immutable.
9999999. If drift is unresolvable, output REPLAN_REQUIRED - do not guess.

---

# Required Local Verification (Do This Before You Finish)

After editing, run these checks locally:

1) Ensure only the intended 3 files changed:
- `git status --porcelain`

2) Sanity-check the new template is present:
- `test -f .pipe/p9/P9_VERIFY_CRITERION.md`

3) Parser compatibility smoke test (must pass):
- Create a minimal JSON stdin with one criterion and a valid verdict block that matches the new stricter example (use a fixed nonce like `AB12CD`), then run:
  - `python3 build_verdict.py --nonce AB12CD --criteria AC1`

Example stdin (adjust as needed, but keep parser-valid):
```
[["AC1","<<<VERDICT:V1:AC1:NONCE=AB12CD>>>\\nANSWER=YES\\nREASON=\\\"ok\\\"\\n<<<END_VERDICT:AC1:NONCE=AB12CD>>>"]]
```

Confirm stdout JSON has `"verdict":"PASS"` and AC1 answer `"YES"`.

---

# Completion

When done, the repo should contain:
- `.pipe/p9/P9_VERIFY_CRITERION.md` with the merged template content above
- `CLAUDE.md` updated to reference P9 template and to reflect the new parser-safe verdict + repair behavior
- `.pipe/p2-codex-prompt.md` mirroring those changes exactly

