#!/bin/bash
# deadf(ish) CLI — ralph.sh (Loop Controller)
# Architecture: v2.4.2 — Claude Code CLI Port
#
# Ralph is the mechanical loop controller. He kicks cycles, watches state,
# enforces timeouts, manages locks, rotates logs. He never thinks, never
# decides, never plans. Purely mechanical.
#
# Key difference from pipeline version:
#   - Calls `claude --print --dangerously-skip-permissions` instead of `clawdbot session send`
#   - Synchronous execution: claude exits when done, ralph reads stdout
#   - Scans stdout for CYCLE_OK / CYCLE_FAIL / DONE tokens
#
# Write permissions (STATE.yaml):
#   phase        → "needs_human" ONLY
#   cycle.status → "timed_out" ONLY
#   Everything else belongs to Claude Code.
#
# Usage: ralph.sh <project_path> [mode]

set -uo pipefail

# ── Version ────────────────────────────────────────────────────────────────
RALPH_VERSION="2.4.2-cli"

# ── Arguments ──────────────────────────────────────────────────────────────
PROJECT_PATH="${1:?Usage: ralph.sh <project_path> [mode]}"
MODE="${2:-yolo}"

# ── Configuration ──────────────────────────────────────────────────────────
CYCLE_TIMEOUT="${RALPH_TIMEOUT:-600}"
LOG_DIR="$PROJECT_PATH/.deadf/logs"
LOCK_FILE="$PROJECT_PATH/.deadf/ralph.lock"
STATE_FILE="$PROJECT_PATH/STATE.yaml"
NOTIFY_DIR="$PROJECT_PATH/.deadf/notifications"
MAX_LOG_FILES="${RALPH_MAX_LOGS:-50}"
STALE_LOCK_AGE=86400  # 24 hours in seconds

# New CLI-specific configuration
RATE_LIMIT="${RALPH_RATE_LIMIT:-5}"             # Minimum seconds between cycles
MAX_FAILURES="${RALPH_MAX_FAILURES:-10}"         # Circuit breaker: consecutive failures
SESSION_MODE="${RALPH_SESSION:-auto}"            # auto|fresh|continue
SESSION_FILE="$PROJECT_PATH/.deadf/.claude_session_id"
SESSION_MAX_AGE="${RALPH_SESSION_MAX_AGE:-3600}" # Session expiry in seconds (1hr)
MIN_CLAUDE_VERSION="${RALPH_MIN_CLAUDE:-1.0.0}"  # Minimum claude CLI version

# ── Color Output ───────────────────────────────────────────────────────────
if [[ -t 1 ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' CYAN='' BOLD='' NC=''
fi

# ── Preflight ──────────────────────────────────────────────────────────────
[[ -d "$PROJECT_PATH" ]] || { echo -e "${RED}[ralph] ERROR: Project path does not exist: $PROJECT_PATH${NC}" >&2; exit 1; }
[[ -f "$STATE_FILE" ]]   || { echo -e "${RED}[ralph] ERROR: STATE.yaml not found: $STATE_FILE${NC}" >&2; exit 1; }

mkdir -p "$LOG_DIR"    || { echo -e "${RED}[ralph] ERROR: Cannot create log dir: $LOG_DIR${NC}" >&2; exit 1; }
mkdir -p "$NOTIFY_DIR" || { echo -e "${RED}[ralph] ERROR: Cannot create notify dir: $NOTIFY_DIR${NC}" >&2; exit 1; }

command -v yq &>/dev/null    || { echo -e "${RED}[ralph] ERROR: yq required but not found${NC}" >&2; exit 1; }
command -v claude &>/dev/null || { echo -e "${RED}[ralph] ERROR: claude CLI required but not found${NC}" >&2; exit 1; }

# ── Claude CLI Version Check ──────────────────────────────────────────────
check_claude_version() {
    local version_output
    version_output=$(claude --version 2>/dev/null || echo "0.0.0")
    # Extract version number (handles formats like "claude 1.2.3" or just "1.2.3")
    local version
    version=$(echo "$version_output" | grep -oP '\d+\.\d+\.\d+' | head -1)
    [[ -z "$version" ]] && version="0.0.0"

    # Simple semver comparison
    local IFS='.'
    read -r maj1 min1 pat1 <<< "$version"
    read -r maj2 min2 pat2 <<< "$MIN_CLAUDE_VERSION"

    if (( maj1 < maj2 || (maj1 == maj2 && min1 < min2) || (maj1 == maj2 && min1 == min2 && pat1 < pat2) )); then
        echo -e "${RED}[ralph] ERROR: claude CLI version $version < minimum $MIN_CLAUDE_VERSION${NC}" >&2
        exit 1
    fi
    log "Claude CLI version: $version (minimum: $MIN_CLAUDE_VERSION)"
}

# ── Logging ────────────────────────────────────────────────────────────────
log() { echo -e "${CYAN}[ralph]${NC} $(date -Iseconds) $*"; }
log_ok() { echo -e "${GREEN}[ralph]${NC} $(date -Iseconds) $*"; }
log_warn() { echo -e "${YELLOW}[ralph]${NC} $(date -Iseconds) ⚠️  $*"; }
log_err() { echo -e "${RED}[ralph]${NC} $(date -Iseconds) ERROR: $*" >&2; }

# ── Lock Management ───────────────────────────────────────────────────────
acquire_lock() {
    if ! ( set -o noclobber; echo "$$ $(date -Iseconds)" > "$LOCK_FILE" ) 2>/dev/null; then
        local other_pid other_ts
        read -r other_pid other_ts < "$LOCK_FILE" 2>/dev/null || true

        if [[ -z "$other_pid" ]]; then
            log "Empty lockfile. Taking over."
            echo "$$ $(date -Iseconds)" > "$LOCK_FILE"
            return 0
        fi

        if kill -0 "$other_pid" 2>/dev/null; then
            if [[ -n "$other_ts" ]]; then
                local lock_epoch
                lock_epoch=$(date -d "$other_ts" +%s 2>/dev/null || echo 0)
                local now_epoch
                now_epoch=$(date +%s)
                local lock_age=$(( now_epoch - lock_epoch ))

                if [[ "$lock_age" -gt "$STALE_LOCK_AGE" ]]; then
                    log_warn "Lock PID $other_pid alive but ${lock_age}s old (>${STALE_LOCK_AGE}s). Assuming stale."
                    echo "$$ $(date -Iseconds)" > "$LOCK_FILE"
                    return 0
                fi
            fi
            log_err "Another instance running (PID $other_pid). Exiting."
            exit 1
        else
            log "Stale lock (PID $other_pid dead). Taking over."
            echo "$$ $(date -Iseconds)" > "$LOCK_FILE"
        fi
    fi
}

release_lock() {
    rm -f "$LOCK_FILE"
}

# ── Signal Handling ────────────────────────────────────────────────────────
SHUTTING_DOWN=0

cleanup() {
    if [[ "$SHUTTING_DOWN" -eq 1 ]]; then
        return
    fi
    SHUTTING_DOWN=1
    log "🛑 Signal received. Shutting down gracefully."
    release_lock
    print_summary
    log "Shutdown complete."
    exit 130
}

trap cleanup INT TERM

# ── STATE.yaml Helpers ─────────────────────────────────────────────────────
read_field() {
    yq -r ".$1 // \"unknown\"" "$STATE_FILE" 2>/dev/null || echo "unknown"
}

get_iteration()    { read_field "loop.iteration"; }
get_phase()        { read_field "phase"; }
get_cycle_status() { read_field "cycle.status"; }
get_max_iter()     { read_field "loop.max_iterations"; }

# Ralph may ONLY set these specific values:
set_phase_needs_human() {
    yq -i '.phase = "needs_human"' "$STATE_FILE"
}

set_cycle_timed_out() {
    yq -i '.cycle.status = "timed_out"' "$STATE_FILE"
}

# ── Log Rotation ───────────────────────────────────────────────────────────
rotate_logs() {
    local log_count
    log_count=$(find "$LOG_DIR" -maxdepth 1 -name 'cycle-*.log' -type f 2>/dev/null | wc -l)

    if [[ "$log_count" -gt "$MAX_LOG_FILES" ]]; then
        local to_remove=$(( log_count - MAX_LOG_FILES ))
        log "Rotating logs: removing $to_remove oldest files (keeping $MAX_LOG_FILES)"
        find "$LOG_DIR" -maxdepth 1 -name 'cycle-*.log' -type f -printf '%T@ %p\n' \
            | sort -n \
            | head -n "$to_remove" \
            | awk '{print $2}' \
            | xargs -r rm -f
    fi
}

# ── UUID Generation ────────────────────────────────────────────────────────
generate_cycle_id() {
    uuidgen 2>/dev/null \
        || cat /proc/sys/kernel/random/uuid 2>/dev/null \
        || echo "cycle-$(date +%s)-$$"
}

# ── Session Management ─────────────────────────────────────────────────────
get_session_flag() {
    case "$SESSION_MODE" in
        fresh)
            # Always start a new session
            echo ""
            ;;
        continue)
            # Always continue (if session file exists)
            if [[ -f "$SESSION_FILE" ]]; then
                local session_id
                session_id=$(cat "$SESSION_FILE" 2>/dev/null)
                if [[ -n "$session_id" ]]; then
                    echo "--continue --session-id $session_id"
                    return
                fi
            fi
            echo ""
            ;;
        auto|*)
            # Continue if session is fresh enough, otherwise start new
            if [[ -f "$SESSION_FILE" ]]; then
                local session_ts
                session_ts=$(stat -c %Y "$SESSION_FILE" 2>/dev/null || echo 0)
                local now_ts
                now_ts=$(date +%s)
                local age=$(( now_ts - session_ts ))

                if [[ "$age" -lt "$SESSION_MAX_AGE" ]]; then
                    local session_id
                    session_id=$(cat "$SESSION_FILE" 2>/dev/null)
                    if [[ -n "$session_id" ]]; then
                        log "Reusing session (age=${age}s < ${SESSION_MAX_AGE}s)"
                        echo "--continue --session-id $session_id"
                        return
                    fi
                else
                    log "Session expired (age=${age}s >= ${SESSION_MAX_AGE}s). Starting fresh."
                    rm -f "$SESSION_FILE"
                fi
            fi
            echo ""
            ;;
    esac
}

save_session_id() {
    local output="$1"
    # Claude CLI may output session ID — try to capture it
    # The session ID is typically in the output or can be derived
    # For now, use a hash of the first cycle as session marker
    local session_id
    session_id=$(echo "$output" | grep -oP 'session[_-]?id[=: ]+\K\S+' | head -1)
    if [[ -z "$session_id" ]]; then
        # Generate a stable session ID for this run
        session_id="ralph-$$-$(date +%s)"
    fi
    echo "$session_id" > "$SESSION_FILE"
}

# ── Notifications ──────────────────────────────────────────────────────────
notify() {
    local event="$1"
    local message="$2"
    local timestamp
    timestamp=$(date -Iseconds)
    local file="$NOTIFY_DIR/${event}-${timestamp}.md"

    cat > "$file" <<EOF
# Notification: $event
**Timestamp:** $timestamp
**Project:** $PROJECT_PATH
**Mode:** $MODE

$message
EOF

    log "$message"
}

# ── Statistics Tracking ────────────────────────────────────────────────────
STATS_START_TIME=$(date +%s)
STATS_CYCLES_RUN=0
STATS_CYCLES_OK=0
STATS_CYCLES_FAIL=0
STATS_CONSECUTIVE_FAILURES=0

print_summary() {
    local end_time
    end_time=$(date +%s)
    local duration=$(( end_time - STATS_START_TIME ))
    local hours=$(( duration / 3600 ))
    local minutes=$(( (duration % 3600) / 60 ))
    local seconds=$(( duration % 60 ))

    echo ""
    echo -e "${BOLD}════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ralph.sh Session Summary${NC}"
    echo -e "${BOLD}════════════════════════════════════════${NC}"
    echo -e "  Version:     ${RALPH_VERSION}"
    echo -e "  Project:     ${PROJECT_PATH}"
    echo -e "  Mode:        ${MODE}"
    echo -e "  Duration:    ${hours}h ${minutes}m ${seconds}s"
    echo -e "  Cycles run:  ${STATS_CYCLES_RUN}"
    echo -e "  ├─ OK:       ${GREEN}${STATS_CYCLES_OK}${NC}"
    echo -e "  └─ Failed:   ${RED}${STATS_CYCLES_FAIL}${NC}"
    echo -e "  Final phase: $(get_phase)"
    echo -e "${BOLD}════════════════════════════════════════${NC}"
    echo ""
}

# ── Scan Claude Output ─────────────────────────────────────────────────────
# Scans stdout for the LAST occurrence of CYCLE_OK, CYCLE_FAIL, or DONE.
# Returns: "ok", "fail", "done", or "unknown"
scan_cycle_result() {
    local output_file="$1"

    if [[ ! -s "$output_file" ]]; then
        echo "unknown"
        return
    fi

    # Scan from the end for the last occurrence of a cycle token
    local last_token=""
    while IFS= read -r line; do
        case "$line" in
            *DONE*)       last_token="done" ;;
            *CYCLE_OK*)   last_token="ok" ;;
            *CYCLE_FAIL*) last_token="fail" ;;
        esac
    done < "$output_file"

    echo "${last_token:-unknown}"
}

# ── Run Claude Cycle ───────────────────────────────────────────────────────
run_cycle() {
    local cycle_id="$1"
    local cycle_log="$2"
    local local_iter="$3"
    local phase="$4"

    local session_flags
    session_flags=$(get_session_flag)

    local prompt="DEADF_CYCLE $cycle_id
project: $PROJECT_PATH
mode: $MODE
Execute ONE cycle. Follow iteration contract. Reply: CYCLE_OK | CYCLE_FAIL | DONE"

    local output_file="$LOG_DIR/.cycle-output-$$"

    log "Invoking claude --print (iter=$local_iter, phase=$phase, id=${cycle_id:0:8}...)"

    # Build command — use eval to handle session_flags which may be empty
    local cmd="claude --print --dangerously-skip-permissions"
    if [[ -n "$session_flags" ]]; then
        cmd="$cmd $session_flags"
    fi

    # Run with timeout
    local exit_code=0
    timeout "$CYCLE_TIMEOUT" bash -c "$cmd -p \"\$1\"" -- "$prompt" \
        > "$output_file" 2>>"$cycle_log" || exit_code=$?

    # Log the output
    if [[ -f "$output_file" ]]; then
        cat "$output_file" >> "$cycle_log"
    fi

    # Handle timeout (exit code 124)
    if [[ "$exit_code" -eq 124 ]]; then
        log_err "⏰ Cycle timeout after ${CYCLE_TIMEOUT}s"
        echo "$(date -Iseconds) TIMEOUT after ${CYCLE_TIMEOUT}s" >> "$cycle_log"
        set_cycle_timed_out
        set_phase_needs_human
        notify "timeout" "Cycle timed out after ${CYCLE_TIMEOUT}s at iteration $local_iter"
        rm -f "$output_file"
        echo "timeout"
        return
    fi

    # Handle claude crash (nonzero exit, not timeout)
    if [[ "$exit_code" -ne 0 ]]; then
        log_warn "claude exited with code $exit_code"
        echo "$(date -Iseconds) CLAUDE_EXIT_CODE=$exit_code" >> "$cycle_log"
    fi

    # Save session ID for potential reuse
    if [[ -f "$output_file" ]]; then
        save_session_id "$(cat "$output_file")"
    fi

    # Scan for cycle result token
    local result
    result=$(scan_cycle_result "$output_file")
    rm -f "$output_file"

    echo "$result"
}

# ── Main ───────────────────────────────────────────────────────────────────
check_claude_version
acquire_lock

log_ok "Starting ralph.sh v${RALPH_VERSION}"
log "  project=$PROJECT_PATH mode=$MODE"
log "  timeout=${CYCLE_TIMEOUT}s rate_limit=${RATE_LIMIT}s"
log "  max_failures=$MAX_FAILURES session=$SESSION_MODE"

# Read max iterations (with fallback)
MAX_ITERATIONS=$(get_max_iter)
[[ "$MAX_ITERATIONS" == "unknown" || "$MAX_ITERATIONS" == "null" ]] && MAX_ITERATIONS=200
log "Max iterations: $MAX_ITERATIONS"

LAST_CYCLE_TIME=0

while true; do
    # Check for shutdown between iterations
    [[ "$SHUTTING_DOWN" -eq 1 ]] && break

    PHASE=$(get_phase)
    ITERATION=$(get_iteration)

    # ── Terminal conditions ──────────────────────────────────────────────
    if [[ "$PHASE" == "complete" ]]; then
        log_ok "🎉 Pipeline complete at iteration $ITERATION"
        notify "complete" "Pipeline completed successfully at iteration $ITERATION"
        release_lock
        print_summary
        exit 0
    fi

    if [[ "$PHASE" == "needs_human" ]]; then
        log_warn "Needs human intervention. Pausing. (iteration=$ITERATION)"
        notify "needs-human" "Pipeline paused — needs human intervention at iteration $ITERATION"
        release_lock
        print_summary
        exit 1
    fi

    if [[ "$ITERATION" != "unknown" && "$ITERATION" -ge "$MAX_ITERATIONS" ]]; then
        log_err "🛑 Max iterations reached ($ITERATION >= $MAX_ITERATIONS)"
        notify "max-iterations" "Max iterations reached ($ITERATION >= $MAX_ITERATIONS)"
        release_lock
        print_summary
        exit 1
    fi

    # ── Circuit breaker ──────────────────────────────────────────────────
    if [[ "$STATS_CONSECUTIVE_FAILURES" -ge "$MAX_FAILURES" ]]; then
        log_err "🔌 Circuit breaker: $STATS_CONSECUTIVE_FAILURES consecutive failures (limit=$MAX_FAILURES)"
        set_phase_needs_human
        notify "circuit-breaker" "Circuit breaker tripped: $STATS_CONSECUTIVE_FAILURES consecutive failures"
        release_lock
        print_summary
        exit 1
    fi

    # ── Rate limiting ────────────────────────────────────────────────────
    NOW_TS=$(date +%s)
    ELAPSED=$(( NOW_TS - LAST_CYCLE_TIME ))
    if [[ "$LAST_CYCLE_TIME" -gt 0 && "$ELAPSED" -lt "$RATE_LIMIT" ]]; then
        WAIT_TIME=$(( RATE_LIMIT - ELAPSED ))
        log "Rate limit: waiting ${WAIT_TIME}s"
        sleep "$WAIT_TIME"
    fi

    # ── Rotate logs before kicking new cycle ─────────────────────────────
    rotate_logs

    # ── Kick a new cycle ─────────────────────────────────────────────────
    CYCLE_ID=$(generate_cycle_id)
    local_iter="${ITERATION:-0}"

    log "── Cycle kick (iter=$local_iter, phase=$PHASE, id=${CYCLE_ID:0:8}...) ──"

    CYCLE_LOG="$LOG_DIR/cycle-${local_iter}.log"
    echo "$(date -Iseconds) CYCLE_START id=$CYCLE_ID iter=$local_iter phase=$PHASE" >> "$CYCLE_LOG"

    LAST_CYCLE_TIME=$(date +%s)

    # Run claude and get result
    RESULT=$(run_cycle "$CYCLE_ID" "$CYCLE_LOG" "$local_iter" "$PHASE")
    STATS_CYCLES_RUN=$((STATS_CYCLES_RUN + 1))

    echo "$(date -Iseconds) RESULT=$RESULT" >> "$CYCLE_LOG"

    case "$RESULT" in
        ok)
            log_ok "✅ Cycle OK (iter=$local_iter)"
            STATS_CYCLES_OK=$((STATS_CYCLES_OK + 1))
            STATS_CONSECUTIVE_FAILURES=0
            ;;
        done)
            log_ok "🎉 Pipeline reports DONE (iter=$local_iter)"
            STATS_CYCLES_OK=$((STATS_CYCLES_OK + 1))
            STATS_CONSECUTIVE_FAILURES=0
            # Loop will check phase on next iteration and exit
            ;;
        fail)
            log_warn "❌ Cycle failed (iter=$local_iter, consecutive=${STATS_CONSECUTIVE_FAILURES})"
            STATS_CYCLES_FAIL=$((STATS_CYCLES_FAIL + 1))
            STATS_CONSECUTIVE_FAILURES=$((STATS_CONSECUTIVE_FAILURES + 1))
            ;;
        timeout)
            log_err "⏰ Cycle timed out — exiting"
            STATS_CYCLES_FAIL=$((STATS_CYCLES_FAIL + 1))
            release_lock
            print_summary
            exit 1
            ;;
        unknown|*)
            log_warn "⚠️  No valid cycle reply — treating as failure (iter=$local_iter)"
            STATS_CYCLES_FAIL=$((STATS_CYCLES_FAIL + 1))
            STATS_CONSECUTIVE_FAILURES=$((STATS_CONSECUTIVE_FAILURES + 1))
            ;;
    esac
done

# If we exit the loop (shutdown flag), clean up
release_lock
print_summary
log "Exited main loop."
exit 130
