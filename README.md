<div align="center">
  <br>
  <h1>🐟 deadfish-cli</h1>
  <p><strong>Autonomous dev pipeline that plans, codes, verifies, and commits — while you sleep.</strong></p>

  <br>
  <em>"Only a dead fish follows the flow."</em>
  <br><br>

  [![License: MIT](https://img.shields.io/badge/License-MIT-blue?style=for-the-badge)](LICENSE)
  [![Bash](https://img.shields.io/badge/Bash-4.0+-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](#prerequisites)
  [![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=for-the-badge&logo=python&logoColor=white)](#prerequisites)
  [![Claude Code](https://img.shields.io/badge/Claude_Code-CLI-cc785c?style=for-the-badge&logo=anthropic&logoColor=white)](https://docs.anthropic.com/en/docs/claude-code)
  [![Codex](https://img.shields.io/badge/Codex-CLI-412991?style=for-the-badge&logo=openai&logoColor=white)](https://github.com/openai/codex)

  <br>
  <a href="#-quick-start">Quick Start</a> •
  <a href="#-how-it-works">How It Works</a> •
  <a href="#%EF%B8%8F-configuration">Configuration</a> •
  <a href="#-methodology">Methodology</a>
  <br><br>
</div>

---

## ✨ Highlights

- 🔄 **Fully autonomous loop** — Plan → Implement → Verify → Commit, no human in the loop
- 🧠 **Multi-model architecture** — GPT-5.2 plans, GPT-5.2-Codex implements, Claude Opus orchestrates
- 🔒 **Deterministic verification** — `verify.sh` gates every merge with tests, lint, and build checks
- 📁 **Zero hidden state** — Everything lives in filesystem artifacts. Reproducible from a fresh clone.
- 🛡️ **Strict role separation** — Five actors, each with one job. No actor exceeds its authority.
- ⏸️ **Pause & resume** — Stop mid-cycle, come back later with `--continue`. No lost context.
- 🏗️ **No framework required** — Pure Bash + Python + CLI tools. No Discord, no bots, no servers.

---

## 🎬 How a Cycle Looks

```
┌─────────────────────────────────────────────────────┐
│                     ralph.sh                         │
│           (loop controller — purely mechanical)      │
└──────────────────────┬──────────────────────────────┘
                       │ DEADF_CYCLE <id>
                       ▼
┌─────────────────────────────────────────────────────┐
│             Claude Code (Orchestrator)                │
│   reads STATE.yaml → decides action → dispatches     │
└────┬──────────────┬───────────────┬─────────────────┘
     │              │               │
     ▼              ▼               ▼
┌─────────┐  ┌────────────┐  ┌───────────┐
│ Planner  │  │Implementer │  │  Verifier  │
│ GPT-5.2  │  │GPT-5.2-Codex│ │ verify.sh  │
└────┬─────┘  └──────┬─────┘  └─────┬─────┘
     │               │              │
     └───────────────┴──────────────┘
                     │
                     ▼  CYCLE_OK / CYCLE_FAIL / DONE
┌─────────────────────────────────────────────────────┐
│  ralph.sh parses tokens → updates lock/logs →        │
│  next cycle or stop                                  │
└─────────────────────────────────────────────────────┘
```

Every cycle produces artifacts in `.deadf/logs/` — plans, verdicts, test output. Nothing is ephemeral.

---

## 🚀 Quick Start

### Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| **claude** CLI | ≥ 1.0.0 | [docs.anthropic.com](https://docs.anthropic.com/en/docs/claude-code) |
| **codex** CLI | latest | [github.com/openai/codex](https://github.com/openai/codex) |
| **python3** | ≥ 3.10 | System package manager |
| **bash** | ≥ 4.0 | Pre-installed on Linux/macOS |
| **yq** | v4.x | [github.com/mikefarah/yq](https://github.com/mikefarah/yq) |

### Setup (5 minutes)

```bash
# 1. Clone deadfish-cli
git clone https://github.com/yourorg/deadfish-cli.git

# 2. Copy pipeline files into your project
cd deadfish-cli
cp ralph.sh verify.sh extract_plan.py build_verdict.py /path/to/your/project/
cp CLAUDE.md POLICY.yaml /path/to/your/project/

# 3. Create your STATE.yaml
cp examples/project-structure.md /path/to/your/project/STATE.yaml
# Edit: set your task, phase, and initial state

# 4. Configure MCP (enables Codex tool access)
cat > /path/to/your/project/.mcp.json << 'EOF'
{
  "mcpServers": {
    "codex": { "command": "codex", "args": ["mcp-server"] }
  }
}
EOF

# 5. Run 🐟
./ralph.sh /path/to/your/project
```

> 💡 **That's it.** Ralph takes over from here — planning, coding, testing, committing. Check `.deadf/logs/` for what happened.

---

## 🎭 The Five Actors

deadfish-cli enforces strict role separation. Each actor has exactly one job and **cannot exceed its authority**.

| Actor | Role | Tool | Authority |
|:------|:-----|:-----|:----------|
| 🔧 **Ralph** | Loop controller — kicks cycles, enforces timeouts, manages locks | `ralph.sh` | Writes `phase → needs_human` and `cycle.status → timed_out` ONLY |
| 🧠 **Orchestrator** | Reads state, decides what to do, dispatches work | Claude Code (Opus 4.5) | Reads/writes STATE.yaml, dispatches sub-tasks |
| 📋 **Planner** | Decomposes work into implementation plans | GPT-5.2 via Codex MCP | Writes plans to `.pipe/` — never touches `src/` |
| ⚡ **Implementer** | Writes source code — the **only** actor that touches `src/` | GPT-5.2-Codex | Writes code files, nothing else |
| ✅ **Verifier** | Runs tests/lint/build, produces pass/fail verdict | `verify.sh` + LLM | Read-only on source; writes verdicts |

> ⚠️ **The Implementer is the only actor that writes code.** The Orchestrator never codes. The Planner never codes. This is non-negotiable.

---

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|:---------|:--------|:------------|
| `RALPH_TIMEOUT` | `600` | Cycle timeout in seconds |
| `RALPH_MAX_LOGS` | `50` | Max log files to retain |
| `RALPH_RATE_LIMIT` | `5` | Min seconds between cycles |
| `RALPH_MAX_FAILURES` | `10` | Consecutive failures before circuit break |
| `RALPH_SESSION` | `auto` | Session mode: `auto` · `fresh` · `continue` |
| `RALPH_SESSION_MAX_AGE` | `3600` | Session expiry in seconds |
| `RALPH_MIN_CLAUDE` | `1.0.0` | Min claude CLI version required |
| `RALPH_DISPATCH_CMD` | — | **Required.** Orchestrator dispatch command |

### Execution Modes

Defined in `POLICY.yaml`, set in `STATE.yaml`:

| Mode | Behavior | Best For |
|:-----|:---------|:---------|
| 🟢 **yolo** | Full autonomy. Runs until done or stuck. | Overnight runs, trusted tasks |
| 🟡 **hybrid** | Autonomous within tracks; asks approval at boundaries. | Normal development |
| 🔴 **interactive** | Human approves every task. Maximum oversight. | Critical changes, learning |

---

## 📁 Project Structure

```
your-project/
├── ralph.sh              # 🔧 Loop controller
├── verify.sh             # ✅ Verification gate
├── extract_plan.py       # 📋 Plan parser
├── build_verdict.py      # ✅ Verdict builder
├── CLAUDE.md             # 🧠 Orchestrator instructions (v2.4.2)
├── POLICY.yaml           # 🛡️ Pipeline policy & constraints
├── STATE.yaml            # 📊 Current position (track, task, status)
├── VISION.md             # 🎯 Problem statement & scope
├── ROADMAP.md            # 🗺️ Themes & upcoming tracks
├── .mcp.json             # 🔌 MCP server config
├── .deadf/
│   ├── logs/             # 📝 Execution logs per cycle
│   ├── notifications/    # 🔔 Human-attention queue
│   └── ralph.lock        # 🔒 Prevents concurrent runs
└── src/                  # Your actual code
```

---

## 📖 Methodology

### The Loop

```
ROADMAP → select track → plan tasks → TASK LOOP:
  generate TASK.md → execute → verify → commit → next task
→ mark track complete → next track
```

### Core Principles

1. **Plan incrementally** — One track (feature/fix) at a time
2. **Execute atomically** — One task = one commit = one verification
3. **Verify everything** — Every task has explicit pass/fail criteria
4. **State is YAML** — Machine-readable, diffable, unambiguous

### Verification Logic

The verification gate combines deterministic checks with LLM review:

| `verify.sh` | LLM Review | → Result |
|:------------|:-----------|:---------|
| ❌ FAIL | *(any)* | **FAIL** — always trust the tests |
| ✅ PASS | ❌ FAIL | **FAIL** — conservative gate |
| ✅ PASS | ⚠️ HUMAN | **PAUSE** — needs human eyes |
| ✅ PASS | ✅ PASS | **PASS** — ship it |
| *(parse error)* | *(after retry)* | **NEEDS_HUMAN** — escalate |

### Escalation Thresholds

| Threshold | Default | What Happens |
|:----------|:--------|:-------------|
| Stuck cycles | 3 | Consecutive no-progress → escalation |
| Task retries | 3 | Failures → rollback + rescue branch |
| Max iterations | 200 | Ralph exits gracefully |
| Time budget | 24h | Hard stop |
| Cycle timeout | 600s | Individual cycle killed |

---

## 🔀 deadfish-cli vs deadfish-pipeline

| Aspect | deadfish-pipeline | deadfish-cli |
|:-------|:------------------|:-------------|
| **Controller** | Clawdbot Discord bot | `ralph.sh` (local Bash) |
| **Orchestrator** | `clawdbot session send` | `claude --print` |
| **Sub-agents** | `sessions_spawn` | Claude Code Task tool |
| **Implementer** | Codex via bot | `codex exec` / Codex MCP |
| **Instructions** | Custom bot config | `CLAUDE.md` (native) |
| **Session state** | Bot session state | `--continue` + session file |
| **Notifications** | Discord messages | stdout + files |
| **Dependencies** | Node.js, Discord, Clawdbot | Bash, Python, claude, codex |

> 💡 **Same pipeline, minus the infrastructure.** Same methodology, same verification rigor, same actor model — just runs locally with CLI tools.

---

## 🗺️ Roadmap

- [x] Copy identical components (extract_plan, build_verdict, verify)
- [x] Rewrite CLAUDE.md for Claude Code CLI
- [x] Port ralph.sh loop controller
- [ ] Template cleanup + MCP config
- [ ] Integration test (full end-to-end cycle)
- [ ] Native Claude Code Task Management integration
- [ ] CI runner support

---

## 🤝 Contributing

Contributions welcome! The pipeline is designed to be extensible:

1. Fork the repo
2. Create your branch (`git checkout -b feat/your-feature`)
3. Commit changes (`git commit -m 'feat: add your feature'`)
4. Push (`git push origin feat/your-feature`)
5. Open a Pull Request

> ⚠️ **Use deadfish-cli to develop deadfish-cli.** Yes, it's recursive. Yes, it works.

---

## 🤖 For LLMs / AI Agents

**Quick context for AI assistants helping users with this project:**

> deadfish-cli is an autonomous dev pipeline that runs a plan → implement → verify → commit loop using CLI tools. It uses Bash (ralph.sh) as loop controller, Claude Code CLI as orchestrator, GPT-5.2 via Codex MCP as planner, and GPT-5.2-Codex as implementer. The entry point is `ralph.sh <project_path>`.

### Key files to read first
- `CLAUDE.md` — Orchestrator contract defining all agent behavior, phases, and sentinel protocol
- `ralph.sh` — Loop controller: cycle dispatch, timeouts, locks, log rotation
- `POLICY.yaml` — Execution modes (yolo/hybrid/interactive), escalation thresholds, rollback policy
- `STATE.yaml` — Current pipeline position: active track, task, phase, iteration count
- `verify.sh` — Verification gate: runs tests, lint, build; produces structured JSON verdict

### Common tasks
- **Run pipeline:** `./ralph.sh /path/to/project [mode]`
- **Check state:** `cat STATE.yaml | yq .`
- **View logs:** `ls .deadf/logs/`
- **Run verification only:** `./verify.sh`

### Architecture in one paragraph
Ralph (bash) runs an infinite loop: each cycle it dispatches to Claude Code CLI which reads STATE.yaml, decides the next action, and delegates to either GPT-5.2 (planning via Codex MCP) or GPT-5.2-Codex (implementation via codex exec). After implementation, verify.sh runs deterministic checks (tests/lint/build) and an LLM reviewer produces a combined verdict. On PASS, the orchestrator commits and advances state. On FAIL, it retries or escalates. All state lives in YAML files and all artifacts persist to `.deadf/logs/`.

> 📄 See [`llms.txt`](llms.txt) for the full machine-readable project context.

---

## 📄 License

[MIT](LICENSE) © deadfish contributors

---

<div align="center">
  <sub>Built by an autonomous pipeline that builds autonomous pipelines. 🐟</sub>
</div>
