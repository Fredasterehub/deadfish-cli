---
name: deadfish
description: >
  deadf(ish) autonomous development pipeline v3.0.0 — heartbeat-driven.
  Clawdbot cron replaces ralph.sh. Each cycle = fresh isolated session.
  STATE.yaml = continuity. Strict role separation: Clawdbot orchestrates,
  GPT-5.2 plans, gpt-5.2-codex implements, verify.sh + Opus sub-agent verify.
  Transforms vision into shipped code through automated cron-driven cycles
  with sentinel DSL, deterministic verification, and conservative safety.
  Use when building software projects or continuing development work.
  Use when Fred mentions deadfish, pipeline, autonomous coding, or
  continuing a dev project. Also applies when discussing cycle flow,
  sentinel blocks, plan/verdict parsing, verify scripts, state management,
  or heartbeat-driven autonomous development.
---

## Quick Reference

| Action | Command / Method |
|--------|-----------------|
| Start pipeline | Create cron job (see [Activation](#activation)) |
| Stop pipeline | Disable cron job OR set `phase: needs_human` |
| Run one manual cycle | Follow [Cycle Protocol](#cycle-protocol) directly |
| Plan a task | `codex-mcp-call.sh --model gpt-5.2 --sandbox danger-full-access "..."` |
| Implement a task | `codex-mcp-call.sh --model gpt-5.2-codex --full-auto --cwd <project> "..."` |
| Implement (complex) | Same with `--model gpt-5.2-codex-high` |
| Run verification | `./verify.sh` (outputs JSON to stdout) |
| Parse plan output | `python3 extract_plan.py --nonce <NONCE> < raw_output` |
| Parse verdict output | `echo '<json>' \| python3 build_verdict.py --nonce <NONCE> --criteria AC1,AC2,...` |
| LLM verify criterion | `sessions_spawn` sub-agent per acceptance criterion |
| Read state | `yq -r '.<field>' STATE.yaml` |
| Write state | Atomic: flock → yq → temp → mv (see [State Writes](#state-write-protocol)) |
| Post status | `message` action=send to pipeline Discord channel |

## Architecture

### Heartbeat-Driven Execution

```
┌──────────┐  fires every   ┌───────────────┐   dispatch   ┌──────────────┐
│ Cron Job │── 3-5 min ────▶│ Isolated      │─────────────▶│ GPT-5.2      │
│ (driver) │                │ Session       │              │ GPT-5.2-Codex│
└──────────┘                │               │              │ Opus 4.5     │
                            │ flock → read  │              └──────────────┘
┌──────────┐                │ → ONE action  │
│ Discord  │◀── status ────│ → write state │
│ #pipeline│   one-liner   │ → release     │
└──────────┘                └───────────────┘
```

**No ralph.sh. No external loop. Clawdbot's cron IS the heartbeat.**

Each cron tick spawns a fresh isolated session. The session:
1. Acquires `flock` (non-blocking — exits if held)
2. Reads STATE.yaml
3. Runs ONE action
4. Updates STATE.yaml atomically
5. Posts status to Discord
6. Exits (flock released automatically)

STATE.yaml is the continuity. Not the context window.

### Five Actors, Strict Boundaries

| Role | Actor | Writes To |
|------|-------|-----------|
| **Driver** | Clawdbot Cron | Fires sessions on schedule |
| **Orchestrator** | Clawdbot (Claude Opus 4.5) | STATE.yaml (all fields) |
| **Planner** | GPT-5.2 (via Codex MCP) | stdout only (sentinel plan blocks) |
| **Implementer** | gpt-5.2-codex (via Codex MCP) | Source code + git commits |
| **Verifier (Script)** | verify.sh (bash) | stdout only (JSON) |
| **Verifier (LLM)** | Opus 4.5 sub-agent (`sessions_spawn`) | stdout only (sentinel verdict blocks) |

No actor crosses into another's domain. Clawdbot orchestrates but never writes code or judges quality. GPT-5.2 plans but never touches files. gpt-5.2-codex implements but never plans or verifies.

---

## Concurrency Guard

### The Problem

Two cron ticks could read `cycle.status: idle` simultaneously and both claim ownership.

### The Solution: `flock -n`

The ENTIRE cycle is wrapped in a non-blocking filesystem lock:

```bash
(
  flock -n 9 || exit 0   # If locked → another session owns it → exit silently

  # === CRITICAL SECTION ===
  # Read STATE.yaml → check phase → claim → execute → update → release
  # === END ===

) 9>/path/to/project/.deadf/cycle.flock
```

- `flock -n`: Non-blocking. If held, exit immediately. Zero wait, zero conflict.
- Lock released automatically when session exits (even on crash — OS handles it).
- Each project has its own `.deadf/cycle.flock`. Multiple projects don't interfere.

### Stale Lease Recovery

If a session hangs (process alive but stuck), the lease renewal mechanism detects it:

```yaml
# STATE.yaml cycle fields:
cycle:
  status: running
  started_at: "2026-01-30T03:30:00Z"
  session_key: "agent:main:cron:deadfish-mnemo"
  last_heartbeat_at: "2026-01-30T03:35:00Z"
```

**Inside flock, before claiming:**
1. If `cycle.status == running` AND `now - last_heartbeat_at > stale_timeout_min` → recover (reset to idle, log warning)
2. If `cycle.status == running` AND not stale → someone legit is working, but we couldn't get flock... (this case shouldn't happen since we're inside flock — it's a belt-and-suspenders check)

### Lease Renewal

Long-running actions update `last_heartbeat_at` at sub-step boundaries:

```
implement_task:
  1. Update last_heartbeat_at → NOW    (before dispatching to Codex)
  2. Dispatch to gpt-5.2-codex         (may take 20+ min for high reasoning)
  3. Update last_heartbeat_at → NOW    (after Codex returns)
  4. Read git state, update STATE.yaml
```

---

## Cycle Protocol

When triggered (by cron or manual), execute these steps in order:

### Step 0: GUARD

1. Acquire `flock -n` on `<project>/.deadf/cycle.flock`
   - If cannot acquire → exit silently (another session owns the cycle)
2. Read `cycle.status` from STATE.yaml:
   - `idle` → proceed to Step 1
   - `running` + stale (`now - last_heartbeat_at > stale_timeout_min`) → log recovery, reset to `idle`, proceed
   - `running` + not stale → release flock, exit (shouldn't happen inside flock, but safety check)
   - `complete`/`failed` → reset to `idle`, proceed
3. Check `phase`:
   - `needs_human` → post alert to Discord, release flock, exit
   - `complete` → post completion summary, release flock, exit
   - Any other → proceed

### Step 1: LOAD

Read these files:
```
STATE.yaml          — current pipeline state
POLICY.yaml         — mode behavior, thresholds, heartbeat config
OPS.md              — project-specific build/test/run commands (if present)
task.files_to_load  — files listed in STATE task.files_to_load (cap: <3000 tokens)
```

### Step 2: VALIDATE

1. Parse STATE.yaml. If unparseable → `phase: needs_human`, post alert, exit.
2. Generate cycle_id: `cycle-<iteration+1>-<8 random hex chars>`
3. Derive nonce from cycle_id:
   - `sha256(cycle_id.encode('utf-8')).hexdigest()[:6].upper()`
   - Format: exactly `^[0-9A-F]{6}$`
4. Claim cycle — write to STATE.yaml atomically:
   ```yaml
   cycle:
     id: <cycle_id>
     nonce: <derived_nonce>
     status: running
     started_at: <ISO-8601>
     session_key: <this session's key>
     last_heartbeat_at: <ISO-8601>
   ```
5. Check budgets:
   - Time: `now - budget.started_at >= max_hours` → `phase: needs_human`, alert, exit
   - Budget 75%: → warn per POLICY
   - Iterations: `iteration >= 200` → `phase: needs_human`, alert, exit

### Step 3: DECIDE

Read `phase` and `task.sub_step`. The action is **deterministic** — first matching row wins:

| # | Phase | Condition | Action |
|---|-------|-----------|--------|
| 1 | Any | Budget exceeded or state invalid | `escalate` |
| 2 | `execute` | `stuck_count >= stuck_threshold` AND `replan_attempted == true` | `escalate` |
| 3 | `execute` | `stuck_count >= stuck_threshold` AND `replan_attempted == false` | `replan_task` |
| 4 | `execute` | `sub_step: implement` + `last_result.ok == false` + `retry_count >= max_retries` | `rollback_and_escalate` |
| 5 | `execute` | `sub_step: implement` + `last_result.ok == false` + `retry_count < max_retries` | `retry_task` |
| 6 | `research` | — | `seed_docs` |
| 7 | `select-track` | No track selected | `pick_track` |
| 8 | `select-track` | Track selected, no spec | `create_spec` |
| 9 | `select-track` | Spec exists, no plan | `create_plan` |
| 10 | `execute` | `sub_step: null` or `generate` | `generate_task` |
| 11 | `execute` | `sub_step: implement` | `implement_task` |
| 12 | `execute` | `sub_step: verify` | `verify_task` |
| 13 | `execute` | `sub_step: reflect` | `reflect` |
| 14 | `complete` | — | `summarize` |

**One cycle = one action. No chaining.**

### Step 4: EXECUTE

Run the determined action. See [Action Specifications](#action-specifications).

### Step 5: RECORD

Update STATE.yaml atomically (see [State Write Protocol](#state-write-protocol)):
- `cycle.status`: `complete` or `failed`
- `cycle.finished_at`: ISO-8601
- `loop.iteration`: **always increment** (even on failure)
- `last_action`: action name
- `last_result`: outcome details
- Action-specific fields per action spec

### Step 6: REPORT

Post one-liner to Discord pipeline channel:

```
{emoji} #{iteration} | {action} | {project}:{task_id} | {details} | → {next_step}
```

Examples:
```
✅ #47 | generate_task | mnemo:tui-09 | TASK.md written | → implement
❌ #49 | verify_task | mnemo:tui-09 | FAIL: 2 tests broken | retry 1/3
🚨 #55 | escalate | mnemo:api-03 | 3x fail, rolled back | needs_human
🏁 #103 | summarize | mnemo | PROJECT COMPLETE: 5 tracks, 38 tasks
```

### Step 7: RELEASE

1. Set `cycle.status: idle` (if not already set to failed/needs_human)
2. flock released automatically on session exit

---

## Action Specifications

### `seed_docs` (research phase)

1. Read project files, understand codebase structure
2. Generate VISION.md and ROADMAP.md (consult GPT-5.2 via MCP)
3. Set `phase: select-track`

### `pick_track` (select-track phase)

1. Consult GPT-5.2 planner (via MCP) to select next track from `tracks_remaining`
2. Set `track.id`, `track.name`, `track.status: in-progress`

### `create_spec` / `create_plan` (select-track phase)

1. Consult GPT-5.2 planner (via MCP) for track spec/plan
2. Parse output with `extract_plan.py --nonce <nonce>`
3. On plan complete: set `phase: execute`, `task.sub_step: generate`

### `generate_task` (execute phase)

1. Dispatch to GPT-5.2 via MCP with layered prompt (orientation → objective → rules → guardrails)
2. Parse with `extract_plan.py --nonce <nonce>`
3. Write TASK.md from parsed plan
4. Update: `task.id`, `task.description`, `task.sub_step: implement`, `task.files_to_load`
5. On parse failure after retry: `CYCLE_FAIL`

### `implement_task` (execute phase)

1. **Idempotency check:** If `git log --oneline -1` matches current task ID → skip, set `sub_step: verify`
2. Update `last_heartbeat_at` (lease renewal before long operation)
3. Dispatch to gpt-5.2-codex via MCP:
   ```bash
   codex-mcp-call.sh --model gpt-5.2-codex --full-auto --cwd <project> "<implementation prompt>"
   ```
   For complex tasks: use `--model gpt-5.2-codex-high`
4. Update `last_heartbeat_at` (lease renewal after return)
5. Read results from git:
   ```bash
   commit_hash=$(git -C <project> rev-parse HEAD)
   files_changed=$(git -C <project> diff HEAD~1 --name-only)
   diff_lines=$(git -C <project> diff HEAD~1 --stat)
   ```
6. On success (new commit): set `task.sub_step: verify`
7. On failure (no commit): set `last_result.ok: false`

### `verify_task` (execute phase)

**Stage 1: Deterministic**
```bash
cd <project> && ./verify.sh
```
Output: JSON with `pass`, `checks`, `failures`. If `pass == false` → FAIL immediately.

**Stage 2: LLM (only if Stage 1 passes)**
- `DET:` prefixed criteria → auto-pass (covered by verify.sh)
- `LLM:` prefixed criteria → spawn one `sessions_spawn` sub-agent per criterion
- Each sub-agent produces a sentinel verdict block

**Stage 3: Combined**
```bash
echo '<responses_json>' | python3 build_verdict.py --nonce <nonce> --criteria AC1,AC2,...
```

| verify.sh | LLM | Result |
|-----------|-----|--------|
| FAIL | (not run) | **FAIL** |
| PASS | FAIL | **FAIL** |
| PASS | NEEDS_HUMAN | **pause** |
| PASS | PASS | **PASS** |
| PASS | parse failure | **NEEDS_HUMAN** |

On PASS: `sub_step: reflect`, update `last_cycle.*`, `last_result.ok: true`
On FAIL: increment `retry_count`, `sub_step: implement`, `last_result.ok: false`

### `reflect` (execute phase)

1. Update baselines:
   ```yaml
   last_good.commit: <HEAD>
   last_good.task_id: <current task>
   last_good.timestamp: <now>
   ```
2. Advance: more tasks → `sub_step: generate` | track done → `phase: select-track` | all done → `phase: complete`
3. Reset: `retry_count: 0`, `stuck_count: 0`, `replan_attempted: false`

### `retry_task` (execute phase)

1. Set `sub_step: implement`
2. Include failure context in next implementation prompt

### `replan_task` (execute phase — stuck recovery)

1. Set `replan_attempted: true`, reset `stuck_count: 0`, `retry_count: 0`
2. Set `sub_step: generate` (regenerate task from scratch)

### `rollback_and_escalate` (execute phase)

```bash
git stash                                        # if dirty
git checkout -b rescue-{run_id}-{task_id}        # preserve failed work
git checkout main
git reset --hard {last_good_commit}
```

Set `phase: needs_human`, post alert.

### `summarize` (complete phase)

Post completion summary to Discord. Set `phase: complete`.

### `escalate` (any phase)

Set `phase: needs_human`. Post alert with context.

---

## Sentinel DSL

### Plan Block (GPT-5.2 → extract_plan.py)

```
<<<PLAN:V1:NONCE={nonce}>>>
TASK_ID=auth-01-03
TITLE="Implement JWT refresh token rotation"
SUMMARY=
  Multi-line description here.
FILES:
- path=src/auth/jwt.ts action=modify rationale="Add refresh logic"
ACCEPTANCE:
- id=AC1 text="DET: All tests pass"
- id=AC2 text="LLM: Auth module exports refresh() method"
ESTIMATED_DIFF=120
<<<END_PLAN:NONCE={nonce}>>>
```

### Verdict Block (Sub-agent → build_verdict.py)

```
<<<VERDICT:V1:AC1:NONCE={nonce}>>>
ANSWER=YES
REASON="Criterion met: endpoint returns both tokens."
<<<END_VERDICT:AC1:NONCE={nonce}>>>
```

### Nonce Derivation

- `sha256(cycle_id.encode('utf-8')).hexdigest()[:6].upper()`
- Format: `^[0-9A-F]{6}$`
- Same nonce for entire cycle

### Rules

- One block per LLM response
- Sentinels on their own line
- Open nonce == close nonce == expected nonce
- One format-repair retry, then CYCLE_FAIL/NEEDS_HUMAN

---

## State Management

### STATE.yaml — Single Source of Truth

```yaml
project: mnemo
phase: execute                    # research | select-track | execute | complete | needs_human
mode: yolo                        # yolo | hybrid | interactive
_run_id: "run-2026-01-30-a1b2c3d4"

cycle:
  status: idle                    # idle | running | complete | failed
  id: null
  nonce: null
  started_at: null
  finished_at: null
  session_key: null               # owning session
  last_heartbeat_at: null         # lease renewal timestamp

loop:
  iteration: 0
  stuck_count: 0

track:
  id: null
  name: null
  status: null
  tasks_total: 0
  task_current: 0
  tracks_remaining: []
  tracks_completed: []

task:
  id: null
  description: null
  sub_step: null                  # generate | implement | verify | reflect
  retry_count: 0
  max_retries: 3
  replan_attempted: false
  files_to_load: []

last_action: null
last_result:
  ok: null
  details: null

last_good:
  commit: null
  task_id: null
  timestamp: null

last_cycle:
  commit_hash: null
  test_count: null
  diff_lines: null

budget:
  started_at: null
  max_hours: 24
```

### POLICY.yaml — Mode + Heartbeat Config

```yaml
modes:
  yolo:
    description: "Full autonomy. Pause only on stuck/failure."
    notifications:
      track_complete: silent
      task_complete: silent
      stuck: pause
      triple_fail_rollback: pause
      budget_75_percent: warn
      complete: summary
    approvals:
      new_track: false
      task_start: false

  hybrid:
    description: "Autonomous with human checkpoints at track boundaries."
    notifications:
      track_complete: notify
      new_track_starting: notify
      task_complete: silent
      stuck: pause
      triple_fail_rollback: pause
      budget_75_percent: warn
      complete: summary
    approvals:
      new_track: true
      task_start: false

  interactive:
    description: "Human approves each task."
    notifications:
      track_complete: notify
      new_track_starting: notify
      task_complete: notify
      stuck: pause
      triple_fail_rollback: pause
      budget_75_percent: warn
      complete: summary
    approvals:
      new_track: true
      task_start: true

escalation:
  stuck_threshold: 3
  max_retries: 3
  max_iterations: 200
  max_hours: 24

heartbeat:
  enabled: true
  cycle_interval_min: 3           # Cron fires every N minutes
  stale_timeout_min: 45           # Recover dead sessions after N min
  lease_renewal: true             # Update last_heartbeat_at between sub-steps
  discord_channel: null           # Set per project: "channel:<id>"
  status_format: oneliner         # oneliner | verbose | silent

rollback:
  authority: clawdbot
  trigger: "task.retry_count >= task.max_retries"

verification:
  format_repair_retries: 1
```

### State Write Protocol

**ALL STATE.yaml writes use flock + atomic rename:**

```bash
(
  flock -w 10 9 || { echo "FLOCK_FAIL"; exit 70; }
  tmp=$(mktemp "STATE.yaml.tmp.XXXXXX")
  yq --arg v "$value" ".$field = \$v" STATE.yaml > "$tmp"
  mv -f "$tmp" STATE.yaml
) 9>"$PROJECT/.deadf/cycle.flock"
```

**Owner verification:** Before any state update during a cycle, assert `cycle.session_key == this session`. If mismatch → abort (another session took over).

---

## Model Dispatch

| Purpose | Method | Notes |
|---------|--------|-------|
| Planning | `codex-mcp-call.sh --model gpt-5.2 --sandbox danger-full-access` | No timeout. Let it think. |
| Implementation | `codex-mcp-call.sh --model gpt-5.2-codex --full-auto --cwd <project>` | Full filesystem access |
| Complex impl | `codex-mcp-call.sh --model gpt-5.2-codex-high --full-auto --cwd <project>` | Parsers, state machines |
| LLM Verification | `sessions_spawn` (Opus 4.5 sub-agent) | One per LLM: criterion |
| Orchestration | This session (Opus 4.5) | Reads skill, follows protocol |

**Wrapper script:** `/tank/dump/AGENTS/junior/scripts/codex-mcp-call.sh`

**Critical:** Never set timeouts on GPT-5.2 calls. It thinks slowly. That's by design.

---

## Stuck Detection

| Trigger | Condition | Action |
|---------|-----------|--------|
| Stuck (first) | `stuck_count >= stuck_threshold` + `replan_attempted == false` | `replan_task` |
| Stuck (after replan) | `stuck_count >= stuck_threshold` + `replan_attempted == true` | `escalate` |
| Budget time | `elapsed >= max_hours` | `escalate` |
| Budget iterations | `iteration >= 200` | `escalate` |
| 3x task failure | `retry_count >= max_retries` | `rollback_and_escalate` |
| State invalid | Unparseable STATE.yaml | `escalate` |
| Stale session | `now - last_heartbeat_at > stale_timeout_min` | Auto-recover, log warning |

---

## Safety Constraints

1. **Never write source code** — delegate to gpt-5.2-codex via MCP
2. **Never override verifier verdicts** — verify.sh FAIL = FAIL, period
3. **Deterministic wins** — verify.sh always takes precedence over LLM judgment
4. **Conservative default** — verify.sh PASS + LLM FAIL = FAIL
5. **One cycle = one action** — never chain
6. **Atomic state updates** — flock + temp + mv
7. **Nonce integrity** — every sentinel parse uses the cycle's nonce
8. **Owner verification** — assert session_key before every state write
9. **No secrets in files** — ever
10. **Escalate when uncertain** — `needs_human` is always safe

---

## Project Structure

```
<project>/
├── .deadf/
│   ├── logs/              # Cycle logs (auto-rotated, max 50)
│   └── cycle.flock        # Filesystem lock (replaces ralph.lock)
├── STATE.yaml             # Pipeline state
├── POLICY.yaml            # Mode + heartbeat config
├── OPS.md                 # Project-specific build/test commands
├── VISION.md              # What we're building
├── ROADMAP.md             # How we get there
├── TASK.md                # Current task spec
├── extract_plan.py        # Sentinel plan parser
├── build_verdict.py       # Sentinel verdict parser
├── verify.sh              # Deterministic verifier
└── src/, tests/, etc.     # Actual project code
```

---

## Getting Started

### Initialize a New Project

1. Create project directory:
   ```bash
   mkdir -p /tank/dump/DEV/<project>
   cd /tank/dump/DEV/<project>
   git init && mkdir -p .deadf/logs
   ```

2. Copy pipeline files:
   ```bash
   cp /tank/dump/DEV/deadfish-pipeline/{extract_plan.py,build_verdict.py,verify.sh,POLICY.yaml} .
   chmod +x verify.sh
   ```

3. Create STATE.yaml:
   ```yaml
   project: <project-name>
   phase: research
   mode: yolo
   _run_id: "run-$(date +%Y-%m-%d)-$(head -c4 /dev/urandom | xxd -p)"
   cycle:
     status: idle
   loop:
     iteration: 0
     stuck_count: 0
   budget:
     started_at: "<ISO-8601 now>"
     max_hours: 24
   ```

4. Configure POLICY.yaml heartbeat section:
   ```yaml
   heartbeat:
     enabled: true
     cycle_interval_min: 3
     stale_timeout_min: 45
     discord_channel: "channel:<your-pipeline-channel-id>"
   ```

5. Commit initial state:
   ```bash
   git add STATE.yaml POLICY.yaml extract_plan.py build_verdict.py verify.sh
   git commit -m "init: deadf(ish) pipeline v3.0.0"
   ```

### Activation

Create the cron job to start the pipeline:

```
cron add:
  name: "deadfish-<project>"
  schedule: "*/3 * * * *" (every 3 min)
  sessionTarget: isolated
  payload:
    message: "🐟 DEADFISH CYCLE: Project '<project>' at /tank/dump/DEV/<project>/
              Read the deadfish skill, then execute ONE pipeline cycle.
              Acquire flock, read STATE.yaml, run one action, update state, post status."
    deliver: true
    channel: discord
    to: "channel:<pipeline-channel-id>"
```

### Deactivation

```
cron update: enabled: false
```

Or set `phase: needs_human` in STATE.yaml (cron fires but exits immediately).

### Resume After `needs_human`

1. Read STATE.yaml (`last_action`, `last_result.details`)
2. Fix the issue
3. Set `phase` back to appropriate value
4. Set `cycle.status: idle`
5. Re-enable cron job (if disabled)

### Multiple Projects

Each project gets its own cron job. They run independently — different STATE.yaml, different flock files:

```
deadfish-mnemo     → */3 * * * *  → /tank/dump/DEV/mnemo/
deadfish-dealio    → */5 * * * *  → /tank/dump/DEV/dealio/
```

---

## Discord Status Format

### Per-Cycle One-Liner
```
✅ #47 | generate_task | mnemo:tui-09 | TASK.md written | → implement
✅ #48 | implement_task | mnemo:tui-09 | 3 files, +87 lines | → verify
❌ #49 | verify_task | mnemo:tui-09 | FAIL: 2 tests broken | retry 1/3
✅ #50 | implement_task | mnemo:tui-09 | retry: fixed assertions | → verify
✅ #51 | verify_task | mnemo:tui-09 | PASS: 4/4 AC met | → reflect
✅ #52 | reflect | mnemo:tui-09 | baseline updated | → generate (tui-10)
```

### Transitions
```
🎯 Track complete: mnemo:tui (9/9 tasks)
🚀 New track: mnemo:api (6 tasks planned)
🏁 PROJECT COMPLETE: mnemo | 5 tracks, 38 tasks, 103 cycles
```

### Alerts
```
🚨 STUCK: mnemo:api-03 | 3 cycles no progress | needs_human
🔄 ROLLBACK: mnemo:api-03 | 3x fail | rescue: rescue-run001-api03
⏰ BUDGET 75%: mnemo | 18h / 24h elapsed
⚠️ STALE RECOVERY: session died mid-cycle | auto-recovered
```

---

*Skill version: 3.0.0-heartbeat — deadf(ish) v2.4.2 adapted for Clawdbot cron-driven execution.* 🐟
