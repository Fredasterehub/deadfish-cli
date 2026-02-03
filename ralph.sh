#!/bin/bash
# deadf(ish) Pipeline — ralph.sh (Loop Controller)
# Architecture: v2.4.2 (launcher-unified)
#
# Ralph is the mechanical loop controller. He kicks cycles, watches state,
# enforces timeouts, manages locks, rotates logs. He never thinks, never
# decides, never plans. Purely mechanical.
#
# Write permissions (STATE.yaml):
#   phase        → "needs_human" ONLY
#   cycle.status → "timed_out" ONLY
#   Everything else belongs to the Orchestrator.
#
# Usage: ralph.sh <project_path> [mode]

set -uo pipefail

# ── Arguments ──────────────────────────────────────────────────────────────
PROJECT_PATH="${1:?Usage: ralph.sh <project_path> [mode]}"
MODE="${2:-yolo}"

# ── Configuration ──────────────────────────────────────────────────────────
CYCLE_TIMEOUT="${RALPH_TIMEOUT:-600}"
POLL_INTERVAL="${RALPH_POLL:-15}"
LOG_DIR="$PROJECT_PATH/.deadf/logs"
LOCK_FILE="$PROJECT_PATH/.deadf/ralph.lock"
STATE_FILE="$PROJECT_PATH/.deadf/state/STATE.yaml"
STATE_LOCK_FILE="${STATE_FILE}.flock"
KICK_SCRIPT="$PROJECT_PATH/.deadf/bin/kick.sh"
MAX_LOG_FILES="${RALPH_MAX_LOGS:-50}"
ROTATE_LOGS="${RALPH_ROTATE_LOGS:-1}"
DISPATCH_TIMEOUT="${RALPH_DISPATCH_TIMEOUT:-$CYCLE_TIMEOUT}"
STATE_LOCK_TIMEOUT=5
STATE_UPDATE_RETRIES=3

# ── Validate Numeric Config ────────────────────────────────────────────────
[[ "$CYCLE_TIMEOUT" =~ ^[0-9]+$ ]]  || { echo "[ralph] ERROR: RALPH_TIMEOUT must be a positive integer, got: $CYCLE_TIMEOUT" >&2; exit 1; }
[[ "$CYCLE_TIMEOUT" -ge 1 ]]        || { echo "[ralph] ERROR: RALPH_TIMEOUT must be ≥1, got: $CYCLE_TIMEOUT" >&2; exit 1; }
[[ "$POLL_INTERVAL" =~ ^[0-9]+$ ]]  || { echo "[ralph] ERROR: RALPH_POLL must be a positive integer, got: $POLL_INTERVAL" >&2; exit 1; }
[[ "$POLL_INTERVAL" -ge 1 ]]        || { echo "[ralph] ERROR: RALPH_POLL must be ≥1, got: $POLL_INTERVAL" >&2; exit 1; }
[[ "$MAX_LOG_FILES" =~ ^[0-9]+$ ]]    || { echo "[ralph] ERROR: RALPH_MAX_LOGS must be a positive integer, got: $MAX_LOG_FILES" >&2; exit 1; }
[[ "$MAX_LOG_FILES" -ge 1 ]]           || { echo "[ralph] ERROR: RALPH_MAX_LOGS must be ≥1, got: $MAX_LOG_FILES" >&2; exit 1; }
[[ "$ROTATE_LOGS" =~ ^[0-9]+$ ]]      || { echo "[ralph] ERROR: RALPH_ROTATE_LOGS must be 0 or 1, got: $ROTATE_LOGS" >&2; exit 1; }
[[ "$ROTATE_LOGS" -eq 0 || "$ROTATE_LOGS" -eq 1 ]] || { echo "[ralph] ERROR: RALPH_ROTATE_LOGS must be 0 or 1, got: $ROTATE_LOGS" >&2; exit 1; }
[[ "$DISPATCH_TIMEOUT" =~ ^[0-9]+$ ]] || { echo "[ralph] ERROR: RALPH_DISPATCH_TIMEOUT must be a positive integer, got: $DISPATCH_TIMEOUT" >&2; exit 1; }
[[ "$DISPATCH_TIMEOUT" -ge 1 ]]        || { echo "[ralph] ERROR: RALPH_DISPATCH_TIMEOUT must be ≥1, got: $DISPATCH_TIMEOUT" >&2; exit 1; }

# ── Preflight ──────────────────────────────────────────────────────────────
[[ -d "$PROJECT_PATH" ]] || { echo "[ralph] ERROR: Project path does not exist: $PROJECT_PATH" >&2; exit 1; }
[[ -f "$STATE_FILE" ]]   || { echo "[ralph] ERROR: STATE.yaml not found: $STATE_FILE" >&2; exit 1; }
[[ -x "$KICK_SCRIPT" ]]  || { echo "[ralph] ERROR: kick.sh not found or not executable: $KICK_SCRIPT" >&2; exit 1; }

mkdir -p "$LOG_DIR" || { echo "[ralph] ERROR: Cannot create log dir: $LOG_DIR" >&2; exit 1; }

command -v yq &>/dev/null       || { echo "[ralph] ERROR: yq required but not found" >&2; exit 1; }
# Verify mikefarah/yq v4+ (required for -r and expression syntax)
if ! yq --version 2>/dev/null | grep -qE 'version v?4\.'; then
    echo "[ralph] ERROR: yq v4.x required (mikefarah/yq). Found: $(yq --version 2>/dev/null || echo 'unknown')" >&2
    exit 1
fi
command -v pgrep &>/dev/null    || { echo "[ralph] ERROR: pgrep required but not found" >&2; exit 1; }
command -v stat &>/dev/null     || { echo "[ralph] ERROR: stat required but not found" >&2; exit 1; }
command -v flock &>/dev/null    || { echo "[ralph] ERROR: flock required but not found" >&2; exit 1; }
command -v mktemp &>/dev/null   || { echo "[ralph] ERROR: mktemp required but not found" >&2; exit 1; }

if command -v timeout &>/dev/null; then
    TIMEOUT_CMD="timeout"
elif command -v gtimeout &>/dev/null; then
    TIMEOUT_CMD="gtimeout"
    echo "[ralph] INFO: Using gtimeout fallback (gtimeout)" >&2
else
    echo "[ralph] ERROR: timeout (or gtimeout) required but not found" >&2
    exit 1
fi

STAT_STYLE=""
if stat -c '%a' "$STATE_FILE" >/dev/null 2>&1; then
    STAT_STYLE="gnu"
elif stat -f '%Lp' "$STATE_FILE" >/dev/null 2>&1; then
    STAT_STYLE="bsd"
else
    echo "[ralph] ERROR: stat does not support -c '%a' (GNU) or -f '%Lp' (BSD). Cannot preserve permissions safely." >&2
    exit 1
fi

# ── Logging ────────────────────────────────────────────────────────────────
log() { echo "[ralph] $(date -u -Iseconds) $*"; }
log_err() { echo "[ralph] $(date -u -Iseconds) ERROR: $*" >&2; }

stat_perms() {
    case "$STAT_STYLE" in
        gnu) stat -c '%a' "$1" ;;
        bsd) stat -f '%Lp' "$1" ;;
        *) return 1 ;;
    esac
}

# ── Lock Management ───────────────────────────────────────────────────────
# Lockfile held by flock for the lifetime of this process.

LOCK_FD=""

acquire_lock() {
    exec {LOCK_FD}> "$LOCK_FILE" || { log_err "Cannot open lock file: $LOCK_FILE"; exit 1; }
    if ! flock -n "$LOCK_FD"; then
        log "Another instance running. Exiting."
        exit 1
    fi
    printf '%s %s\n' "$$" "$(date -u -Iseconds)" >&"$LOCK_FD" || true
}

release_lock() {
    if [[ -n "${LOCK_FD:-}" ]]; then
        flock -u "$LOCK_FD" 2>/dev/null || true
        exec {LOCK_FD}>&- || true
        LOCK_FD=""
    fi
}

# ── Signal Handling ────────────────────────────────────────────────────────
SHUTTING_DOWN=0

collect_descendants() {
    local root_pid="$1"
    local -a queue next
    local depth=0
    local max_depth=6
    queue=("$root_pid")
    while [[ ${#queue[@]} -gt 0 && "$depth" -lt "$max_depth" ]]; do
        next=()
        for pid in "${queue[@]}"; do
            while IFS= read -r child; do
                [[ -n "$child" ]] || continue
                echo "$child"
                next+=("$child")
            done < <(pgrep -P "$pid" 2>/dev/null || true)
        done
        queue=("${next[@]}")
        depth=$((depth + 1))
    done
}

cleanup() {
    if [[ "$SHUTTING_DOWN" -eq 1 ]]; then
        return
    fi
    SHUTTING_DOWN=1
    log "Signal received. Shutting down gracefully."
    # Collect descendants to avoid orphaned timeout/dispatch children
    local descendants
    descendants="$(collect_descendants "$$")"
    if [[ -n "$descendants" ]]; then
        while IFS= read -r pid; do
            [[ -n "$pid" ]] || continue
            kill -TERM "$pid" 2>/dev/null || true
        done <<< "$descendants"
    fi
    # Bounded wait for children to exit (max 5 seconds)
    local _wait_count=0
    while [[ $_wait_count -lt 5 ]] && pgrep -P $$ &>/dev/null; do
        sleep 1
        _wait_count=$((_wait_count + 1))
    done
    # Force-kill any stragglers (including re-parented descendants)
    local remaining
    remaining="$descendants
$(collect_descendants "$$")"
    if [[ -n "$remaining" ]]; then
        while IFS= read -r pid; do
            [[ -n "$pid" ]] || continue
            if kill -0 "$pid" 2>/dev/null; then
                kill -KILL "$pid" 2>/dev/null || true
            fi
        done <<< "$remaining"
        sleep 0.5
    fi
    release_lock
    log "Shutdown complete."
    exit 130
}

on_exit() {
    local exit_code=$?
    release_lock
    exit "$exit_code"
}

trap cleanup INT TERM HUP QUIT
trap on_exit EXIT

# ── STATE.yaml Helpers ─────────────────────────────────────────────────────
read_field() {
    yq -r ".$1 // \"unknown\"" "$STATE_FILE" 2>/dev/null || echo "unknown"
}

get_iteration()    { read_field "loop.iteration"; }
get_phase()        { read_field "phase"; }
get_cycle_status() { read_field "cycle.status"; }
get_max_iter()     { read_field "loop.max_iterations"; }

# Ralph may ONLY set these specific values:
# Uses atomic temp+rename + shared flock to avoid race conditions with orchestrator writes.
update_state_field() {
    local field="$1"
    local value="$2"
    local attempt
    local tmp
    if ! { [[ "$field" == "phase" && "$value" == "needs_human" ]] \
        || [[ "$field" == "cycle.status" && "$value" == "timed_out" ]]; }; then
        log_err "Refusing unauthorized state write: ${field}=${value}"
        return 1
    fi
    for ((attempt=1; attempt<=STATE_UPDATE_RETRIES; attempt++)); do
        tmp=$(mktemp "${STATE_FILE}.ralph.tmp.XXXXXX") || {
            log_err "FAILED to create temp file for STATE.yaml update (attempt ${attempt}/${STATE_UPDATE_RETRIES})"
            sleep 0.2
            continue
        }
        if (
            flock -w "$STATE_LOCK_TIMEOUT" 9 || {
                log_err "Cannot acquire lock on STATE.yaml (attempt ${attempt}/${STATE_UPDATE_RETRIES})"
                exit 10
            }
            local orig_perms
            orig_perms=$(stat_perms "$STATE_FILE" 2>/dev/null) || orig_perms=""
            if ! yq --arg value "$value" ".${field} = \$value" "$STATE_FILE" > "$tmp" 2>/dev/null; then
                log_err "FAILED to write ${field}=${value} to STATE.yaml (attempt ${attempt}/${STATE_UPDATE_RETRIES})"
                rm -f "$tmp"
                exit 11
            fi
            if ! mv -f "$tmp" "$STATE_FILE"; then
                log_err "FAILED to mv tmp file for ${field}=${value} (attempt ${attempt}/${STATE_UPDATE_RETRIES})"
                rm -f "$tmp"
                exit 12
            fi
            [[ -n "$orig_perms" ]] && chmod "$orig_perms" "$STATE_FILE" 2>/dev/null || true
        ) 9>"$STATE_LOCK_FILE"; then
            return 0
        fi
        rm -f "$tmp"
        sleep 0.2
    done
    return 1
}

set_phase_needs_human() {
    if ! update_state_field "phase" "needs_human"; then
        log_err "FAILED to update phase=needs_human after ${STATE_UPDATE_RETRIES} attempts"
        return 1
    fi
}

set_cycle_timed_out() {
    if ! update_state_field "cycle.status" "timed_out"; then
        log_err "FAILED to update cycle.status=timed_out after ${STATE_UPDATE_RETRIES} attempts"
        return 1
    fi
}

require_state_update() {
    local what="$1"
    shift
    if ! "$@"; then
        log_err "State update failed: ${what}"
        if [[ "$what" != "phase=needs_human" ]]; then
            set_phase_needs_human 2>/dev/null || log_err "Also failed to set phase=needs_human"
        fi
        release_lock
        exit 1
    fi
}

# ── State Validation ───────────────────────────────────────────────────────
validate_state() {
    if ! yq '.' "$STATE_FILE" > /dev/null 2>&1; then
        log_err "STATE.yaml is unparseable"
        set_phase_needs_human 2>/dev/null || true
        release_lock
        exit 1
    fi
    local phase
    local cycle_status
    phase=$(read_field "phase")
    cycle_status=$(read_field "cycle.status")
    case "$phase" in
        research|select-track|execute|complete|needs_human) ;;
        *) log_err "STATE.yaml has invalid phase or cycle.status (phase=$phase, cycle.status=$cycle_status)"
           set_phase_needs_human 2>/dev/null || true
           release_lock
           exit 1
           ;;
    esac
    case "$cycle_status" in
        idle|running|complete|failed|timed_out) ;;
        *) log_err "STATE.yaml has invalid phase or cycle.status (phase=$phase, cycle.status=$cycle_status)"
           set_phase_needs_human 2>/dev/null || true
           release_lock
           exit 1
           ;;
    esac
}

# ── Log Rotation ───────────────────────────────────────────────────────────
# Keep the most recent $MAX_LOG_FILES log files, delete older ones.
rotate_logs() {
    if [[ "$ROTATE_LOGS" == "0" ]]; then
        return 0
    fi

    local log_count
    log_count=$(find "$LOG_DIR" -maxdepth 1 -name 'cycle-*.log' -type f 2>/dev/null | wc -l)

    if [[ "$log_count" -gt "$MAX_LOG_FILES" ]]; then
        local to_remove=$(( log_count - MAX_LOG_FILES ))
        log "Rotating logs: removing $to_remove oldest files (keeping $MAX_LOG_FILES)"
        # POSIX-compatible: use ls -t (newest first), tail to get oldest, remove via while-read
        # shellcheck disable=SC2012
        ls -t "$LOG_DIR"/cycle-*.log 2>/dev/null \
            | tail -n "$to_remove" \
            | while IFS= read -r _logfile; do rm -f "$_logfile"; done
    fi
}

# ── Main Loop ──────────────────────────────────────────────────────────────
acquire_lock
log "Starting — project=$PROJECT_PATH mode=$MODE timeout=${CYCLE_TIMEOUT}s poll=${POLL_INTERVAL}s"

# Read max iterations (with fallback)
MAX_ITERATIONS=$(get_max_iter)
[[ "$MAX_ITERATIONS" == "unknown" || "$MAX_ITERATIONS" == "null" ]] && MAX_ITERATIONS=200
[[ "$MAX_ITERATIONS" =~ ^[0-9]+$ ]] || MAX_ITERATIONS=200
log "Max iterations: $MAX_ITERATIONS"

RUNNING_WAITED=0
DISPATCH_FAILURES=0

while true; do
    # Check for shutdown between iterations
    [[ "$SHUTTING_DOWN" -eq 1 ]] && break

    # Validate state is parseable each iteration
    validate_state

    PHASE=$(get_phase)
    ITERATION=$(get_iteration)

    # ── Terminal conditions ──────────────────────────────────────────────
    if [[ "$PHASE" == "complete" ]]; then
        log "Pipeline complete at iteration $ITERATION"
        release_lock
        exit 0
    fi

    if [[ "$PHASE" == "needs_human" ]]; then
        log "Needs human intervention. Pausing. (iteration=$ITERATION)"
        release_lock
        exit 1
    fi

    if [[ "$ITERATION" =~ ^[0-9]+$ && "$ITERATION" -ge "$MAX_ITERATIONS" ]]; then
        log "Max iterations reached ($ITERATION >= $MAX_ITERATIONS)"
        release_lock
        exit 1
    fi

    # ── Wait if cycle already running (with timeout) ───────────────────
    if [[ "$(get_cycle_status)" == "running" ]]; then
        sleep "$POLL_INTERVAL"
        RUNNING_WAITED=$((RUNNING_WAITED + POLL_INTERVAL))
        log "Cycle already running. Waited ${RUNNING_WAITED}/${CYCLE_TIMEOUT}s"
        if [[ "$RUNNING_WAITED" -ge "$CYCLE_TIMEOUT" ]]; then
            log "Existing cycle timed out after ${CYCLE_TIMEOUT}s in running state"
            require_state_update "cycle.status=timed_out" set_cycle_timed_out
            require_state_update "phase=needs_human" set_phase_needs_human
            release_lock
            exit 1
        fi
        continue
    fi
    RUNNING_WAITED=0

    # ── P12 init (research phase) ───────────────────────────────────────
    if [[ "$PHASE" == "research" && ! -f "$PROJECT_PATH/.deadf/seed/P2_DONE" ]]; then
        log "P2 brainstorm required — launching .pipe/p12-init.sh"
        if ! "$PROJECT_PATH/.pipe/p12-init.sh" --project "$PROJECT_PATH"; then
            log_err "P12 init runner failed"
            set_phase_needs_human
            release_lock
            exit 1
        fi
    fi

    # ── Rotate logs before kicking new cycle ─────────────────────────────
    TASK_LIST_ID_FILE="$PROJECT_PATH/.deadf/task_list_id"
    if [[ -f "$TASK_LIST_ID_FILE" ]]; then
        export CLAUDE_CODE_TASK_LIST_ID="$(tr -d '\r\n' < "$TASK_LIST_ID_FILE")"
    fi

    rotate_logs

    # ── Kick a new cycle ─────────────────────────────────────────────────
    local_iter="$ITERATION"
    [[ "$local_iter" =~ ^[0-9]+$ ]] || local_iter=0

    log "── Cycle kick (iter=$local_iter, phase=$PHASE) ──"

    "$TIMEOUT_CMD" "$DISPATCH_TIMEOUT" "$KICK_SCRIPT"
    dispatch_rc=$?
    if [[ "$dispatch_rc" -ne 0 ]]; then
        log_err "Failed to kick cycle (exit code: $dispatch_rc)"
        DISPATCH_FAILURES=$((DISPATCH_FAILURES + 1))
        backoff=$(( DISPATCH_FAILURES * DISPATCH_FAILURES * 5 ))
        [[ "$backoff" -gt 300 ]] && backoff=300
        log "Dispatch failure #${DISPATCH_FAILURES}. Backing off ${backoff}s..."
        if [[ "$DISPATCH_FAILURES" -ge 5 ]]; then
            log_err "Too many consecutive dispatch failures ($DISPATCH_FAILURES). Giving up."
            set_phase_needs_human
            release_lock
            exit 1
        fi
        sleep "$backoff"
        continue
    fi

    # ── Wait for cycle completion ────────────────────────────────────────
    WAITED=0
    SAW_RUNNING=0
    while true; do
        sleep "$POLL_INTERVAL"
        WAITED=$((WAITED + POLL_INTERVAL))

        # Check for shutdown during wait
        [[ "$SHUTTING_DOWN" -eq 1 ]] && break

        # Re-validate state each poll
        validate_state

        CS=$(get_cycle_status)
        PH=$(get_phase)

        if [[ "$CS" == "running" ]]; then
            SAW_RUNNING=1
        fi

        # Cycle completed normally
        if [[ "$CS" == "complete" || "$CS" == "failed" || "$CS" == "timed_out" ]]; then
            log "Cycle done (status=$CS, waited=${WAITED}s)"
            break
        fi
        if [[ "$CS" == "idle" && "$SAW_RUNNING" -eq 1 ]]; then
            log "Cycle done (status=$CS, waited=${WAITED}s)"
            break
        fi

        # Phase changed to terminal state
        if [[ "$PH" == "complete" || "$PH" == "needs_human" ]]; then
            log "Phase changed to $PH during cycle (waited=${WAITED}s)"
            break
        fi

        # Timeout enforcement
        if [[ "$WAITED" -ge "$CYCLE_TIMEOUT" ]]; then
            log "Cycle timeout after ${CYCLE_TIMEOUT}s"
            require_state_update "cycle.status=timed_out" set_cycle_timed_out
            require_state_update "phase=needs_human" set_phase_needs_human
            release_lock
            exit 1
        fi
    done

    # Reset dispatch failure counter on successful cycle
    DISPATCH_FAILURES=0

    # Brief pause between cycles to avoid hammering
    sleep 2
done

# If we exit the loop (shutdown flag), clean up
release_lock
log "Exited main loop."
exit 130
