# CLAUDE.md - deadf(ish) Pipeline Instructions

You are operating the **deadf(ish)** development pipeline - a hybrid GSD + Conductor workflow with learning loops.

## Setup: Multi-Model via Codex MCP

For full multi-model support (GPT-5.2 for planning/reflection, GPT-5.2-Codex for implementation):

### 1. Configure Claude Code MCP

Create `.mcp.json` in your project root:

```json
{
  "mcpServers": {
    "codex": {
      "command": "codex",
      "args": ["mcp-server"]
    }
  }
}
```

Verify with: `claude mcp list` or `/mcp` in Claude Code session.

### 2. Available MCP Tools

| Tool | Purpose | Key Parameters |
|------|---------|----------------|
| `codex` | Start new Codex session | `prompt` (required), `model`, `cwd`, `sandbox` |
| `codex-reply` | Continue conversation | `threadId`, `prompt` |

### 3. Calling Codex

**For GPT-5.2 (planning/analysis):**
```
Use MCP tool "codex" with:
- prompt: "Your task here"
- model: "gpt-5.2"
- cwd: "/path/to/project"
```

**For GPT-5.2-Codex (implementation):**
```
Use MCP tool "codex" with:
- prompt: "Implement X per TASK.md"
- model: "gpt-5.2-codex"
- sandbox: "workspace-write"
- cwd: "/path/to/project"
```

### Model Assignments

| Role | Model | How |
|------|-------|-----|
| Orchestrator | Claude (you) | Native |
| Research | Claude + GPT-5.2 (parallel) | Native + MCP `codex` |
| Planner | GPT-5.2 | MCP `codex` |
| Checker | Claude | Native |
| Executor | GPT-5.2-Codex | MCP `codex` |
| Reflector | Claude + GPT-5.2 (parallel) | Native + MCP `codex` |

---

## Philosophy

- **Plan incrementally** - One track at a time, not all phases upfront
- **Execute atomically** - One task, one commit, one verification
- **Reflect on ALL outcomes** - Success, failure, AND escalation
- **Evolve documentation** - Living docs updated after each success

## Commands

### `/deadf:init <name>`
Initialize a new project with deadf(ish) structure.

Creates:
```
<name>/
├── VISION.md
├── PRODUCT.md
├── TECH_STACK.md
├── WORKFLOW.md
├── PATTERNS.md
├── PITFALLS.md
├── RISKS.md
├── GLOSSARY.md
├── ROADMAP.md
├── STATE.md
├── tracks.md
└── tracks/
```

### `/deadf:brainstorm`
Interactive vision discovery session. Guides through:
1. Problem → Who feels it → Consequences
2. Users → Needs → Journey
3. Solution → Mechanism → Differentiator
4. Success metrics
5. MVP scope (in/out/never)

Output: Completed VISION.md

### `/deadf:research`
Research phase for current project.

**Parallel Research** (with Codex MCP):
1. You (Claude) research via web search
2. Simultaneously call GPT-5.2 via MCP tool `codex`:
   ```json
   {
     "prompt": "Research best practices for [project type]: stack options, patterns, common pitfalls, potential risks. Output structured findings.",
     "model": "gpt-5.2",
     "cwd": "/path/to/project"
   }
   ```
3. Merge findings, note disagreements in disagreement register

**Steps:**
1. Parallel research (Claude + GPT-5.2)
2. Document findings
3. Create disagreement register if sources conflict
4. Seed living docs (TECH_STACK, PATTERNS, PITFALLS, RISKS)

### `/deadf:track <name>`
Start a new track (feature/fix):
1. Create `tracks/<id>/spec.md` from VISION + living docs
2. Get approval on spec
3. Create `tracks/<id>/plan.md` with task breakdown
4. Get approval on plan
5. Update STATE.md with active track

### `/deadf:task`
Generate next TASK.md from current track's plan.

Task includes:
- Context (track, spec, plan refs)
- Files to create/modify
- Action (implementation instructions)
- Verify (executable test steps)
- Done (acceptance criteria)
- Rollback (how to undo)

### `/deadf:execute`
Execute the current TASK.md:
1. Call GPT-5.2-Codex via MCP tool `codex`:
   ```json
   {
     "prompt": "Read TASK.md and implement the task. Follow PATTERNS.md for architecture and WORKFLOW.md for process. Commit when done.",
     "model": "gpt-5.2-codex",
     "sandbox": "workspace-write",
     "cwd": "/path/to/project"
   }
   ```
2. Run verification steps from TASK.md
3. If pass → commit with proper format
4. If fail → debug and retry

### `/deadf:verify`
Verify current task against:
- WORKFLOW.md (definition of done)
- PATTERNS.md (architecture expectations)
- Track spec (acceptance criteria)
- Source fidelity (if using existing data)

### `/deadf:reflect`
Post-task reflection. Run after EVERY outcome.

**Parallel Analysis** (with Codex MCP):
1. You (Claude) analyze the outcome
2. Simultaneously call GPT-5.2 via MCP tool `codex`:
   ```json
   {
     "prompt": "Analyze this task outcome: [success/failure/escalation]. Review what happened. What patterns should be documented? What pitfalls discovered? Any systemic risks? Output as diff proposals for PATTERNS.md, PITFALLS.md, or RISKS.md.",
     "model": "gpt-5.2",
     "cwd": "/path/to/project"
   }
   ```
3. Merge both analyses into unified diff proposals

**On success:**
- Did we use a new approach? → Log as experimental pattern
- Validate experimental pattern twice? → Promote to PATTERNS.md

**On failure:**
- What was root cause?
- One-off mistake → Add to PITFALLS.md
- Systemic issue → Add to RISKS.md

**On escalation:**
- Why couldn't this resolve?
- Missing contract clause → Propose addition
- Ambiguous clause → Propose clarification

Output: Diff proposals (not prose) for living doc updates.

### `/deadf:status`
Show current position:
- Active track and task
- Progress (tasks done / total)
- Blockers
- Next recommended action

### `/deadf:next`
Shortcut: task → execute → verify → reflect in one flow.

---

## Document Hierarchy

| Layer | Documents | Updates |
|-------|-----------|---------|
| **Constitution** | VISION.md | Only via explicit pivot |
| **Living Docs** | PRODUCT, TECH_STACK, WORKFLOW, PATTERNS, PITFALLS, RISKS, GLOSSARY | After successful tasks |
| **Execution** | STATE.md, TASK.md, ROADMAP.md | Continuously |
| **Tracks** | tracks/<id>/spec.md, plan.md, log.md | Per track |

## Validation Rules

### 3-Try Rule
All validation: max 3 iterations, then escalate to user.

### Clarification Step
Before iterating, can ask for clarification (doesn't count toward 3 tries).

### Contract Citation
When rejecting/disputing, cite specific clause:
- `VISION.V1`, `WORKFLOW.W3`, `PATTERNS.P2`, `SPEC.S1`, etc.
- No citation = discretionary = default to original proposal

## Commit Format

```
{type}({scope}): {description}

{body - reference task ID}
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`

## Key Principles

1. **Don't skip steps** - Each phase exists for a reason
2. **Reflect on failures** - Most learning comes from what went wrong
3. **Diffs not prose** - Doc updates as concrete patches
4. **Cite contracts** - Disputes reference specific clauses
5. **One task, one commit** - Atomic, traceable changes

---

*deadf(ish) - GSD + Conductor hybrid pipeline*
*"Plan incrementally, execute atomically, reflect always"*
