#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Exit codes:
# 0  - success (session spawned; subprocess exit code 0)
# 10 - skip: lock held
# 11 - skip: needs_human
# 12 - skip: complete
# 13 - skip: cycle_running
# 14 - skip: stale_running_cycle (recovered -> needs_human)
# 20 - error: preflight/deps/state parse/update failure
# 21 - error: orchestrator spawn failure

json_escape() {
  local s="$1"
  s=${s//\\/\\\\}
  s=${s//\"/\\\"}
  s=${s//$'\n'/\\n}
  s=${s//$'\r'/\\r}
  s=${s//$'\t'/\\t}
  printf '%s' "$s"
}

log_json() {
  local level="$1"
  local event="$2"
  local exit_code="$3"
  local reason="$4"
  local project_path="$5"
  local cycle_id="$6"
  local ts
  if ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null); then
    :
  else
    ts="unknown"
  fi
  printf '{"ts":"%s","level":"%s","event":"%s","exit_code":%s,"reason":"%s","project_path":"%s","cycle_id":"%s"}\n' \
    "$(json_escape "$ts")" \
    "$(json_escape "$level")" \
    "$(json_escape "$event")" \
    "$(json_escape "$exit_code")" \
    "$(json_escape "$reason")" \
    "$(json_escape "$project_path")" \
    "$(json_escape "$cycle_id")"
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
  if ! out=$(yq -r "$query" "$file"); then
    log_json "ERROR" "error" 20 "state_parse_failed" "$PROJECT_PATH" ""
    exit 20
  fi
  printf '%s' "$out"
}

script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
PROJECT_PATH=$(cd -- "$script_dir/../.." && pwd)
PROJECT_NAME=$(basename -- "$PROJECT_PATH")

DEADF_DIR="$PROJECT_PATH/.deadf"
LOG_DIR="$DEADF_DIR/logs"
STATE_FILE="$PROJECT_PATH/STATE.yaml"
POLICY_FILE="$PROJECT_PATH/POLICY.yaml"
TEMPLATE_FILE="$PROJECT_PATH/.pipe/p1/P1_CYCLE_KICK.md"

if [[ ! -d "$DEADF_DIR" ]]; then
  if ! mkdir -p "$DEADF_DIR"; then
    log_json "ERROR" "error" 20 "deadf_dir_create_failed" "$PROJECT_PATH" ""
    exit 20
  fi
fi
if [[ ! -d "$LOG_DIR" ]]; then
  if ! mkdir -p "$LOG_DIR"; then
    log_json "ERROR" "error" 20 "log_dir_create_failed" "$PROJECT_PATH" ""
    exit 20
  fi
fi
if [[ ! -w "$DEADF_DIR" || ! -w "$LOG_DIR" ]]; then
  log_json "ERROR" "error" 20 "deadf_dir_not_writable" "$PROJECT_PATH" ""
  exit 20
fi

for dep in flock yq date mktemp tee; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    log_json "ERROR" "error" 20 "missing_dependency:$dep" "$PROJECT_PATH" ""
    exit 20
  fi
done

if [[ ! -f "$STATE_FILE" || ! -f "$POLICY_FILE" ]]; then
  log_json "ERROR" "error" 20 "missing_state_or_policy" "$PROJECT_PATH" ""
  exit 20
fi

lock_file="$DEADF_DIR/cron.lock"
exec 9>"$lock_file"
if ! flock -n 9; then
  log_json "INFO" "skip" 10 "lock_held" "$PROJECT_PATH" ""
  exit 10
fi

cycle_status=$(yq_read '.cycle.status // "unknown"' "$STATE_FILE")
phase=$(yq_read '.phase // "unknown"' "$STATE_FILE")
started_at=$(yq_read '.cycle.started_at // ""' "$STATE_FILE")

if [[ -z "$cycle_status" || "$cycle_status" == "null" ]]; then
  log_json "ERROR" "error" 20 "state_parse_failed" "$PROJECT_PATH" ""
  exit 20
fi

P1_CYCLE_TIMEOUT_S=${P1_CYCLE_TIMEOUT_S:-600}

if [[ "$cycle_status" == "running" ]]; then
  now_epoch=$(date -u +%s)
  started_epoch=0
  if [[ -n "$started_at" && "$started_at" != "null" ]]; then
    if ! started_epoch=$(date -u -d "$started_at" +%s 2>/dev/null); then
      log_json "ERROR" "error" 20 "state_started_at_invalid" "$PROJECT_PATH" ""
      exit 20
    fi
  fi
  age=$((now_epoch - started_epoch))
  if (( age >= P1_CYCLE_TIMEOUT_S )); then
    (
      flock -w 5 8 || exit 1
      tmp=$(mktemp "${STATE_FILE}.tmp.XXXXXX")
      yq -y '(.cycle.status = "timed_out") | (.phase = "needs_human")' "$STATE_FILE" > "$tmp"
      mv -f "$tmp" "$STATE_FILE"
    ) 8>"${STATE_FILE}.flock" || {
      log_json "ERROR" "error" 20 "state_update_failed" "$PROJECT_PATH" ""
      exit 20
    }
    log_json "INFO" "skip" 14 "stale_running_cycle" "$PROJECT_PATH" ""
    exit 14
  fi
  log_json "INFO" "skip" 13 "cycle_running" "$PROJECT_PATH" ""
  exit 13
fi

if [[ "$phase" == "needs_human" ]]; then
  log_json "INFO" "skip" 11 "needs_human" "$PROJECT_PATH" ""
  exit 11
fi

if [[ "$phase" == "complete" ]]; then
  log_json "INFO" "skip" 12 "complete" "$PROJECT_PATH" ""
  exit 12
fi

cycle_status=$(yq_read '.cycle.status // "unknown"' "$STATE_FILE")
phase=$(yq_read '.phase // "unknown"' "$STATE_FILE")
sub_step=$(yq_read '.task.sub_step // "-"' "$STATE_FILE")
iteration_raw=$(yq_read '.loop.iteration // 0' "$STATE_FILE")
task_id=$(yq_read '.task.id // "-"' "$STATE_FILE")
retry_count_raw=$(yq_read '.task.retry_count // 0' "$STATE_FILE")
max_retries_raw=$(yq_read '.task.max_retries // 0' "$STATE_FILE")

iteration=$(num_or_default "$iteration_raw" 0)
retry_count=$(num_or_default "$retry_count_raw" 0)
max_retries=$(num_or_default "$max_retries_raw" 0)

STATE_HINT="${cycle_status} ${phase}:${sub_step} #${iteration} task=${task_id} retry=${retry_count}/${max_retries}"

MODE=$(yq_read '.mode // "unknown"' "$STATE_FILE")
DISCORD_CHANNEL=$(yq_read '.heartbeat.discord_channel // "unknown"' "$POLICY_FILE")
if [[ -z "$DISCORD_CHANNEL" || "$DISCORD_CHANNEL" == "null" ]]; then
  DISCORD_CHANNEL="unknown"
fi

iteration_plus_one=$((iteration + 1))
hex=$(od -An -N4 -tx1 /dev/urandom | tr -d ' \n')
CYCLE_ID="cycle-${iteration_plus_one}-${hex}"

if [[ ! -f "$TEMPLATE_FILE" ]]; then
  log_json "ERROR" "error" 20 "template_missing" "$PROJECT_PATH" "$CYCLE_ID"
  exit 20
fi

kick_template=$(awk 'BEGIN{found=0} /^```text[[:space:]]*$/ {found=1; next} /^```/ {if(found){exit}} found{print}' "$TEMPLATE_FILE")
if [[ -z "$kick_template" ]]; then
  log_json "ERROR" "error" 20 "template_parse_failed" "$PROJECT_PATH" "$CYCLE_ID"
  exit 20
fi

kick_message="$kick_template"
kick_message=${kick_message//\{PROJECT_NAME\}/$PROJECT_NAME}
kick_message=${kick_message//\{PROJECT_PATH\}/$PROJECT_PATH}
kick_message=${kick_message//\{CYCLE_ID\}/$CYCLE_ID}
kick_message=${kick_message//\{MODE\}/$MODE}
kick_message=${kick_message//\{STATE_HINT\}/$STATE_HINT}
kick_message=${kick_message//\{DISCORD_CHANNEL\}/$DISCORD_CHANNEL}

P1_MAX_LOGS=${P1_MAX_LOGS:-50}
if [[ "$P1_MAX_LOGS" =~ ^[0-9]+$ ]]; then
  mapfile -t old_logs < <(
    find "$LOG_DIR" -maxdepth 1 -type f -name 'cycle-*.log' -printf '%T@ %p\n' |
      sort -nr |
      awk -v keep="$P1_MAX_LOGS" 'NR>keep {print $2}'
  )
  if (( ${#old_logs[@]} > 0 )); then
    rm -f -- "${old_logs[@]}"
  fi
fi

CLAUDE_BIN=${P1_CLAUDE_BIN:-claude}
if ! command -v "$CLAUDE_BIN" >/dev/null 2>&1; then
  log_json "ERROR" "error" 21 "spawn_failed_missing_claude" "$PROJECT_PATH" "$CYCLE_ID"
  exit 21
fi

log_json "INFO" "spawn" 0 "spawn" "$PROJECT_PATH" "$CYCLE_ID"
"$CLAUDE_BIN" --print --allowedTools "Read,Write,Edit,Bash,Task,Glob,Grep" "$kick_message" 2>&1 | tee "$LOG_DIR/cycle-${CYCLE_ID}.log"
rc=$?

if [[ $rc -ne 0 ]]; then
  log_json "ERROR" "error" 21 "spawn_failed" "$PROJECT_PATH" "$CYCLE_ID"
  exit 21
fi

log_json "INFO" "done" 0 "complete" "$PROJECT_PATH" "$CYCLE_ID"
exit 0
