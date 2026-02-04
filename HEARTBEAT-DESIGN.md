# Heartbeat-Driven deadf(ish) Pipeline — Design Doc

> Replaces `ralph.sh` external loop with Clawdbot's native cron system.
> Each cycle = fresh isolated session. STATE.yaml = continuity.

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────┐
│                  Clawdbot Gateway                    │
│                                                      │
│  ┌──────────┐    fires every     ┌───────────────┐  │
│  │ Cron Job │───── 3-5 min ─────▶│ Isolated      │  │
│  │ (driver) │                    │ Session       │  │
│  └──────────┘                    │               │  │
│                                  │ 1. Acquire    │  │
│                                  │    flock      │  │
│  ┌──────────┐                    │ 2. Read       │  │
│  │ Discord  │◀── status ────────│    STATE.yaml │  │
│  │ #pipeline│    one-liner      │ 3. ONE action │  │
│  └──────────┘                    │ 4. Update     │  │
│                                  │    state      │  │
│                                  │ 5. Release    │  │
│                                  │    flock      │  │
│                                  └───────────────┘  │
│                                         │           │
│                    ┌────────────────────┼──────┐    │
│                    ▼                    ▼      ▼    │
│              ┌──────────┐   ┌──────────┐ ┌──────┐  │
│              │ GPT-5.2  │   │GPT-5.2   │ │Opus  │  │
│              │ (planner)│   │Codex     │ │4.5   │  │
│              │ via MCP  │   │(builder) │ │(rev) │  │
│              └──────────┘   │via MCP   │ │spawn │  │
│                             └──────────┘ └──────┘  │
└─────────────────────────────────────────────────────┘
```

### What Replaces What

| ralph.sh responsibility | Heartbeat equivalent |
|------------------------|---------------------|
| Tight poll loop (5-10s) | Cron tick every 3-5 min |
| PID lockfile (.deadf/ralph.lock) | `flock` on STATE.yaml.flock |
| Cycle timeout (600s) | Stale lease detection (configurable, default 45min) |
| Cycle kick (`DEADF_CYCLE <id>`) | Cron payload message |
| Status polling (STATE.yaml) | Discord one-liner per cycle |
| Restart after crash | Cron auto-fires next tick |
| Max iterations (200) | Budget check inside cycle |
| `needs_human` detection | Discord alert + cron skips |

---

## Concurrency Guard

### The Problem (TOCTOU Race)

Two cron ticks could both read `cycle.status: idle` and both claim ownership.
`temp + mv` is atomic for the file write but NOT for read-decide-write.

### The Solution: `flock`

Every cron-triggered session wraps the ENTIRE cycle in a filesystem lock:

```bash
(
  flock -n 9 || exit 0    # non-blocking: if locked, exit silently (another session owns it)

  # === CRITICAL SECTION: entire cycle ===
  # 1. Read STATE.yaml
  # 2. Check if work needed
  # 3. Claim (write status: running)
  # 4. Execute one action
  # 5. Update state (status: idle/complete/failed)
  # === END CRITICAL SECTION ===

) 9>/path/to/project/.deadf/cycle.flock
```

**Key:** `flock -n` (non-blocking). If the lock is held, the new tick exits immediately — zero wait, zero conflict. The lock is released automatically when the subshell exits (even on crash).

### Stale Lease Recovery

If a session crashes while holding `flock` (process dies), the OS releases the lock automatically. Next cron tick acquires it normally.

If a session hangs (process alive but stuck), we add a belt-and-suspenders check:

```yaml
# In STATE.yaml:
cycle:
  status: running | idle | complete | failed
  started_at: "2026-01-30T03:30:00Z"
  session_key: "agent:main:cron:deadfish-mnemo"
  last_heartbeat_at: "2026-01-30T03:35:00Z"  # updated between sub-steps
```

```yaml
# In POLICY.yaml:
heartbeat:
  cycle_interval_min: 3          # cron fires every N minutes
  stale_timeout_min: 45          # treat as dead if no heartbeat_at update in N min
  lease_renewal: true            # update last_heartbeat_at between sub-steps
```

**Stale check logic (inside flock):**
1. If `cycle.status == running` AND `now - last_heartbeat_at > stale_timeout_min`:
   - Log: "Recovering stale cycle from session {session_key}"
   - Reset `cycle.status: idle`
   - Proceed with normal cycle
2. If `cycle.status == running` AND NOT stale:
   - Exit (legitimate work in progress)

### Lease Renewal

Long-running actions (GPT-5.2-high planning, Codex implementation) should update `last_heartbeat_at` at sub-step boundaries:

```
implement_task:
  1. Update last_heartbeat_at → NOW           (before dispatching to Codex)
  2. Dispatch to gpt-5.2-codex via MCP        (may take 20+ min)
  3. Update last_heartbeat_at → NOW           (after Codex returns)
  4. Read git state, update STATE.yaml
```

This prevents false stale detection during legitimate long operations.

---

## Cron Job Configuration

### Payload Template

```json
{
  "name": "deadfish-{project}",
  "schedule": {
    "kind": "cron",
    "expr": "*/3 * * * *",
    "tz": "America/Toronto"
  },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "🐟 DEADFISH CYCLE: Run ONE pipeline cycle for project '{project}'.\n\nProject path: /tank/dump/DEV/{project}/\nSkill: deadfish-pipeline\n\n## Instructions\n1. Read the deadfish skill (SKILL.md)\n2. Acquire flock on {project}/.deadf/cycle.flock (non-blocking, exit if held)\n3. Read STATE.yaml — determine phase + sub_step\n4. If phase == needs_human → post alert to #{channel}, exit\n5. Execute ONE action per the skill's DECIDE table\n6. Update STATE.yaml atomically\n7. Post one-liner status to #{channel}\n8. Release flock (automatic on session end)",
    "deliver": true,
    "channel": "discord",
    "to": "channel:{pipeline_channel_id}"
  }
}
```

### Activation / Deactivation

**Start pipeline:** Create the cron job
```
cron add → job starts firing every 3 min
```

**Pause pipeline:** Disable the cron job (or set `phase: needs_human` in STATE.yaml)
```
cron update → enabled: false
```

**Resume after needs_human:**
1. Fix the issue (check STATE.yaml → last_result.details)
2. Set `phase` back to appropriate value
3. Set `cycle.status: idle`
4. Re-enable cron job

### Multiple Projects

Each project gets its own cron job. They don't interfere — different STATE.yaml files, different flock files.

```
deadfish-mnemo     → */3 * * * * → /tank/dump/DEV/mnemo/
deadfish-dealio    → */5 * * * * → /tank/dump/DEV/dealio/
```

---

## Discord Status Reporting

### Per-Cycle One-Liner

Posted to the project's pipeline channel after each cycle:

```
✅ #47 | generate_task | mnemo:tui-09 | TASK.md written | → implement
✅ #48 | implement_task | mnemo:tui-09 | 3 files, +87 lines | → verify
❌ #49 | verify_task | mnemo:tui-09 | FAIL: 2 tests broken | retry 1/3
✅ #50 | implement_task | mnemo:tui-09 | retry: fixed assertions | → verify
✅ #51 | verify_task | mnemo:tui-09 | PASS: 4/4 AC met | → reflect
✅ #52 | reflect | mnemo:tui-09 | baseline updated | → generate (tui-10)
```

Format: `{emoji} #{iteration} | {action} | {project}:{task_id} | {details} | → {next_step}`

### Track/Phase Transitions

```
🎯 Track complete: mnemo:tui (9/9 tasks) | → select next track
🚀 New track: mnemo:api (6 tasks planned)
🏁 PROJECT COMPLETE: mnemo | 5 tracks, 38 tasks, 103 cycles
```

### Alerts (Always Delivered)

```
🚨 STUCK: mnemo:api-03 | 3 cycles no progress | needs_human
🔄 ROLLBACK: mnemo:api-03 | 3x fail | rescue branch: rescue-run001-api03
⏰ BUDGET 75%: mnemo | 18h / 24h elapsed
⚠️ STALE RECOVERY: mnemo | session agent:main:cron:xyz died mid-cycle | auto-recovered
```

---

## Cycle Protocol (Clawdbot Adaptation)

Same 6-step protocol as CLAUDE.md, adapted for Clawdbot tools:

### Step 0: GUARD (new)

```
1. flock -n on .deadf/cycle.flock → exit if held
2. Check cycle.status:
   - idle → proceed
   - running + stale → recover + proceed
   - running + not stale → release flock, exit
   - needs_human → post alert, release flock, exit
3. Claim: write status=running, started_at=now, session_key=<this session>
```

### Steps 1-6: Same as CLAUDE.md

| Step | Action | Clawdbot Adaptation |
|------|--------|-------------------|
| LOAD | Read STATE.yaml + POLICY.yaml | Same |
| VALIDATE | Parse state, derive nonce, check budgets | Same |
| DECIDE | Deterministic action lookup | Same (unchanged table) |
| EXECUTE | Dispatch to appropriate worker | Model dispatch via MCP + sessions_spawn |
| RECORD | Update STATE.yaml atomically | Same + update last_heartbeat_at |
| REPLY | Status output | Discord one-liner (replaces stdout) |

### Step 7: RELEASE (new)

```
1. Set cycle.status: idle (or complete/failed)
2. Post Discord one-liner
3. flock released automatically on session end
```

---

## Model Dispatch (Clawdbot)

| Purpose | Method | Notes |
|---------|--------|-------|
| Planning (GPT-5.2) | `codex-mcp-call.sh --model gpt-5.2 --sandbox danger-full-access` | No timeout. Let it cook. |
| Implementation (GPT-5.2-Codex) | `codex-mcp-call.sh --model gpt-5.2-codex --full-auto --cwd <project>` | Full filesystem access |
| Implementation (complex) | Same + `--model gpt-5.2-codex-high` | For parsers, state machines |
| LLM Verification | `sessions_spawn` (Claude Opus 4.5 sub-agent) | One per AC criterion |
| Orchestration | Native Clawdbot session (this session) | Reads skill, follows protocol |

### Key Differences from CLI Version

| CLI (CLAUDE.md) | Clawdbot (Heartbeat) |
|-----------------|---------------------|
| `codex exec -m gpt-5.2` | `codex-mcp-call.sh` (MCP primary) |
| Claude Code Task tool | `sessions_spawn` |
| `claude --print --continue` | Cron isolated session |
| stdout → ralph.sh | Discord channel message |
| `.deadf/notifications/*.md` | Discord alerts (direct) |
| `CLAUDE_CODE_TASK_LIST_ID` | Not needed (state in YAML) |

---

## Idempotency & Crash Safety

### Non-Idempotent Side Effects

GPT-5.2 raised this concern. Solutions per action:

| Action | Side Effect | Idempotency Strategy |
|--------|-------------|---------------------|
| generate_task | Writes TASK.md | Overwrite is safe (same input = same output) |
| implement_task | Git commits | Check `git log --oneline -1` — if last commit matches task ID, skip re-implementation |
| verify_task | Spawns sub-agents | verify.sh is deterministic; re-running is safe |
| reflect | Updates baselines | Idempotent (same values written) |
| rollback | Resets git state | Check if already on `main` at `last_good.commit` before acting |

### Owner Verification

Every state write asserts ownership:

```python
# Before writing:
if state.cycle.session_key != MY_SESSION_KEY:
    # Someone else owns this cycle — abort
    log("Owner mismatch: expected {MY_SESSION_KEY}, found {state.cycle.session_key}")
    exit(1)
```

### Partial State Corruption

If STATE.yaml is unparseable (crash mid-write despite atomic mv):
1. Check for `.tmp.XXXXXX` files → use as recovery source
2. If no temp files → `phase: needs_human`, alert Fred
3. Never "fix" corrupt state automatically — too dangerous

---

## POLICY.yaml Additions

```yaml
# --- Heartbeat Configuration ---
heartbeat:
  enabled: true                    # Master switch
  cycle_interval_min: 3            # Cron fires every N minutes
  stale_timeout_min: 45            # Force-recover after N min with no heartbeat
  lease_renewal: true              # Update last_heartbeat_at between sub-steps
  discord_channel: "channel:xxx"   # Pipeline status channel
  status_format: "oneliner"        # oneliner | verbose | silent
  alert_on_needs_human: true       # Post alert when pipeline pauses
  alert_on_stale_recovery: true    # Post alert when recovering dead session
```

## STATE.yaml Additions

```yaml
# --- Cycle Lock Fields ---
cycle:
  status: idle                     # idle | running | complete | failed
  id: null                         # Current cycle ID
  nonce: null                      # Derived nonce
  started_at: null                 # ISO-8601
  finished_at: null                # ISO-8601
  session_key: null                # Which session owns this cycle
  last_heartbeat_at: null          # Lease renewal timestamp
```

---

## Migration Path

### From ralph.sh to Heartbeat

1. Stop ralph.sh (`kill <pid>` or let it finish current cycle)
2. Ensure `cycle.status: idle` in STATE.yaml
3. Add heartbeat config to POLICY.yaml
4. Create cron job via Clawdbot
5. Create Discord #pipeline channel
6. Pipeline is now heartbeat-driven

### Keeping ralph.sh as Manual Trigger

ralph.sh can still be used for single-cycle debugging:
```bash
./ralph.sh /path/to/project --once    # Run exactly one cycle, then exit
```

This doesn't conflict with cron — flock prevents concurrent execution.

---

## FAQ

**Q: What if a cycle takes longer than the cron interval?**
A: `flock -n` makes new ticks exit immediately if a cycle is running. No conflict.

**Q: What if Clawdbot itself restarts mid-cycle?**
A: Session dies → flock released by OS → next tick sees stale state → recovers.

**Q: Can I run multiple projects simultaneously?**
A: Yes. Each project has its own flock file and STATE.yaml. Independent cron jobs.

**Q: How do I stop the pipeline?**
A: Disable the cron job, OR set `phase: needs_human` in STATE.yaml.

**Q: How do I change the cycle speed?**
A: Update the cron expression. `*/3` = 3 min, `*/5` = 5 min, `*/1` = 1 min (aggressive).

**Q: What about token costs?**
A: Each cron tick = one isolated session. If `cycle.status: idle` and no work needed (e.g., `phase: needs_human`), the session reads state, posts nothing, exits. Minimal tokens consumed.

---

*Design version: 3.0.0-heartbeat — Adapts deadf(ish) v2.4.2 for Clawdbot cron-driven execution.*
