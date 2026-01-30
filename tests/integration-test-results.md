# Integration Test: Task Management (Track 7.3)

## Test 1: Claude Code 2.1.23 (without ENABLE_TASKS)
- File Creation: ✅ PASS
- CYCLE_OK Signal: ✅ PASS
- Tasks Created: ❌ FAIL — uses old TodoWrite, cleared on exit
- Tasks Persisted: ❌ FAIL — JSON contains [] after session ends
- CLAUDE_CODE_TASK_LIST_ID: ❌ No effect — todos use session UUID

## Test 2: Claude Code 2.1.25 (without ENABLE_TASKS)
- Same results as 2.1.23 — old Todo system still active

## Test 3: Claude Code 2.1.25 (with CLAUDE_CODE_ENABLE_TASKS=1) ✅
- File Creation: ✅ PASS — greeting.py created and runs
- CYCLE_OK Signal: ✅ PASS — last line of stdout
- Tasks Created: ✅ PASS — ~/.claude/tasks/deadf-task-test-v3/1.json
- Task Content: ✅ PASS — id, subject, description, status=completed, blocks, blockedBy
- Tasks Persisted: ✅ PASS — JSON retains data after claude exits
- TASK_LIST_ID: ✅ PASS — tasks stored under named directory matching ID

## Key Finding
**CLAUDE_CODE_ENABLE_TASKS=1 is REQUIRED** to activate the native Task system.
Without it, Claude Code falls back to ephemeral Todos even on 2.1.25.

## Task JSON Structure (verified)
```json
{
    "id": "1",
    "subject": "Create greeting.py per TASK.md spec",
    "description": "Create greeting.py that prints \"Hello from deadf(ish) Tasks v2!\"",
    "activeForm": "Creating greeting.py",
    "status": "completed",
    "blocks": [],
    "blockedBy": []
}
```
