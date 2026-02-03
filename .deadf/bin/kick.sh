#!/usr/bin/env bash
# deadf(ish) Pipeline — kick.sh (Shared Kick Assembly)
# Responsibilities: assemble kick message from template, dispatch to Claude Code.
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
DEADF_ROOT="${DEADF_ROOT:-$(cd -- "$SCRIPT_DIR/.." && pwd)}"
PROJECT_ROOT="${PROJECT_ROOT:-$(cd -- "$DEADF_ROOT/.." && pwd)}"

STATE_FILE="$DEADF_ROOT/state/STATE.yaml"
POLICY_FILE="$DEADF_ROOT/state/POLICY.yaml"
TEMPLATE_FILE="$DEADF_ROOT/templates/kick/cycle-kick.md"
LOG_DIR="$DEADF_ROOT/logs"

log_err() { echo "[kick] $(date -u -Iseconds) ERROR: $*" >&2; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { log_err "Required command not found: $1"; exit 20; }
}

preflight() {
  [[ -f "$STATE_FILE" ]] || { log_err "STATE.yaml not found: $STATE_FILE"; exit 20; }
  [[ -f "$POLICY_FILE" ]] || { log_err "POLICY.yaml not found: $POLICY_FILE"; exit 20; }
  [[ -f "$TEMPLATE_FILE" ]] || { log_err "Kick template not found: $TEMPLATE_FILE"; exit 20; }

  mkdir -p "$LOG_DIR" || { log_err "Cannot create log dir: $LOG_DIR"; exit 20; }
  [[ -w "$LOG_DIR" ]] || { log_err "Log dir not writable: $LOG_DIR"; exit 20; }

  require_cmd yq
  require_cmd mktemp
  require_cmd tee
  require_cmd od
  require_cmd tr

  if ! yq --version 2>/dev/null | grep -qE 'version v?4\.'; then
    log_err "yq v4.x required (mikefarah/yq). Found: $(yq --version 2>/dev/null || echo 'unknown')"
    exit 20
  fi
}

num_or_default() {
  local val="$1"
  local def="$2"
  if [[ "$val" =~ ^[0-9]+$ ]]; then
    printf '%s' "$val"
  else
    printf '%s' "$def"
  fi
}

yq_read() {
  local query="$1"
  local file="$2"
  local out
  if ! out=$(yq -r "$query" "$file" 2>/dev/null); then
    log_err "Failed to read: $query from $file"
    exit 20
  fi
  printf '%s' "$out"
}

parse_template() {
  local tpl
  tpl=$(awk 'BEGIN{found=0} /^```text[[:space:]]*$/ {found=1; next} /^```/ {if(found){exit}} found{print}' "$TEMPLATE_FILE")
  if [[ -z "$tpl" ]]; then
    log_err "Template parse failed: $TEMPLATE_FILE"
    exit 20
  fi
  printf '%s' "$tpl"
}

generate_cycle_id() {
  local iteration="$1"
  local iteration_plus_one=$((iteration + 1))
  local hex
  hex=$(od -An -N4 -tx1 /dev/urandom | tr -d ' \n')
  printf 'cycle-%s-%s' "$iteration_plus_one" "$hex"
}

main() {
  preflight

  local project_path project_name
  project_path="$PROJECT_ROOT"
  project_name=$(basename -- "$project_path")

  local cycle_status phase sub_step iteration_raw task_id retry_count_raw max_retries_raw
  cycle_status=$(yq_read '.cycle.status // "unknown"' "$STATE_FILE")
  phase=$(yq_read '.phase // "unknown"' "$STATE_FILE")
  sub_step=$(yq_read '.task.sub_step // "-"' "$STATE_FILE")
  iteration_raw=$(yq_read '.loop.iteration // 0' "$STATE_FILE")
  task_id=$(yq_read '.task.id // "-"' "$STATE_FILE")
  retry_count_raw=$(yq_read '.task.retry_count // 0' "$STATE_FILE")
  max_retries_raw=$(yq_read '.task.max_retries // 0' "$STATE_FILE")

  local iteration retry_count max_retries
  iteration=$(num_or_default "$iteration_raw" 0)
  retry_count=$(num_or_default "$retry_count_raw" 0)
  max_retries=$(num_or_default "$max_retries_raw" 0)

  local state_hint
  state_hint="${cycle_status} ${phase}:${sub_step} #${iteration} task=${task_id} retry=${retry_count}/${max_retries}"

  local mode discord_channel
  mode=$(yq_read '.mode // "unknown"' "$STATE_FILE")
  discord_channel=$(yq_read '.heartbeat.discord_channel // "unknown"' "$POLICY_FILE")
  if [[ -z "$discord_channel" || "$discord_channel" == "null" ]]; then
    discord_channel="unknown"
  fi

  local cycle_id
  if [[ -n "${CYCLE_ID:-}" ]]; then
    cycle_id="$CYCLE_ID"
  else
    cycle_id=$(generate_cycle_id "$iteration")
  fi

  local task_list_id
  task_list_id="${CLAUDE_CODE_TASK_LIST_ID:-}"

  local kick_template kick_message
  kick_template=$(parse_template)

  kick_message="$kick_template"
  kick_message=${kick_message//\{PROJECT_NAME\}/$project_name}
  kick_message=${kick_message//\{PROJECT_PATH\}/$project_path}
  kick_message=${kick_message//\{CYCLE_ID\}/$cycle_id}
  kick_message=${kick_message//\{MODE\}/$mode}
  kick_message=${kick_message//\{STATE_HINT\}/$state_hint}
  kick_message=${kick_message//\{DISCORD_CHANNEL\}/$discord_channel}
  kick_message=${kick_message//\{TASK_LIST_ID\}/$task_list_id}

  local claude_exe
  claude_exe="${P1_CLAUDE_BIN:-${CLAUDE_BIN:-claude}}"
  if ! command -v "$claude_exe" >/dev/null 2>&1; then
    log_err "Claude Code CLI not found: $claude_exe"
    exit 21
  fi

  "$claude_exe" --print --allowedTools "Read,Write,Edit,Bash,Task,Glob,Grep" "$kick_message" \
    2>&1 | tee "$LOG_DIR/cycle-${cycle_id}.log"
  local rc=${PIPESTATUS[0]}
  if [[ $rc -ne 0 ]]; then
    log_err "Claude Code CLI exited non-zero: $rc"
    exit 21
  fi

  exit 0
}

main "$@"
