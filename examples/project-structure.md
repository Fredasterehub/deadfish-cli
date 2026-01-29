# Example Project Structure

What a deadf(ish) v2.4.2 project looks like after initialization.

## Project Layout

```
<project>/
├── .deadf/                 # Pipeline runtime state
│   ├── logs/               # Execution logs
│   ├── notifications/      # Notification queue
│   └── ralph.lock          # Lock file for ralph process
├── STATE.yaml              # Current pipeline state (machine-readable)
├── POLICY.yaml             # Project policy and constraints
├── CLAUDE.md               # Primary operational doc for Claude
├── VISION.md               # What we're building (constitution)
├── ROADMAP.md              # How we get there (themes + tracks)
├── TASK.md                 # Current task (generated per task)
├── ralph.sh                # Pipeline orchestrator script
├── extract_plan.py         # Plan extraction utility
├── build_verdict.py        # Verdict builder utility
├── verify.sh               # Verification runner
├── .mcp.json               # MCP server configuration
└── src/, tests/, etc.      # Your actual project code
```

## Key Differences from v1.x

- **No living doc templates** — patterns, pitfalls, glossary, etc. are gone
- **YAML state** — `STATE.yaml` replaces `STATE.md` for machine parsing
- **POLICY.yaml** — explicit policy file replaces `WORKFLOW.md`
- **CLAUDE.md** — single operational document for the AI agent
- **ralph.sh** — shell-based orchestrator replaces the old conductor model
- **Python utilities** — `extract_plan.py` and `build_verdict.py` handle plan/verdict logic
- **.deadf/ directory** — runtime state is isolated from project docs
