# P1 - Cycle Kick Template

## Variables

| Variable | Type | Default | Notes |
|---|---|---|---|
| {PROJECT_NAME} | string | basename of project path | Required |
| {PROJECT_PATH} | absolute path | none | Required |
| {CYCLE_ID} | string | cycle-{iteration+1}-{8hex} | Required |
| {MODE} | string | unknown | From STATE.yaml .mode |
| {STATE_HINT} | string | unknown | Extracted under process lock |
| {DISCORD_CHANNEL} | string | unknown | From POLICY.yaml .heartbeat.discord_channel (optional) |

## Kick Message

```text
DEADF_CYCLE {CYCLE_ID}
project: {PROJECT_NAME}
path: {PROJECT_PATH}
mode: {MODE}
state: {STATE_HINT} (advisory -- STATE.yaml is authoritative; ignore hint if it conflicts)
discord: {DISCORD_CHANNEL}

BOOTSTRAP:
1) cd {PROJECT_PATH} or print CYCLE_FAIL and exit
2) Require CLAUDE.md, STATE.yaml, POLICY.yaml; if missing print CYCLE_FAIL and exit
3) Acquire flock on STATE.yaml.flock for VALIDATE (R-M-W)

EXECUTE:
Follow CLAUDE.md iteration contract: LOAD -> VALIDATE -> DECIDE -> ONE action -> RECORD -> REPORT
Contract: CLAUDE.md (binding)

Reply:
Final line token must be one of:
CYCLE_OK | CYCLE_FAIL | DONE
```

## State Hint Format

{cycle.status} {phase}:{sub_step} #{iteration} task={task_id} retry={retry_count}/{max_retries}

Examples:
- idle research:- #0 task=- retry=0/3
- idle execute:implement #47 task=tui-09 retry=1/3
- running execute:verify #48 task=tui-09 retry=0/3
- timed_out needs_human:- #55 task=api-03 retry=3/3
