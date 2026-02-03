# P1 (Cycle Kick) — Implementation Prompt for `gpt-5.2-codex`

You are `gpt-5.2-codex`, operating in this repo. Implement **P1 Cycle Kick** per the approved spec and R2 review notes.

## Read First (inputs; do not skip)
1. `.pipe/p1/synthesis-opus-orchestrator.md` (APPROVED synthesis v2 — spec)
2. `.pipe/p1/synthesis-review-gpt52-r2.md` (R2 review — 2 minor fixes)
3. `CLAUDE.md` (binding contract — match voice; verify `DEADF_CYCLE` references)
4. `PROMPT_OPTIMIZATION.md` (status — update P1 entry)

## R2 Minor Fixes (must incorporate)
1. **Launcher skip behavior is non-silent**: `p1-cron-kick.sh` MUST emit **one structured log line** on every “skip / no session spawned” exit, including **exit_code** and a stable **reason**. No silent exits.
2. **Remove “Skill: deadfish” from kick template**: Replace with `Contract: CLAUDE.md (binding)`.

---

## Deliverables

### A) Create `.pipe/p1/P1_CYCLE_KICK.md` (canonical template)
Must contain:
- A **Variables** table defining these placeholders (exact brace form):
  - `{PROJECT_NAME}` — string (default: basename of project path)
  - `{PROJECT_PATH}` — absolute path
  - `{CYCLE_ID}` — `cycle-{iteration+1}-{8hex}`
  - `{MODE}` — from `STATE.yaml .mode` (fallback `unknown`)
  - `{STATE_HINT}` — extracted under process lock (see format below)
  - `{DISCORD_CHANNEL}` — optional; from `POLICY.yaml .heartbeat.discord_channel` (fallback `unknown`)
- A **Kick Message** block (copyable) in a fenced `text` block. Keep ~120–180 tokens. It MUST:
  - Start with: `DEADF_CYCLE {CYCLE_ID}`
  - Include: `project: {PROJECT_NAME}`, `path: {PROJECT_PATH}`, `mode: {MODE}`
  - Include: `state: {STATE_HINT} (advisory — STATE.yaml is authoritative; ignore hint if it conflicts)`
  - Optionally include: `discord: {DISCORD_CHANNEL}`
  - Include BOOTSTRAP section (cd, required files exist, acquire `STATE.yaml.flock` for VALIDATE)
  - Include EXECUTE directive: “Follow CLAUDE.md iteration contract… ONE action…”
  - Include **R2 fix #2 line**: `Contract: CLAUDE.md (binding)`
  - Include reply contract: final line token must be one of `CYCLE_OK | CYCLE_FAIL | DONE`
- A **State Hint Format** section:
  - Format: `{cycle.status} {phase}:{sub_step} #{iteration} task={task_id} retry={retry_count}/{max_retries}`
  - Include 3–5 examples.

### B) Create `.pipe/p1/p1-cron-kick.sh` (reference launcher; executable)
Production-quality bash. Requirements:
- Shebang: `#!/usr/bin/env bash`
- `set -euo pipefail` and safe IFS.
- Determine `PROJECT_PATH` robustly as repo root based on script location (no external args required).
- Ensure `.deadf/` and `.deadf/logs/` exist.
- Hard deps check: `flock`, `yq` (mikefarah v4+), `date`, `mktemp`, `tee`. Fail with structured error log.

#### Responsibilities (in this order)
1. **Acquire process lock**: `.deadf/cron.lock` via `flock -n` and hold it for the entire runtime (including the orchestrator subprocess).
2. **Stale recovery** (under process lock):
   - Read `cycle.status` and `cycle.started_at` from `STATE.yaml`.
   - If `cycle.status == running` AND `now - started_at >= TIMEOUT_S` (default `600`, configurable via env `P1_CYCLE_TIMEOUT_S`):
     - Under the shared `STATE.yaml.flock` lock (R-M-W, temp+mv), set ONLY:
       - `cycle.status: timed_out`
       - `phase: needs_human`
     - Then **exit** (no session spawn) with structured skip output (reason `stale_running_cycle`).
   - If `cycle.status == running` but not stale: **exit** (no session spawn) with structured skip output (reason `cycle_running`).
3. **Quick-exit checks** (under process lock):
   - If `phase == needs_human`: exit with structured skip output (reason `needs_human`).
   - If `phase == complete`: exit with structured skip output (reason `complete`).
4. **State hint extraction** (under process lock):
   - Extract fields using `yq -r` with safe defaults:
     - `cycle.status`, `phase`, `task.sub_step`, `loop.iteration`, `task.id`, `task.retry_count`, `task.max_retries`
   - Assemble `STATE_HINT` exactly per the template spec.
5. **Cycle ID generation**:
   - Use `loop.iteration` (default `0` if missing/non-numeric) → `iteration_plus_one`.
   - Generate `8hex` from `/dev/urandom`.
   - Format exactly: `cycle-${iteration_plus_one}-${hex}`.
6. **Kick message assembly**:
   - Read `.pipe/p1/P1_CYCLE_KICK.md` and extract ONLY the fenced `text` kick block.
   - Substitute `{…}` placeholders without introducing shell injection risks (pure string substitution).
7. **Log rotation**:
   - Keep last 50 `cycle-*.log` in `.deadf/logs/` (configurable via `P1_MAX_LOGS`, default `50`).
8. **Dispatch orchestrator session**:
   - Spawn Claude Code CLI (default `claude`, overridable via `P1_CLAUDE_BIN`).
   - Use `--print` and an `--allowedTools` set matching `CLAUDE.md` conventions.
   - Pass the assembled kick message as the single CLI argument.
   - Tee stdout/stderr into `.deadf/logs/cycle-{CYCLE_ID}.log`.
   - Keep the process lock held until the subprocess exits.

#### Structured logging (R2 fix #1)
Implement `log_json` that prints **one line** JSON to stdout:
```json
{"ts":"...","level":"INFO|WARN|ERROR","event":"skip|start|spawn|done|stale_recovery|error","exit_code":<int>,"reason":"<stable_reason>","project_path":"...","cycle_id":"..."}
```
Rules:
- Every skip path MUST emit exactly one `event:"skip"` log line and exit with the documented code.
- Every fatal error MUST emit exactly one `event:"error"` log line and exit non-zero.
- “Lock held” MUST be treated as a skip, not silent.

Define stable exit codes (document in script header comment), e.g.:
- `0` success (session spawned; subprocess exit code 0)
- `10` skip: lock held
- `11` skip: needs_human
- `12` skip: complete
- `13` skip: cycle_running (non-stale)
- `14` skip: stale_running_cycle (recovered → needs_human)
- `20` error: preflight/deps/state parse/update failure
- `21` error: orchestrator spawn failure
Use these consistently and include in the JSON log.

### C) Update `CLAUDE.md` (contract; terse voice)
Update the “cycle kick / ralph.sh” section to:
- Reference `.pipe/p1/P1_CYCLE_KICK.md` as the canonical kick template.
- State explicitly that the canonical trigger sentinel is: `DEADF_CYCLE <cycle_id>`.
- Document the **dual-lock model**:
  - Process lock: `.deadf/cron.lock` held by launcher for full orchestrator runtime
  - State lock: `STATE.yaml.flock` held by orchestrator for atomic R-M-W (VALIDATE + RECORD)
- Add/clarify the **early-exit / output contract**:
  - If the orchestrator is invoked, it MUST always end with exactly one of: `CYCLE_OK | CYCLE_FAIL | DONE` as the last line.
  - If the launcher skips (no orchestrator spawned), it MUST emit one structured `skip` log line (exit code + reason).
- Remove or generalize `ralph.sh`-specific phrasing where it conflicts with the new launcher model. (Do not delete ralph.sh; just update the doc section to reflect that ralph/cron should call the P1 launcher or use the P1 template.)

### D) Update `PROMPT_OPTIMIZATION.md`
- In the **Prompt Inventory** P1 section, mark P1 as implemented and reference:
  - `.pipe/p1/P1_CYCLE_KICK.md`
  - `.pipe/p1/p1-cron-kick.sh`
- In the **Review order** table, update the `P1 — Cycle Kick` row from “🔲 À optimiser” to “✅ Implemented” (terse).

---

## Guardrails
- Match `CLAUDE.md` contract tone: terse, imperative, no fluff.
- Do NOT change unrelated files.
- Do NOT add new external dependencies beyond what the repo already assumes (`yq` is acceptable; ralph.sh already requires it).
- Keep the kick message token budget tight (it’s a trigger, not a briefing).

## Verification (run before finishing)
- `bash -n .pipe/p1/p1-cron-kick.sh`
- `chmod +x .pipe/p1/p1-cron-kick.sh`
- Smoke check structured skip log:
  - Temporarily simulate lock held: run two instances; second must print one JSON skip line with reason `lock_held` and exit code `10`.

## Output
Implement the changes directly in the repo. Do not paste large code blocks into the chat; just make the edits and summarize.

