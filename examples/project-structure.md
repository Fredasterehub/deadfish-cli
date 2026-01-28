# Example Project Structure

What a deadf(ish) project looks like after initialization.

## Fresh Project (after `/deadf:init`)

```
myproject/
├── VISION.md           # Empty template, fill via /deadf:brainstorm
├── PRODUCT.md          # Empty template
├── TECH_STACK.md       # Empty template
├── WORKFLOW.md         # Populated with default rules
├── PATTERNS.md         # Empty, will grow with project
├── PITFALLS.md         # Empty, will grow from failures
├── RISKS.md            # Empty, will grow from analysis
├── GLOSSARY.md         # Basic terms defined
├── ROADMAP.md          # Empty template
├── STATE.md            # Initialized to "no active track"
├── tracks.md           # Empty track index
└── tracks/             # Empty folder
```

## After Brainstorm + Research

```
myproject/
├── VISION.md           # Filled with problem, users, MVP scope
├── PRODUCT.md          # Goals and metrics from vision
├── TECH_STACK.md       # Stack decisions from research
├── WORKFLOW.md         # Default rules
├── PATTERNS.md         # Initial patterns from research
├── PITFALLS.md         # Known pitfalls from research
├── RISKS.md            # Identified risks
├── GLOSSARY.md         # Project-specific terms added
├── ROADMAP.md          # Themes and first tracks identified
├── STATE.md            # Ready for first track
├── tracks.md           # First tracks listed
└── tracks/
```

## Mid-Project (Track 2, Task 3)

```
myproject/
├── VISION.md           # Unchanged (constitution)
├── PRODUCT.md          # Updated after T01 learnings
├── TECH_STACK.md       # Added library decision in T01
├── WORKFLOW.md         # Unchanged
├── PATTERNS.md         # 2 blessed patterns, 1 experimental
├── PITFALLS.md         # 3 pitfalls from T01 failures
├── RISKS.md            # 1 risk identified
├── GLOSSARY.md         # 2 terms added
├── ROADMAP.md          # T01 complete, T02 active, T03-T04 planned
├── STATE.md            # Track: T02, Task: 03, Status: executing
├── TASK.md             # Current task details
├── tracks.md           # T01 ✅, T02 🔄, T03 ⬜, T04 ⬜
├── tracks/
│   ├── T01-auth-system/
│   │   ├── spec.md     # Frozen
│   │   ├── plan.md     # All tasks ✅
│   │   └── log.md      # 5 learnings logged
│   └── T02-receipt-upload/
│       ├── spec.md     # Approved
│       ├── plan.md     # 2/5 tasks done
│       └── log.md      # 2 entries
└── pivots/             # Empty (no pivots needed yet)
```

## Example TASK.md

```xml
<task id="T02-receipt-upload.03">
  <name>Add file validation</name>
  
  <context>
    <track>T02-receipt-upload</track>
    <spec_ref>tracks/T02-receipt-upload/spec.md</spec_ref>
    <plan_ref>tracks/T02-receipt-upload/plan.md</plan_ref>
  </context>
  
  <files>
    <file action="create">src/validators/file.ts</file>
    <file action="modify">src/routes/upload.ts</file>
  </files>
  
  <action>
    Add file validation before upload:
    - Check file type (jpg, png, pdf only)
    - Check file size (max 10MB)
    - Return 400 with specific error if invalid
  </action>
  
  <assumptions>
    <assumption>multer middleware already configured</assumption>
  </assumptions>
  
  <non_goals>
    <non_goal>Virus scanning (deferred to T04)</non_goal>
  </non_goals>
  
  <verify>
    <step>
      <command>curl -X POST localhost:3000/upload -F "file=@test.exe"</command>
      <expected>400 status, error: "Invalid file type"</expected>
    </step>
    <step>
      <command>curl -X POST localhost:3000/upload -F "file=@large.jpg"</command>
      <expected>400 status, error: "File too large"</expected>
    </step>
    <step>
      <command>curl -X POST localhost:3000/upload -F "file=@valid.jpg"</command>
      <expected>200 status, upload successful</expected>
    </step>
  </verify>
  
  <done>
    <criterion contract="SPEC.S2">Invalid files rejected with clear error</criterion>
    <criterion contract="WORKFLOW.W2">All verify steps pass</criterion>
  </done>
  
  <rollback>
    <step>git revert HEAD</step>
  </rollback>
</task>
```

## Example Track Log Entry

```markdown
## 2026-01-28: Learning - T02.02

**Outcome**: ❌ Failure

### What Happened
File upload worked locally but failed in CI due to missing tmp directory.

### What We Learned
CI environment doesn't have /tmp writable by default. Need explicit upload directory config.

### Doc Updates
- [x] PITFALLS.md: Added PF4 - CI temp directory
- [ ] PATTERNS.md: Not applicable
- [ ] RISKS.md: Not applicable
```
