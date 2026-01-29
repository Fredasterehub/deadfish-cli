# deadfish-cli

**Autonomous dev pipeline for Claude Code CLI** · v2.4.2

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
![Bash](https://img.shields.io/badge/shell-bash-green)
![Python 3](https://img.shields.io/badge/python-3.x-blue)

---

## What It Is

deadfish-cli is the CLI-native port of the deadf(ish) autonomous development pipeline. It runs a strict loop — plan → implement → verify — with deterministic role separation across five actors, no bot framework or chat UI required. The controller (`ralph.sh`) drives cycles by invoking Claude Code CLI directly, capturing structured output, and gating merges through an automated verification step. Everything runs locally, everything is reproducible from filesystem artifacts.

---

## Actors

| Actor | Role | Implementation |
|-------|------|----------------|
| **Ralph** | Mechanical loop controller — kicks cycles, enforces timeouts, manages locks | `ralph.sh` (Bash) |
| **Orchestrator** | Reads state, dispatches work, updates STATE.yaml atomically | Claude Code (Opus 4.5) via `claude` CLI |
| **Planner** | Decomposes tasks into implementation plans | GPT-5.2 via Codex MCP |
| **Implementer** | Writes source code — the only actor that touches `src/` | GPT-5.2-Codex via `codex exec` |
| **Verifier** | Runs tests/lint/build, produces pass/fail verdict | `verify.sh` + LLM verifier |

---

## Quick Start

### Prerequisites

- **claude** CLI ≥ 1.0.0 ([install](https://docs.anthropic.com/en/docs/claude-code))
- **codex** CLI ([install](https://github.com/openai/codex))
- **python3** ≥ 3.10
- **bash** ≥ 4.0
- **yq** ([install](https://github.com/mikefarah/yq))

### Setup

```bash
# 1. Clone
git clone https://github.com/yourorg/deadfish-cli.git
cd deadfish-cli

# 2. Copy pipeline files into your target project
cp ralph.sh verify.sh extract_plan.py build_verdict.py /path/to/your/project/
cp CLAUDE.md POLICY.yaml /path/to/your/project/

# 3. Create STATE.yaml in your project (use the template)
cp templates/state-template.md /path/to/your/project/STATE.yaml
# Edit STATE.yaml: set your task, phase, and initial state

# 4. Configure MCP (in your project root)
cat > /path/to/your/project/.mcp.json << 'EOF'
{
  "mcpServers": {
    "codex": {
      "command": "codex",
      "args": ["mcp-server"]
    }
  }
}
EOF

# 5. Run
./ralph.sh /path/to/your/project
```

---

## How It Works

```
┌─────────────────────────────────────────────────┐
│                   ralph.sh                       │
│         (loop controller — mechanical)           │
└────────────────────┬────────────────────────────┘
                     │ DEADF_CYCLE <id>
                     ▼
┌─────────────────────────────────────────────────┐
│              Claude Code (Orchestrator)           │
│  reads STATE.yaml → decides action → dispatches  │
└───┬──────────────┬──────────────┬───────────────┘
    │              │              │
    ▼              ▼              ▼
┌────────┐  ┌───────────┐  ┌──────────┐
│ Planner│  │Implementer│  │ Verifier │
│ GPT-5.2│  │  Codex    │  │verify.sh │
└────┬───┘  └─────┬─────┘  └────┬─────┘
     │            │              │
     └────────────┴──────────────┘
                  │
                  ▼ CYCLE_OK / CYCLE_FAIL / DONE
┌─────────────────────────────────────────────────┐
│  ralph.sh parses tokens → updates lock/logs →    │
│  next cycle or stop                              │
└─────────────────────────────────────────────────┘
```

---

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `RALPH_TIMEOUT` | `600` | Cycle timeout in seconds |
| `RALPH_MAX_LOGS` | `50` | Max log files to retain |
| `RALPH_RATE_LIMIT` | `5` | Minimum seconds between cycles |
| `RALPH_MAX_FAILURES` | `10` | Consecutive failures before circuit break |
| `RALPH_SESSION` | `auto` | Session mode: `auto`, `fresh`, or `continue` |
| `RALPH_SESSION_MAX_AGE` | `3600` | Session expiry in seconds |
| `RALPH_MIN_CLAUDE` | `1.0.0` | Minimum claude CLI version required |

### Usage

```bash
ralph.sh <project_path> [mode]
```

- **`project_path`** — Path to your project root (must contain STATE.yaml)
- **`mode`** — Execution mode (default: `yolo`)

---

## Project Structure

```
deadfish-cli/
├── ralph.sh              # Loop controller (Bash)
├── verify.sh             # Verification gate (tests/lint/build)
├── extract_plan.py       # Plan parser
├── build_verdict.py      # Verdict builder
├── CLAUDE.md             # Orchestrator contract (v2.4.2)
├── POLICY.yaml           # Pipeline policy/constraints
├── VISION.md             # Project vision
├── ROADMAP.md            # Port roadmap
├── METHODOLOGY.md        # Design methodology
├── LICENSE               # MIT
├── examples/
│   └── project-structure.md
├── scripts/
│   └── update-changelog.sh
└── templates/            # Project scaffolding templates
    ├── state-template.md
    ├── task-template.md
    ├── roadmap-template.md
    ├── vision-template.md
    └── ...
```

---

## deadfish-cli vs deadfish-pipeline

| Aspect | deadfish-pipeline (Clawdbot) | deadfish-cli |
|--------|------------------------------|-------------|
| **Controller** | Clawdbot Discord bot | `ralph.sh` (local Bash) |
| **Orchestrator call** | `clawdbot session send` | `claude --print --dangerously-skip-permissions` |
| **Sub-agents** | `sessions_spawn` | Claude Code Task tool |
| **Implementer dispatch** | Codex via bot | `codex exec` / Codex MCP |
| **Instructions** | Custom bot config | `CLAUDE.md` (Claude Code native) |
| **Session continuity** | Bot session state | `--continue` flag + session file |
| **Notifications** | Discord messages | stdout + notification files |
| **Dependencies** | Node.js, Discord, Clawdbot | Bash, Python, claude CLI, codex CLI |

---

## License

[MIT](LICENSE)
