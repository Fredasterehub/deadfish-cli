# Integration Test: Task Management (Track 7.3)
Date: 2025-01-29T19:01Z
Claude Code version: 2.1.23

## Test Setup
- Project: /tmp/deadfish-task-test
- CLAUDE_CODE_TASK_LIST_ID: deadf-task-test
- Task: Create greeting.py
- Allowed tools: `Read,Write,Edit,Bash,TodoRead,TodoWrite,Glob,Grep`
- Prompt asked to use TodoWrite for task tracking

## Results
### File Creation: PASS
- `greeting.py` created with correct content: `print("Hello from deadf(ish) with Tasks!")`
- Output: `Hello from deadf(ish) with Tasks!`

### CYCLE_OK Signal: PASS
- CYCLE_OK appeared as the last meaningful line of stdout
- Claude exited with code 0

### Task Created (TodoWrite): PARTIAL
- A todo file was created at `~/.claude/todos/bffa14c9-...-agent-bffa14c9-....json`
- File was modified within the test window (last 5 min)
- However, content is `[]` (empty array) — Claude likely created then completed/cleared todos

### Task Status Updated: INCONCLUSIVE
- The todo file exists but is empty post-session
- Claude Code's TodoWrite tool appears to clean up completed items on exit
- No way to verify intermediate status transitions from outside

### Tasks Persisted: PARTIAL
- File persists on disk at `~/.claude/todos/`
- Content is `[]` — completed tasks are not retained in the JSON after session ends

## Key Observations

1. **TodoWrite vs Task tool naming**: Claude Code 2.1.23 uses `TodoRead`/`TodoWrite` (not `TaskCreate`/`TaskUpdate`). The `--allowedTools` list must include `TodoRead,TodoWrite` for task management to work.

2. **Todos are ephemeral**: Claude's built-in todo system appears to clear completed items when the session ends. The JSON files persist but contain `[]` after completion. This means ralph.sh's `task_status_check()` function can only observe todos during an active session, not after.

3. **`--allowedTools` works correctly**: Using `--allowedTools "Read,Write,Edit,Bash,TodoRead,TodoWrite,Glob,Grep"` is the correct approach for root environments where `--dangerously-skip-permissions` fails.

4. **CLAUDE_CODE_TASK_LIST_ID**: The env var was exported but Claude Code doesn't appear to use it for todo segregation — todos go to per-session UUID-named files regardless.

5. **No git commit by Claude**: Claude created the file but did not commit it. The CLAUDE.md instructions should explicitly ask for commits if desired during cycles.

## Recommendations for ralph.sh

- `task_status_check()` should run **during** the cycle (while claude is still running) to capture todo state, not after
- Consider parsing claude's stdout for task-related output instead of relying on todo file inspection
- The `RALPH_TASK_LIST_ID` / `CLAUDE_CODE_TASK_LIST_ID` env var may not affect todo behavior — needs further investigation
- Alternatively, use claude's `--output-format json` or structured output to capture task state

## Test Command
```bash
echo "Read TASK.md. Create greeting.py per the spec. Use TodoWrite to create a todo for this work, update it to in_progress, then completed when done. Print CYCLE_OK as your last line." | claude --print --allowedTools "Read,Write,Edit,Bash,TodoRead,TodoWrite,Glob,Grep" 2>&1
```
