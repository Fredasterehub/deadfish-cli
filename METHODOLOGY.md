# deadf(ish) Methodology — v2.4.2

## Overview

deadf(ish) is a development pipeline for AI-assisted software projects.
It enforces incremental planning, atomic execution, and structured verification.

**Primary operational document: `CLAUDE.md`** — that file contains everything
the AI agent needs to operate within a deadf(ish) project. This methodology
doc provides background context only.

---

## Core Principles

1. **Plan incrementally** — one track (feature/fix) at a time
2. **Execute atomically** — one task = one commit = one verification
3. **Verify everything** — every task has explicit pass/fail criteria
4. **State is YAML** — machine-readable, diffable, unambiguous

## Architecture

### Pipeline Components

| Component | Purpose |
|-----------|---------|
| `ralph.sh` | Orchestrator — runs the task loop |
| `extract_plan.py` | Parses plans into executable task sequences |
| `build_verdict.py` | Evaluates verification output into pass/fail |
| `verify.sh` | Runs verification commands for the current task |

### State Files

| File | Purpose |
|------|---------|
| `STATE.yaml` | Current position: active track, task, status |
| `POLICY.yaml` | Project constraints and rules |
| `CLAUDE.md` | Agent instructions and operational context |
| `VISION.md` | Problem statement and scope (constitution) |
| `ROADMAP.md` | Themes and upcoming tracks |
| `TASK.md` | Current task details (generated per task) |

### Runtime Directory

```
.deadf/
├── logs/            # Execution logs per task
├── notifications/   # Queue for human-attention items
└── ralph.lock       # Prevents concurrent pipeline runs
```

## Workflow

```
ROADMAP → select track → plan tasks → TASK LOOP:
  generate TASK.md → execute → verify → commit → next task
→ mark track complete → next track
```

Each task is atomic. If verification fails, the task is retried or escalated.
Ralph manages this loop automatically.

## MCP Integration

Projects include `.mcp.json` for Model Context Protocol server configuration.
This enables tool-augmented AI workflows (e.g., Codex as an MCP server).

---

*For operational details, see `CLAUDE.md` in any deadf(ish) project.*
*For the CLI tool itself, see `README.md`.*
