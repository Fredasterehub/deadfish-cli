# State Locking (auto-loaded)

Shared-lock discipline
- All STATE.yaml writers MUST hold an exclusive flock on `STATE.yaml.flock`.
- Use bounded wait: `flock -w 5`. On lock failure: treat as cycle failure and escalate.

Atomic R-M-W pattern
- Always perform read → compute → temp write → mv while holding the lock.
- Never write partial state; never edit STATE.yaml in place.
- Required pattern:
  (
    flock -w 5 9 || exit 70
    tmp=$(mktemp "${STATE_FILE}.tmp.XXXXXX")
    yq --arg v "$value" ".$field = \$v" "$STATE_FILE" > "$tmp"
    mv -f "$tmp" "$STATE_FILE"
  ) 9>"${STATE_FILE}.flock"

Nonce and timestamp writes
- The nonce and cycle timestamps are written only during VALIDATE and RECORD.

Dual-lock model
- Process lock: `.deadf/cron.lock` is held by the launcher for full runtime.
- State lock: `STATE.yaml.flock` is held by the orchestrator for atomic state updates.

Lock timeout behavior
- If lock acquisition fails, set `phase: needs_human`, emit notification, reply `CYCLE_FAIL`.
