#!/bin/bash
# deadf(ish) Pipeline — kick.sh (Single Cycle Entrypoint)
# Responsibilities: acquire cycle lock, read STATE.yaml, perform one action,
# update STATE.yaml atomically, post status, release lock.

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "${SCRIPT_DIR}/../.." && pwd)

STATE_FILE="$PROJECT_ROOT/.deadf/state/STATE.yaml"
POLICY_FILE="$PROJECT_ROOT/.deadf/state/POLICY.yaml"
STATE_LOCK_FILE="${STATE_FILE}.flock"
CYCLE_LOCK_FILE="$PROJECT_ROOT/.deadf/cycle.flock"

STATE_LOCK_TIMEOUT=5
STATE_UPDATE_RETRIES=3

LOCK_FD=""

log() { echo "[kick] $(date -u -Iseconds) $*"; }
log_err() { echo "[kick] $(date -u -Iseconds) ERROR: $*" >&2; }

require_cmd() {
    command -v "$1" &>/dev/null || { log_err "Required command not found: $1"; exit 1; }
}

preflight() {
    [[ -f "$STATE_FILE" ]] || { log_err "STATE.yaml not found: $STATE_FILE"; exit 1; }
    [[ -f "$POLICY_FILE" ]] || { log_err "POLICY.yaml not found: $POLICY_FILE"; exit 1; }

    require_cmd yq
    require_cmd flock
    require_cmd mktemp
    require_cmd stat

    if ! yq --version 2>/dev/null | grep -qE 'version v?4\.'; then
        log_err "yq v4.x required (mikefarah/yq). Found: $(yq --version 2>/dev/null || echo 'unknown')"
        exit 1
    fi
}

STAT_STYLE=""
init_stat_style() {
    if stat -c '%a' "$STATE_FILE" >/dev/null 2>&1; then
        STAT_STYLE="gnu"
    elif stat -f '%Lp' "$STATE_FILE" >/dev/null 2>&1; then
        STAT_STYLE="bsd"
    else
        log_err "stat does not support -c '%a' (GNU) or -f '%Lp' (BSD). Cannot preserve permissions safely."
        exit 1
    fi
}

stat_perms() {
    case "$STAT_STYLE" in
        gnu) stat -c '%a' "$1" ;;
        bsd) stat -f '%Lp' "$1" ;;
        *) return 1 ;;
    esac
}

acquire_cycle_lock() {
    exec {LOCK_FD}> "$CYCLE_LOCK_FILE" || { log_err "Cannot open lock file: $CYCLE_LOCK_FILE"; exit 1; }
    if ! flock -n "$LOCK_FD"; then
        log "Cycle lock held by another session."
        exit 70
    fi
    printf '%s %s\n' "$$" "$(date -u -Iseconds)" >&"$LOCK_FD" || true
}

release_cycle_lock() {
    if [[ -n "${LOCK_FD:-}" ]]; then
        flock -u "$LOCK_FD" 2>/dev/null || true
        exec {LOCK_FD}>&- || true
        LOCK_FD=""
    fi
}

read_field() {
    yq -r ".${1} // \"null\"" "$STATE_FILE" 2>/dev/null || echo "null"
}

update_state_expr() {
    local expr="$1"
    local attempt tmp
    for ((attempt=1; attempt<=STATE_UPDATE_RETRIES; attempt++)); do
        tmp=$(mktemp "${STATE_FILE}.kick.tmp.XXXXXX") || {
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
            if ! yq eval "$expr" "$STATE_FILE" > "$tmp" 2>/dev/null; then
                log_err "FAILED to write STATE.yaml (attempt ${attempt}/${STATE_UPDATE_RETRIES})"
                rm -f "$tmp"
                exit 11
            fi
            if ! mv -f "$tmp" "$STATE_FILE"; then
                log_err "FAILED to mv tmp file for STATE.yaml (attempt ${attempt}/${STATE_UPDATE_RETRIES})"
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
    update_state_expr '.phase = "needs_human"'
}

update_sub_step() {
    local next_step="$1"
    local action="$2"
    local details="$3"

    update_state_expr "\
        .task.sub_step = \"${next_step}\" |\
        .last_action = \"${action}\" |\
        .last_result.ok = true |\
        .last_result.details = \"${details}\""
}

post_status() {
    local emoji="$1"
    local action="$2"
    local details="$3"
    local next_step="$4"

    local channel
    channel=$(yq -r '.heartbeat.discord_channel // ""' "$POLICY_FILE" 2>/dev/null || true)
    if [[ -z "$channel" || "$channel" == "null" ]]; then
        log_err "Discord channel not configured in POLICY.yaml"
        return 1
    fi

    if ! command -v openclaw &>/dev/null; then
        log_err "openclaw not found; cannot post Discord status"
        return 1
    fi

    local iteration project task_id
    iteration=$(read_field "loop.iteration")
    project=$(read_field "project")
    task_id=$(read_field "task.id")

    local arrow
    arrow=$'\u2192'
    local msg
    msg="${emoji} #${iteration} | ${action} | ${project}:${task_id} | ${details} | ${arrow} ${next_step}"

    openclaw message send --channel discord --to "$channel" --message "$msg"
}

validate_state() {
    if ! yq '.' "$STATE_FILE" > /dev/null 2>&1; then
        log_err "STATE.yaml is unparseable"
        set_phase_needs_human 2>/dev/null || true
        exit 1
    fi
}

# ── Stub Actions ──────────────────────────────────────────────────────────
generate_task() {
    log "Stub: generate_task"
    local next_step="implement"
    local details="stub: advance to implement"
    update_sub_step "$next_step" "generate_task" "$details"
    post_status ":gear:" "generate_task" "$details" "execute.${next_step}" || log_err "Failed to post status"
}

implement_task() {
    log "Stub: implement_task"
    local next_step="verify"
    local details="stub: advance to verify"
    update_sub_step "$next_step" "implement_task" "$details"
    post_status ":hammer_and_wrench:" "implement_task" "$details" "execute.${next_step}" || log_err "Failed to post status"
}

verify_task() {
    log "Stub: verify_task"
    local next_step="reflect"
    local details="stub: advance to reflect"
    update_sub_step "$next_step" "verify_task" "$details"
    post_status ":mag:" "verify_task" "$details" "execute.${next_step}" || log_err "Failed to post status"
}

reflect() {
    log "Stub: reflect"
    local next_step="generate"
    local details="stub: advance to generate"
    update_sub_step "$next_step" "reflect" "$details"
    post_status ":thought_balloon:" "reflect" "$details" "execute.${next_step}" || log_err "Failed to post status"
}

main() {
    preflight
    init_stat_style
    acquire_cycle_lock
    trap release_cycle_lock EXIT

    validate_state

    local phase sub_step
    phase=$(read_field "phase")
    sub_step=$(read_field "task.sub_step")

    case "$phase" in
        needs_human)
            post_status ":warning:" "needs_human" "manual intervention required" "needs_human" || log_err "Failed to post status"
            exit 2
            ;;
        complete)
            post_status ":tada:" "complete" "pipeline complete" "complete" || log_err "Failed to post status"
            exit 0
            ;;
        execute)
            case "$sub_step" in
                generate) generate_task ;;
                implement) implement_task ;;
                verify) verify_task ;;
                reflect) reflect ;;
                *)
                    log_err "Unknown task.sub_step: $sub_step"
                    set_phase_needs_human 2>/dev/null || true
                    post_status ":warning:" "needs_human" "unknown sub_step: ${sub_step}" "needs_human" || log_err "Failed to post status"
                    exit 2
                    ;;
            esac
            ;;
        *)
            log_err "Unknown phase: $phase"
            set_phase_needs_human 2>/dev/null || true
            post_status ":warning:" "needs_human" "unknown phase: ${phase}" "needs_human" || log_err "Failed to post status"
            exit 2
            ;;
    esac

    exit 0
}

main "$@"
