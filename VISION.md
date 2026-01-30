# VISION.md — deadfish-cli

```yaml
vision_yaml<=300t:
problem:
  why: "Enable autonomous coding loops without Clawdbot/Discord dependencies."
  pain: ["bot coupling", "session plumbing overhead", "non-CLI workflows", "harder local iteration"]
solution:
  what: "CLI-native deadf(ish) autonomous dev pipeline using Claude Code CLI as orchestrator."
  loop_roles: ["ralph.sh controller", "Claude Code orchestrator", "GPT-5.2 planner", "GPT-5.2-Codex implementer", "verify.sh + LLM verifier"]
users:
  primary: "Developers running Claude Code CLI for repo-local autonomous work."
  environments: ["local dev", "CI runners", "headless servers"]
key_differentiators_vs_deadfish_pipeline:
  - "ralph.sh calls `claude --print --dangerously-skip-permissions` (no clawdbot session send)."
  - "Sub-agents use Claude Code native Task tool (no `sessions_spawn`)."
  - "Model dispatch: `codex exec` for one-shots; Codex MCP for interactive debugging."
  - "Instruction source: `CLAUDE.md` (Claude Code native)."
  - "Session continuity via `--continue` flag."
  - "Notifications to stdout + notification files (no Discord)."
mvp_scope:
  in:
    - "End-to-end autonomous loop parity with deadfish-pipeline core behaviors."
    - "Deterministic role separation + handoffs across planner/implementer/verifier."
    - "Local session persistence + resume via `--continue`."
    - "Artifacted notifications/logs suitable for CI and humans."
    - "Native Claude Code Task Management integration (TaskCreate/TaskGet/TaskUpdate/TaskList)"
    - "Dependency graph for cycle sub-steps (generate → implement → verify → reflect)"
    - "Multi-session persistence via CLAUDE_CODE_TASK_LIST_ID"
    - "Hybrid state: Tasks for workflow tracking + STATE.yaml for pipeline config + sentinel for LLM comms"
  out:
    - "Discord/Clawdbot integration."
    - "Multi-tenant UX, chat UI, or web dashboard."
    - "Long-lived agent memory beyond repo artifacts."
    - "Advanced scheduling/queueing/prioritization across many repos."
success_metrics:
  - "Setup-to-first-successful-run <= 5 minutes on a typical repo."
  - ">= 90% runs complete without manual intervention for 'small' tasks."
  - "All outputs reproducible from filesystem artifacts (no hidden state)."
  - "Verification gate catches regressions (tests/lint/build) before merge."
  - "User can pause/resume reliably via `--continue` with no lost context."
```
