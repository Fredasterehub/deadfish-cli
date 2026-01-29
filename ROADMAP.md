# ROADMAP.md — deadfish-cli port

```yaml
version: "v2.4.2-port"
project: "deadfish-cli"
from: "deadfish-pipeline (Clawdbot Discord bot)"
to: "Claude Code CLI (Claude CLI + Codex)"
goal: "Port the deadf(ish) autonomous development pipeline to a local CLI workflow with deterministic verification."

tracks:
  - id: 1
    name: "Copy identical components"
    goal: "Bring over unchanged pipeline parts."
    deliverables:
      - "extract_plan.py"
      - "build_verdict.py"
      - "verify.sh"
      - "STATE.yaml"
      - "POLICY.yaml"
      - ".gitignore"
    steps:
      - "Copy files verbatim; preserve paths and line endings."
      - "Run quick sanity checks (python -m py_compile; shellcheck if present)."
    done_when:
      - "Files exist in deadfish-cli and behave identically on representative inputs."

  - id: 2
    name: "Rewrite CLAUDE.md for Claude Code"
    goal: "Adapt the v2.4.2 iteration/orchestrator contract to Claude Code CLI."
    contract_updates:
      - "Use Claude Code Task tool semantics (no sessions_spawn)."
      - "Emit progress/verdicts to stdout (no Discord notifications)."
      - "Document exact claude CLI invocation and required flags."
    done_when:
      - "CLAUDE.md fully describes loop inputs/outputs, constraints, and stop conditions for CLI use."

  - id: 3
    name: "Port ralph.sh loop controller"
    goal: "Replace Clawdbot send calls with local Claude CLI execution."
    required_change:
      from: "clawdbot session send"
      to: "claude --print --dangerously-skip-permissions"
    steps:
      - "Implement prompt assembly + file IO compatible with CLAUDE.md."
      - "Capture stdout/stderr; persist artifacts for sentinel + verifier."
      - "Return deterministic exit codes for success/fail/abort."
    done_when:
      - "ralph.sh runs a single iteration and a multi-iteration loop reliably on a sample task."

  - id: 4
    name: "Update README.md for v2.4.2 (Claude Code)"
    goal: "Document installation and usage for the CLI port."
    include:
      - "Prereqs: claude CLI, python, bash; any env vars."
      - "Quickstart: run ralph.sh; where outputs/logs live."
      - "How verify.sh gates merges; how to interpret verdicts."
      - "Troubleshooting: permissions, timeouts, deterministic failures."
    done_when:
      - "A fresh checkout can be run end-to-end using only README instructions."

  - id: 5
    name: "Template cleanup + MCP config"
    goal: "Remove Clawdbot/Discord remnants; add Codex MCP config."
    deliverables:
      - ".mcp.json (Codex MCP server config)"
    steps:
      - "Delete/archivize unused Discord templates and bot glue."
      - "Add minimal .mcp.json enabling required MCP tools for the workflow."
    done_when:
      - "Repo contains only CLI-relevant templates; MCP config is present and documented."

  - id: 6
    name: "Integration test (full cycle)"
    goal: "Prove the pipeline runs end-to-end deterministically."
    test_plan:
      - "Run ralph.sh on a small, deterministic task."
      - "Validate extract_plan.py output; build_verdict.py verdict consistency."
      - "Ensure verify.sh passes/fails exactly as expected."
      - "Confirm STATE.yaml updates and policy enforcement across iterations."
    done_when:
      - "One full cycle completes; artifacts are reproducible; verifier outcome matches verdict."

milestones:
  - "M1: Track 1 complete (identical components in place)."
  - "M2: Tracks 2+3 complete (contract + loop operational)."
  - "M3: Tracks 4+5 complete (docs + cleanup + MCP ready)."
  - "M4: Track 6 complete (end-to-end green run)."

risks:
  - "Non-determinism from model variability impacting verify.sh gating."
  - "CLI permission/flag differences causing missing artifacts or truncated outputs."
  - "Contract drift between CLAUDE.md and ralph.sh behavior."

definition_of_done:
  - "All tracks done_when satisfied; README quickstart works; integration test reproducibly passes."
```
