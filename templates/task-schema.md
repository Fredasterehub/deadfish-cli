# Task Schema

Strict schema for TASK.md. XML format.

## Required Fields

| Field | Description |
|-------|-------------|
| `id` | `{track-id}.{number}` |
| `name` | < 60 chars |
| `context` | track, spec_ref, plan_ref |
| `files` | create/modify/delete with paths |
| `action` | unambiguous implementation instructions |
| `verify` | executable command + expected output |
| `done` | binary criteria with contract clause refs |
| `rollback` | undo steps |

## Conditionally Required

| Field | When |
|-------|------|
| `source_refs` | using existing data/content |
| `assumptions` | implicit dependencies |
| `non_goals` | scope needs clarification |

## Validation Rules

1. **Source fidelity**: if `source_refs` present, checker verifies usage
2. **Contract citation**: `done` criteria reference clause IDs
3. **Executable verify**: each step must be runnable
4. **Atomic scope**: one session, one commit
5. **No orphans**: track must exist

## Example

```xml
<task id="T01-auth-system.02">
  <name>Add user registration endpoint</name>
  <context>
    <track>T01-auth-system</track>
    <spec_ref>tracks/T01-auth-system/spec.md</spec_ref>
    <plan_ref>tracks/T01-auth-system/plan.md</plan_ref>
  </context>
  <files>
    <file action="create">src/routes/auth.ts</file>
    <file action="create">src/services/auth.service.ts</file>
    <file action="modify">prisma/schema.prisma</file>
  </files>
  <action>
    POST /auth/register: accept email+password, bcrypt hash (10 rounds),
    create via Prisma, return 201 (no password), 400 on duplicate.
  </action>
  <verify>
    <step>
      <command>curl -X POST localhost:3000/auth/register -H "Content-Type: application/json" -d '{"email":"test@example.com","password":"test123"}'</command>
      <expected>201, JSON with id+email, no password</expected>
    </step>
    <step>
      <command>curl -X POST localhost:3000/auth/register -H "Content-Type: application/json" -d '{"email":"test@example.com","password":"test123"}'</command>
      <expected>400, duplicate email error</expected>
    </step>
  </verify>
  <done>
    <criterion contract="SPEC.S1">Users can register with email/password</criterion>
    <criterion contract="WORKFLOW.W2">All verify steps pass</criterion>
  </done>
  <rollback>
    <step>git revert HEAD</step>
  </rollback>
</task>
```
