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

**Preflight Detection** — Auto-detect scenario before proceeding:
- **Greenfield** (no docs, no code) → Brainstorm flow (existing)
- **Brownfield** (no docs, has code) → Interactive mapping → seamless brainstorm transition
- **Returning** (has docs: VISION.md etc.) → Restart / Refine / Continue

Heuristics (brownfield = 2+ signals): `.git/` exists, source files present, `package.json`/`go.mod`/etc., CI config, README.

Creates (all scenarios converge to):
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

#### Greenfield Flow
No code detected → proceed directly to `/deadf:brainstorm`.

#### Brownfield Flow
Code detected, no living docs → interactive mapping:

1. **Existing doc intake**: Read README, CONTRIBUTING, etc. Distill as *hints* — question, don't trust. Present summary: "Here's what I found. Correct me."
2. **Dynamic analysis depth**: Orchestrator decides 1–4 analysis passes based on codebase complexity:
   - Pass 1: General structure (entry points, framework, deps) — always
   - Pass 2: Architecture patterns (routing, data layer, auth) — medium+ projects
   - Pass 3: Testing/CI/deployment — if CI config exists
   - Pass 4: Domain model deep-dive — large/complex codebases
3. **Git history signals**: `git log --stat` for hot files (recent churn) vs stale files. Weight confidence by activity.
4. **Structured per-category confirmation**: Present findings category by category (stack, patterns, risks, etc.). User confirms/corrects each before proceeding.
5. **Seamless transition**: After mapping, ask "What do you want to work on?" — flows into brainstorm for VISION completion or directly to `/deadf:track` if vision is clear.

#### Returning Flow
Living docs detected (VISION.md exists) → offer:
- **Restart**: Wipe docs, start fresh
- **Refine**: Update specific docs (e.g., stack changed, new patterns)
- **Continue**: Load STATE.md, resume where left off

#### Agent Failure Handling
If any analysis pass fails or produces low-confidence results:
- Show partial results with confidence markers
- Offer retry for failed category
- Fallback: skip to interactive brainstorm (user provides info manually)
- Never block the pipeline on a failed mapper

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

## Context Budget

ALL living docs combined MUST stay under **5000 tokens**. Machine-optimized YAML format, not prose.

### Token Targets

| Doc | Budget |
|-----|--------|
| VISION.md | 300t |
| ROADMAP.md | 500t |
| STATE.md | 200t |
| TECH_STACK.md | 400t |
| PATTERNS.md | 400t |
| PITFALLS.md | 300t |
| RISKS.md | 300t |
| WORKFLOW.md | 400t |
| PRODUCT.md | 400t |
| GLOSSARY.md | 200t |

### Smart Loading (per track type)

Only load docs relevant to the current track (~1500–2000t per session):

| Track Type | Load |
|------------|------|
| UI/frontend | VISION, PATTERNS, WORKFLOW |
| API/backend | VISION, PATTERNS, TECH_STACK |
| Database | VISION, TECH_STACK, PRODUCT |
| Auth/security | VISION, PATTERNS, RISKS |
| Refactor | VISION, PITFALLS, PATTERNS |
| Ambiguous | VISION, PATTERNS, RISKS, PITFALLS |

### Compression Principle

If a doc exceeds its budget: compress, don't split. Remove examples, collapse tables, use YAML shorthand. Split into a separate file only when a section exceeds 500t on its own.

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
