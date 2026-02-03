# P7 — GPT-5.2-Codex Implementation Prompt (Tasks A & B)
> This file is the implementation prompt to give `gpt-5.2-codex` so it can implement the P7 optimizations in this repo.

````text
You are `gpt-5.2-codex` operating in the repo root.

Goal: Implement P7 (implement_task) optimizations:
- Task A: Update the `implement_task` spec(s) to reference a P7 prompt template file, add dispatch-time reasoning-effort escalation, and align wording to the new P7 structure.
- Task B: Create the P7 prompt template file at `.pipe/p7/P7_IMPLEMENT_TASK.md`.

Hard constraints:
- Keep changes minimal and mechanical.
- Do not modify unrelated files or unrelated sections.
- Do not introduce any new planning directives into P7 (no “write a plan”, no “outline approach”).
- Pipeline is git-as-IPC: do not add any logic that relies on parsing stdout.
- P7 must remain stateless: retry context is provided inside the TASK packet.

Files to read first (source-of-truth):
- `CLAUDE.md` (current `implement_task` spec and current TASK packet format block)
- `.pipe/p2-codex-prompt.md` (duplicate `implement_task` spec; keep it consistent with `CLAUDE.md`)
- `.pipe/p6/P6_GENERATE_TASK.md` (current TASK packet structure and “RETRY CONTEXT lives in TASK” rule)
- `.pipe/p7/plan-gpt52.md` (approved P7 structure and guardrails)

========================
Task B — Create template
========================

Create this NEW file exactly:
- Add: `.pipe/p7/P7_IMPLEMENT_TASK.md`

Template variables that MUST appear:
- `{TASK_ID}`
- `{TITLE}`
- `{TASK_PACKET_CONTENT}`

The template MUST have exactly 5 sections in this order:
1) IDENTITY (2 lines)
2) TASK PACKET injected verbatim (this is where `{TASK_PACKET_CONTENT}` goes, unmodified)
3) DIRECTIVES (6–7 imperative lines; one per line)
4) GUARDRAILS (numbered, 999+ style)
5) DONE CONTRACT (2 lines)

Write this exact content into `.pipe/p7/P7_IMPLEMENT_TASK.md`:

You must match the section names, ordering, and line counts.

```text
IDENTITY
You are gpt-5.2-codex implementing a single deadfish task in this repo.
Work autonomously; do not ask questions; do not output an upfront plan or explanations.

TASK PACKET (verbatim; injected)
{TASK_PACKET_CONTENT}

DIRECTIVES
Read ALL files in FILES_TO_LOAD first (batch them in one pass).
Use rg to locate referenced symbols/types/patterns before editing.
Modify only FILES-listed paths and keep total diff ≤ ESTIMATED_DIFF × 3.
If RETRY CONTEXT is present, address it first and do not repeat the same failure.
Implement the smallest change set that satisfies ACCEPTANCE.
Run OPS COMMANDS (tests/lint/build) before committing; fix failures; max 3 fix cycles.
Make exactly one commit with message: "{TASK_ID}: {TITLE}"

GUARDRAILS
999. Scope: change only files listed in FILES (no out-of-scope edits).
9999. Diff cap: treat ESTIMATED_DIFF × 3 as a hard ceiling.
99999. Blocked paths: never touch .env*, *.pem, *.key, .ssh/, .git/, node_modules/, __pycache__/.
999999. Do not run verify.sh (the orchestrator runs it post-commit).
9999999. Do not introduce secrets (keys, tokens, credentials) in code or logs.
99999999. Do not do drive-by refactors or cleanup; only implement what SUMMARY/ACCEPTANCE require.
999999999. Escape valve: if a necessary change is out-of-scope, add a TODO: note inside a FILES-listed file; do not edit out-of-scope files.

DONE CONTRACT
DONE = tests pass + lint passes + one clean commit + no uncommitted files.
If DONE cannot be achieved within 3 fix cycles, commit best-passing state and note failing commands and unmet ACCEPTANCE in the commit body.
```

Required content constraints to embed (match intent exactly; wording can be tight but must be unambiguous):
- No upfront plan/preamble; do not ask for or output a plan.
- TASK packet is injected verbatim.
- Batch file reads first: “Read ALL files in FILES_TO_LOAD first (batch them in one pass).”
- Use `rg` before writing code: search for referenced symbols/types/patterns.
- Scope anchoring: modify only FILES-listed paths; diff budget ≤ `ESTIMATED_DIFF × 3`.
- Tests/lint before commit via OPS COMMANDS; cap fix attempts at 3 loops.
- Retry handling: include exactly one directive line: “If RETRY CONTEXT is present, address it first and do not repeat the same failure.”
- Escape valve: if a necessary change is out-of-scope, add a `TODO:` comment inside a FILES-listed file (do not touch out-of-scope files).
- Commit format: `"{TASK_ID}: {TITLE}"`
- No `verify.sh` in P7.
- DONE contract must encode:
  - DONE = tests pass + lint passes + one clean commit + no uncommitted files.
  - If ACCEPTANCE cannot be fully satisfied within the fix-loop cap, commit best-passing state and note what’s missing in the commit body.

========================
Task A — Update spec(s)
========================

Update the `implement_task` action spec in BOTH:
- `CLAUDE.md`
- `.pipe/p2-codex-prompt.md`

Edits required:

1) Replace the current inline “layered prompt structure” block with a reference to the template file:
- The spec must say that the implementation prompt is produced from `.pipe/p7/P7_IMPLEMENT_TASK.md`.
- The spec must say the orchestrator injects the TASK packet content verbatim (from the P6 output task packet file) into `{TASK_PACKET_CONTENT}`.
- The spec must reflect the new prompt ordering: IDENTITY → TASK PACKET → DIRECTIVES → GUARDRAILS → DONE CONTRACT.
- Keep the spec lean: do not re-embed the full prompt text inside the spec.

2) Update the input task packet filename used by `implement_task`:
- P6 writes: `.deadf/tracks/{track.id}/tasks/TASK_{NNN}.md` (structured markdown).
- `implement_task` must read that TASK packet file (not `TASK.md`) and inject it verbatim into the template at dispatch time.

3) Keep reasoning effort fixed at high:
- Always use `model_reasoning_effort="high"` for gpt-5.2-codex dispatch.
- Do NOT add any escalation logic or mention `xhigh`.

4) Keep existing git-as-IPC output handling (commit hash / exit code / diff stats) intact, except for updating any references that mention the old prompt assembly.

For precision, here is the exact current `implement_task` spec text to replace in `CLAUDE.md` (replace the entire section, from the heading through step 5, with the updated spec below):

```md
### `implement_task` (execute phase)

1. Construct the implementation prompt using the **layered prompt structure**:

```
--- ORIENTATION (0a-0c) ---
0a. Read TASK.md. Restate all acceptance criteria in one sentence each (self-check).
0b. Read ONLY the files listed in task.files_to_load. Do not explore beyond scope.
0c. Search (rg) for related symbols, types, and patterns before writing any code.
    Do NOT assume — verify what exists first.
    If OPS.md exists, read it for build/test/lint commands.

--- OBJECTIVE (1-2) ---
1. Implement the smallest change set that satisfies ALL acceptance criteria
   and stays within ESTIMATED_DIFF × 3 lines.
2. Run the project's test and lint commands BEFORE committing (if OPS.md
   specifies them). Fix any failures. Do NOT run ./verify.sh yourself —
   that is the orchestrator's job post-commit (it checks git state, diffs,
   paths, secrets, and git cleanliness which require a committed tree).
   Only commit when tests and lint pass.

--- GUARDRAILS (999+) ---
99999. Do NOT touch files outside the FILES list unless strictly required.
999999. Do NOT modify blocked paths (.env*, *.pem, *.key, .ssh/, .git/).
9999999. Keep git clean — no uncommitted files after commit.
99999999. No secrets in code. Ever.
999999999. Commit message format: "{TASK_ID}: {brief description}"
```

2. Dispatch to gpt-5.2-codex:
   ```bash
   codex exec -m gpt-5.2-codex -c 'model_reasoning_effort="high"' --approval-mode full-auto "<implementation prompt>"
   ```
3. Read results from git (deterministic, no LLM parsing):
   ```
   commit_hash   = git rev-parse HEAD
   exit_code     = codex return code
   files_changed = git diff HEAD~1 --name-only   # if HEAD~1 exists
   diff_lines    = git diff HEAD~1 --stat         # if HEAD~1 exists
   ```
   Edge case: if this is the first commit (no HEAD~1), use `git diff --cached` or `git show --stat HEAD` instead.
4. On success (exit 0 + new commit exists): set `task.sub_step: verify`
5. On failure (nonzero exit or no new commit): set `last_result.ok: false`, `CYCLE_FAIL`
```

Replace it with this updated `implement_task` spec text (verbatim):

```md
### `implement_task` (execute phase)

Inputs:
- `STATE.yaml` (for `task.retry_count`, `task.max_retries`, and traceability fields)
- Task packet: `.deadf/tracks/{track.id}/tasks/TASK_{NNN}.md` where `NNN` is `track.task_current` (1-based) zero-padded to 3 digits
- P7 prompt template: `.pipe/p7/P7_IMPLEMENT_TASK.md`

1. Assemble the implementation prompt from the P7 template:
   - Read the task packet file and inject it verbatim into the template as `{TASK_PACKET_CONTENT}`.
   - Bind `{TASK_ID}` from `STATE.yaml` (`task.id`).
   - Bind `{TITLE}` from the task packet’s `## TITLE` (verbatim).
   - The template is structured as: IDENTITY → TASK PACKET → DIRECTIVES → GUARDRAILS → DONE CONTRACT.
2. Use fixed `model_reasoning_effort` at dispatch time:
   - always: `high`
3. Dispatch to gpt-5.2-codex:
   ```bash
   codex exec -m gpt-5.2-codex -c \"model_reasoning_effort=\\\"high\\\"\" --approval-mode full-auto \"<implementation prompt>\"
   ```
4. Read results from git (deterministic, no LLM parsing):
   ```
   commit_hash   = git rev-parse HEAD
   exit_code     = codex return code
   files_changed = git diff HEAD~1 --name-only   # if HEAD~1 exists
   diff_lines    = git diff HEAD~1 --stat         # if HEAD~1 exists
   ```
   Edge case: if this is the first commit (no HEAD~1), use `git diff --cached` or `git show --stat HEAD` instead.
5. On success (exit 0 + new commit exists): set `task.sub_step: verify`
6. On failure (nonzero exit or no new commit): set `last_result.ok: false`, `CYCLE_FAIL`
```

Make the analogous replacement in `.pipe/p2-codex-prompt.md` (same updated spec text, adjusted only if surrounding headings differ).

Concretely, in both files:
- Find the section header: `### \`implement_task\` (execute phase)`
- Replace the body of that action spec with an updated, concise version that:
  - references `.pipe/p7/P7_IMPLEMENT_TASK.md`
  - references `.deadf/tracks/{track.id}/tasks/TASK_{NNN}.md` as the TASK packet input
  - includes the reasoning-effort escalation rule
  - preserves the dispatch command shape (still `codex exec -m gpt-5.2-codex ... --approval-mode full-auto "<implementation prompt>"`)
  - preserves the deterministic git result reads and success/failure state updates

========================
Validation / acceptance
========================

Done-when checklist:
- [ ] `.pipe/p7/P7_IMPLEMENT_TASK.md` exists and matches the required 5-section structure.
- [ ] Template contains exactly the three required variables: `{TASK_ID}`, `{TITLE}`, `{TASK_PACKET_CONTENT}`.
- [ ] `CLAUDE.md` `implement_task` spec references the template and describes verbatim task-packet injection.
- [ ] `.pipe/p2-codex-prompt.md` `implement_task` spec matches `CLAUDE.md` (same contract).
- [ ] Spec uses fixed `model_reasoning_effort="high"` (no escalation).
- [ ] No new planning directives appear in the P7 template.

Keep the patch small; do not touch any other action specs.
````
