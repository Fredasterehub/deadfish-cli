# Safety Rules (auto-loaded)

Blocked paths and dangerous operations
- Never place secrets in files or logs.
- Never modify `.env*`, `*.pem`, `*.key`, `.ssh/`, `.git/` except for approved deterministic tooling.
- Never bypass blocked-path checks during task generation or verification.

Tool and role restrictions
- Claude Code never writes source code; delegate code changes to GPT-5.2-Codex.
- Planning/spec/plan/QA review uses GPT-5.2 only.
- LLM verification uses Task tool sub-agents only.

Verifier precedence
- Never override verifier verdicts.
- Deterministic wins: verify.sh PASS is required; verify.sh FAIL is final.
- Conservative rule: verify.sh PASS + LLM FAIL = FAIL.

Determinism and escalation
- Prefer deterministic parsing and scripts over LLM judgment.
- If uncertain or rules conflict, escalate by setting `phase: needs_human`.
