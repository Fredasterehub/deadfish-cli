# Task Schema

Strict schema for TASK.md. All fields required unless marked optional.

## XML Structure

```xml
<task id="{track-id}.{number}">
  <name>{Brief descriptive name}</name>
  
  <context>
    <track>{track-id}</track>
    <spec_ref>{path to spec.md}</spec_ref>
    <plan_ref>{path to plan.md}</plan_ref>
  </context>
  
  <files>
    <file action="create">{path}</file>
    <file action="modify">{path}</file>
    <file action="delete">{path}</file>
  </files>
  
  <action>
    {What to implement. Specific, unambiguous instructions.}
  </action>
  
  <source_refs>
    <!-- Required if task uses existing data/content -->
    <ref type="url">{source URL}</ref>
    <ref type="file">{source file path}</ref>
    <ref type="doc">{reference doc}</ref>
  </source_refs>
  
  <assumptions>
    <!-- What we assume to be true. Prevents scope creep. -->
    <assumption>{assumption 1}</assumption>
    <assumption>{assumption 2}</assumption>
  </assumptions>
  
  <non_goals>
    <!-- What this task explicitly does NOT do. -->
    <non_goal>{non-goal 1}</non_goal>
  </non_goals>
  
  <verify>
    <!-- Concrete, executable verification steps -->
    <step>
      <command>{shell command or action}</command>
      <expected>{expected output or state}</expected>
    </step>
  </verify>
  
  <done>
    <!-- Acceptance criteria. Binary pass/fail. -->
    <criterion contract="{clause-id}">{criterion text}</criterion>
  </done>
  
  <rollback>
    <!-- How to undo this task if needed -->
    <step>{rollback instruction}</step>
  </rollback>
</task>
```

## Field Definitions

### Required Fields

| Field | Description |
|-------|-------------|
| `id` | Unique task identifier (track.number format) |
| `name` | Brief descriptive name (< 60 chars) |
| `context.track` | Parent track ID |
| `context.spec_ref` | Path to track's spec.md |
| `context.plan_ref` | Path to track's plan.md |
| `files` | List of files to create/modify/delete |
| `action` | Implementation instructions |
| `verify` | Executable verification steps |
| `done` | Acceptance criteria with contract refs |
| `rollback` | How to undo the task |

### Conditionally Required

| Field | When Required |
|-------|---------------|
| `source_refs` | When task uses existing data, migrates content, or references external sources |
| `assumptions` | When task has implicit dependencies or constraints |
| `non_goals` | When scope boundaries need clarification |

## Validation Rules

1. **Source Fidelity**: If `source_refs` present, checker must verify sources were actually used
2. **Contract Citation**: Each `done.criterion` should reference a clause ID when applicable
3. **Executable Verify**: Each verify step must be runnable (command + expected output)
4. **Atomic Scope**: Task should be completable in one session, one commit
5. **No Orphans**: `context.track` must reference an existing track

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
    Implement POST /auth/register endpoint:
    - Accept email + password in request body
    - Hash password with bcrypt (10 rounds)
    - Create user in database via Prisma
    - Return 201 with user object (exclude password)
    - Return 400 if email already exists
  </action>
  
  <source_refs>
    <ref type="doc">Express middleware docs</ref>
    <ref type="doc">Prisma client docs</ref>
  </source_refs>
  
  <assumptions>
    <assumption>Database is PostgreSQL with Prisma configured</assumption>
    <assumption>Express app scaffold exists</assumption>
  </assumptions>
  
  <non_goals>
    <non_goal>Email verification (deferred to T01.04)</non_goal>
    <non_goal>Rate limiting (deferred to hardening)</non_goal>
  </non_goals>
  
  <verify>
    <step>
      <command>curl -X POST localhost:3000/auth/register -H "Content-Type: application/json" -d '{"email":"test@example.com","password":"test123"}'</command>
      <expected>201 status, JSON with id and email, no password field</expected>
    </step>
    <step>
      <command>curl -X POST localhost:3000/auth/register -H "Content-Type: application/json" -d '{"email":"test@example.com","password":"test123"}'</command>
      <expected>400 status, error message about duplicate email</expected>
    </step>
  </verify>
  
  <done>
    <criterion contract="SPEC.S1">Users can register with email/password</criterion>
    <criterion contract="WORKFLOW.W2">All verification steps pass</criterion>
    <criterion contract="PATTERNS.P1">Follows Express route pattern</criterion>
  </done>
  
  <rollback>
    <step>git revert HEAD</step>
    <step>npx prisma migrate reset (if schema changed)</step>
  </rollback>
</task>
```
