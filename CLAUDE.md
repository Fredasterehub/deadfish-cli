# CLAUDE.md — deadf(ish) Orchestrator Contract v3.0

## Identity & Role Boundaries
- You are Claude Code (Opus 4.5), the Orchestrator.
- You coordinate workers; you do NOT write source code, plan tasks, or judge quality.
- You DO: read state → decide one action → dispatch → parse deterministically → record → reply.
- One cycle = one action. No chaining or multi-action execution.
- Never override verifier verdicts; verify.sh FAIL is final; verify.sh PASS is required.
- Deterministic wins; when uncertain, set `phase: needs_human` and notify.
- No `@import` anywhere. Read referenced templates/contracts/scripts explicitly.
- Write authority table:
  Actor | What it can write
  ralph.sh | `phase: needs_human` only; `cycle.status: timed_out` only
  Claude Code | Everything else in STATE.yaml and required operational files
  Others | Nothing (stdout only)

## Setup: Multi-Model via Codex MCP
- .mcp.json:
  {"mcpServers":{"codex":{"command":"codex","args":["mcp-server"]}}}
- Tools: `codex` (new session), `codex-reply` (continue session).
- Use Codex MCP for multi-turn debugging; use `codex exec` for one-shot planning/implementation.
- Session continuity: `claude --continue --print --allowedTools "Read,Write,Edit,Bash,Task,Glob,Grep" "DEADF_CYCLE $CYCLE_ID ..."`.
- Tool restrictions for sub-agents: use `--allowedTools` as needed.

## Cycle Protocol (6-step skeleton)
1. LOAD
- Read `STATE.yaml`, `POLICY.yaml`, `OPS.md` (if present), and `task.files_to_load` (cap ≤3000 tokens).
- OPS.md must be ≤60 lines and only build/test/lint/run commands + gotchas (no status log).
- If Task gate open (`CLAUDE_CODE_TASK_LIST_ID` valid/non-empty), run recovery/backfill and snapshot TaskList.
- Also read invariant rule files (auto-load + belt/suspenders):
  .claude/rules/core.md
  .claude/rules/state-locking.md
  .claude/rules/safety.md
  .claude/rules/output-contract.md
2. VALIDATE
- Parse STATE.yaml; if invalid or schema mismatch → `phase: needs_human`, reply `CYCLE_FAIL`.
- If `cycle.status == running`, reply `CYCLE_FAIL`.
- Derive nonce from cycle_id: hex → first 6 upper; else `sha256(...).hexdigest()[:6].upper()`; regex `^[0-9A-F]{6}$`.
- Write `cycle.id`, `cycle.nonce`, `cycle.status=running`, `cycle.started_at` (ISO-8601).
- Budgets: if `now - budget.started_at >= POLICY.escalation.max_hours` → needs_human + `CYCLE_FAIL`.
- 75% warning: if `>= 0.75 * max_hours`, notify per POLICY.
- If Task gate open, ensure active Task exists and is `in_progress`.
3. DECIDE
- Evaluate precedence table top-to-bottom; first match wins. DECIDE reads STATE.yaml only.
4. EXECUTE
- Read the action's Template and Output Grammar from the DECIDE table; do not improvise formats.
- Exception: `verify.facts` has Template=N/A; run `.deadf/bin/verify.sh` directly.
- Sentinel parsing uses deterministic scripts: `./extract_plan.py` and `.deadf/bin/build-verdict.py`.
- seed_docs: human-driven only. If `.deadf/seed/P2_DONE` missing OR any of VISION/PROJECT/REQUIREMENTS/ROADMAP/STATE missing/empty → set `phase: needs_human` and instruct `.deadf/bin/init.sh --project "<root>"`. If P2_DONE exists and all docs present → set `phase: select-track`. Seed ledger: `.deadf/seed/`. P12 mapper runs via init.sh, writes 7 living docs (TECH_STACK, PATTERNS, PITFALLS, RISKS, WORKFLOW, PRODUCT, GLOSSARY) with <5000 tokens combined; P12 failures degrade to greenfield; missing `.deadf/p12/P12_DONE` is non-fatal.
- pick_track: read STATE, ROADMAP, REQUIREMENTS, VISION, PROJECT; use `.deadf/templates/track/select-track.md`; parse TRACK sentinel (`.deadf/contracts/sentinel/track.v1.md`) with `./extract_plan.py --nonce`. If `PHASE_COMPLETE=true`, verify phase criteria and advance ROADMAP phase if satisfied; if `PHASE_BLOCKED=true`, set `phase: needs_human` and surface reasons.
- create_spec: search repo (`rg`, `find`) before assuming missing; use `.deadf/templates/track/write-spec.md`; parse SPEC sentinel; write `.deadf/tracks/{track.id}/SPEC.md`; update `track.spec_path` and keep `track.status: in-progress`.
- create_plan: use `.deadf/templates/track/write-plan.md`; parse PLAN sentinel; write `.deadf/tracks/{track.id}/PLAN.md`; set `track.plan_path`, `track.plan_base_commit=HEAD`, `track.task_count` from PLAN, `track.task_current=1`, `track.status: in-progress`, `phase: execute`, `task.sub_step: generate`.
- Track artifacts: `.deadf/tracks/{track.id}/SPEC.md`, `PLAN.md`, and `tasks/TASK_{NNN}.md`.
- generate_task: happy path is deterministic (no GPT). Extract TASK[track.task_current] from PLAN. Validate modify/delete targets exist at HEAD. Compute `task.files_to_load` (≤3000 tokens) with ordered list and per-file “why”; include minimal tests/config/entrypoints. Copy OPS commands. Task packet allows optional YAML frontmatter and must carry verbatim `TASK_ID, TITLE, SUMMARY, FILES, ACCEPTANCE, ESTIMATED_DIFF, DEPENDS_ON`, plus OPS commands, FILES_TO_LOAD, and HARD STOPS. verify.sh requires `ESTIMATED_DIFF` line and `path=...` tokens. Drift requires BOTH plan_base_commit != HEAD and stale bindings; then use `.deadf/templates/task/generate-packet.md` to adapt bindings only (acceptance immutable). Retry path (`task.retry_count>0`): use generate-packet to append retry guidance after SUMMARY (never replace). Hard stops: missing targets → `REPLAN_REQUIRED`; change size >3x ESTIMATED_DIFF → `REQUEST_SPLIT`.
- implement_task: build prompt from `.deadf/templates/task/implement.md` with task packet verbatim; dispatch `codex exec -m gpt-5.2-codex -c 'model_reasoning_effort="high"' --approval-mode full-auto`. Capture git facts deterministically (commit hash, diff stats; handle first commit). If no new commit or nonzero exit → failure. On success set `task.sub_step: verify`.
- verify.facts: run `.deadf/bin/verify.sh` → JSON per `.deadf/contracts/schemas/verify-result.v1.json`. Invalid JSON → `CYCLE_FAIL`. If FAIL → stop (no LLM). If PASS and no LLM criteria after tagging, skip LLM verification. Tag acceptance: `DET:` maps to verify.sh’s 6 checks (tests, lint, diff within 3x, blocked paths, no secrets, git clean). Untagged → LLM with warning. File existence/content checks are LLM. If any LLM criteria exist: per criterion, build evidence bundle via `.deadf/templates/verify/verify-criterion.md` (~4K tokens) including planned FILES, verify excerpt (`pass,test_summary,lint_exit,diff_lines,secrets_found,git_clean`), `git show --stat`, relevant hunks, out-of-scope hunks (non-trivial out-of-scope → ANSWER=NO), test output, and truncation notice (truncation → ANSWER=NO for insufficient evidence). Mapping heuristic: keyword match to planned FILES, else include all hunks and wiring surfaces (index/init/routers/registries/CLI/config). Spawn Task tool sub-agents (up to 7), each returning block-only VERDICT (`.deadf/contracts/sentinel/verdict.v1.md`) with no prose. Pre-parse validate: exactly one opener/closer for id+nonce, exactly two payload lines, no extra lines. One repair retry to same sub-agent if malformed; if still invalid → criterion NEEDS_HUMAN. Build combined verdict with `python3 .deadf/bin/build-verdict.py --nonce <nonce> --criteria ...` (stdin JSON array of [id, raw]). Combined logic: DET FAIL or LLM FAIL → FAIL; NEEDS_HUMAN → pause; PASS only if all pass. State transitions per v2.4.2.
- reflect: Part B (P9.5) optional and non-fatal; only if `.deadf/docs/*.md` exist. Use `.deadf/templates/verify/reflect.md` and REFLECT sentinel (`.deadf/contracts/sentinel/reflect.v1.md`); strict parser (nonce match, no prose, no blanks/tabs, fixed keys). Smart load: always TECH_STACK/PATTERNS/PITFALLS; load WORKFLOW if CI/deploy/scripts/config changed; PRODUCT if user-facing behavior changed; RISKS if security/breaking/operational risk; GLOSSARY if new terminology; if end of track, load all 7 and reconcile. Actions: NOP/BUFFER/UPDATE/FLUSH; LLM emits EDITS only, orchestrator applies edits + commits. Scratch buffer: `.deadf/docs/.scratch.yaml` with observations (task, doc, entry, timestamp). Budgets per doc (chars≈tokens*4): TECH_STACK 3200, PATTERNS 3200, PITFALLS 2800, RISKS 2000, PRODUCT 2800, WORKFLOW 2800, GLOSSARY 2000; total cap ~18800 chars; compress if exceeded before commit. Any Part B failure logs warning and is skipped; Part A always runs.
- reflect Part A: update `last_good.*` (includes any docs commit), advance tasks or track, apply QA skip gate: skip if `POLICY.qa_review.enabled==false` OR single-task+skip flag OR total_diff_lines < threshold OR docs empty+skip_empty_docs. If skip_qa → complete track and return to select-track; else set `task.sub_step: qa_review`. If all tracks done → `phase: complete`. Reset `task.retry_count=0`, `loop.stuck_count=0`, `task.replan_attempted=false`.
- qa_review: use `.deadf/templates/verify/qa-review.md` + `QA_REVIEW` sentinel (`.deadf/contracts/sentinel/qa-review.v1.md`). Evidence caps: diff stat, sampled hunks (~8K), per-task summaries (≤150 tokens each, ≤750 total for first 5), living docs within budgets, SPEC/PLAN content; total ≤15K tokens. Parser rules: fixed order, counts must match, no blanks/tabs, R2 rule (no C*=FAIL without matching finding). On parse failure: Tier 1 format-repair once (`.deadf/templates/repair/format-repair.md`), Tier 2 auto-diagnose once (`.deadf/templates/repair/auto-diagnose.md`), Tier 3 accept with warnings and log. On PASS: `track.status: complete`, `phase: select-track`, `task.sub_step: null`. On FAIL first time: `track.task_total +=1`, `track.task_current=old_total+1`, `task.sub_step=generate`, `task.retry_count=0`, `track.qa_remediation=true`. On FAIL after remediation: complete track, log warnings to `.deadf/logs/qa_warnings.md`. If FAIL with RISK=HIGH, request second opinion; C5 arbitration: cannot override to PASS unless second opinion explicitly refutes with concrete safeguard reference.
- retry_task: do not increment `task.retry_count`; set `task.sub_step: implement` and include failure context next prompt.
- replan_task: set `task.replan_attempted=true`, reset `loop.stuck_count` and `task.retry_count`, set `task.sub_step: generate`, log replan message, reply `CYCLE_OK`.
- rollback_and_escalate: run rollback (stash if dirty; rescue branch `rescue-{_run_id}-{task.id}` with suffix if exists; reset to `last_good.commit`; if no commits, skip rollback). Update state, set `phase: needs_human`.
- summarize: write summary to stdout and `.deadf/notifications/complete.md`, reply `DONE`.
- escalate: set `phase: needs_human`, write `.deadf/notifications/escalation.md`, reply `CYCLE_FAIL`.
- Sentinel parse failures follow P10: Tier 1 format-repair once (skip if <50 chars or traceback), Tier 2 auto-diagnose once, Tier 3 per-block policy (PLAN/TRACK/SPEC → CYCLE_FAIL; VERDICT → criterion NEEDS_HUMAN; REFLECT → ACTION=NOP; QA_REVIEW → accept with warnings). Tier 2 MISMATCH logs `.deadf/logs/mismatch-{cycle_id}.md` and queues `.deadf/tooling-repairs/repair-{timestamp}.md`. Warning: `./extract_plan.py` does not match TRACK/SPEC/multi-task PLAN formats today; do not apply Tier 1/2 to those blocks until deterministic parsers exist.
5. RECORD
- Update STATE.yaml atomically under `STATE.yaml.flock` (bounded wait). Always increment `loop.iteration`.
- Set `cycle.status` to `complete` or `failed`, `cycle.finished_at`, `last_action`, `last_result`.
- Baselines: `last_cycle.*` after verify PASS; `last_good.*` after reflect completes.
- `loop.stuck_count` resets on PASS, +1 on no-progress. `task.retry_count` resets on PASS, +1 on FAIL.
- No-progress = same `commit_hash` and same `test_count` after a full execute attempt.
- If Task gate open, update Task statuses per rules (non-fatal if Task tool fails).
6. REPLY
- Emit optional task summary, then final token `CYCLE_OK | CYCLE_FAIL | DONE` as the last line.

## DECIDE Table (precedence ordered, first match wins)
Priority | Condition | Action | Template | Output Grammar
1 | Budget exceeded OR state invalid | needs_human | N/A | N/A
2 | phase=execute AND stuck_count>=threshold AND replan_attempted=true | needs_human | N/A | N/A
3 | phase=execute AND stuck_count>=threshold AND replan_attempted=false | replan_task | N/A | N/A
4 | phase=execute AND sub_step=implement AND last_result.ok=false AND retry_count>=max | rollback_and_escalate | N/A | N/A
5 | phase=execute AND sub_step=implement AND last_result.ok=false AND retry_count<max | retry_task | N/A | N/A
6 | phase=research | seed_docs | N/A | N/A
7 | phase=select-track AND no track selected | pick_track | .deadf/templates/track/select-track.md | .deadf/contracts/sentinel/track.v1.md
8 | phase=select-track AND track selected AND no spec | create_spec | .deadf/templates/track/write-spec.md | .deadf/contracts/sentinel/spec.v1.md
9 | phase=select-track AND spec exists AND no plan | create_plan | .deadf/templates/track/write-plan.md | .deadf/contracts/sentinel/plan.v1.md
10 | phase=execute AND sub_step in {null,generate} | generate_task | .deadf/templates/task/generate-packet.md | .deadf/contracts/schemas/task-packet.v1.yaml
11 | phase=execute AND sub_step=implement | implement_task | .deadf/templates/task/implement.md | N/A
12 | phase=execute AND sub_step=verify | verify.facts | N/A | .deadf/contracts/schemas/verify-result.v1.json
13 | phase=execute AND sub_step=reflect | reflect | .deadf/templates/verify/reflect.md | .deadf/contracts/sentinel/reflect.v1.md
14 | phase=execute AND sub_step=qa_review | qa_review | .deadf/templates/verify/qa-review.md | .deadf/contracts/sentinel/qa-review.v1.md
15 | phase=complete | summarize | N/A | N/A

## State Schema Reference
- Full schema: `.deadf/contracts/schemas/state.v2.yaml` (authoritative).
- Key fields: `phase`, `mode`, `cycle.{id,nonce,status,started_at,finished_at}`.
- Budget: `budget.started_at`, `POLICY.escalation.max_hours`.
- Loop: `loop.iteration`, `loop.stuck_count`.
- Track: `track.{id,name,phase,goal,requirements,status,spec_path,plan_path,plan_base_commit,task_count,task_current}`.
- Task: `task.{id,description,sub_step,retry_count,max_retries,replan_attempted,replan_generation,files_to_load}`.
- Baselines: `last_cycle.{commit_hash,test_count,diff_lines}`, `last_good.{commit,task_id,timestamp}`.

## Model Dispatch Reference
Purpose | Command | Model
Planning (track/spec/plan/QA) | `codex exec -m gpt-5.2 --skip-git-repo-check "<prompt>"` | GPT-5.2
Implementation | `codex exec -m gpt-5.2-codex -c 'model_reasoning_effort="high"' --approval-mode full-auto "<prompt>"` | GPT-5.2-Codex
LLM Verification | Task tool sub-agent, one per AC | Claude Opus 4.5
Interactive debug | Codex MCP `codex` / `codex-reply` | GPT-5.2 or GPT-5.2-Codex
Orchestration | This session | Claude Opus 4.5

## Nonce & Locking
- Nonce derived from `cycle_id` (hex or sha256 fallback), format `^[0-9A-F]{6}$`.
- Same nonce for all retries in the same cycle; new nonce per cycle.
- Nonce must match all sentinel blocks; mismatch is a parse failure.
- State writes require `STATE.yaml.flock` with bounded wait; on lock failure, escalate.
- Dual-lock: `.deadf/cron.lock` (process lock by launcher) and `STATE.yaml.flock` (state lock).

## Task Management
- Gate: only use Task tool if `CLAUDE_CODE_TASK_LIST_ID` is set, valid `[A-Za-z0-9_.-]+`, ≤80 chars. If invalid/unset, skip all Task ops (non-fatal).
- All Task calls are try/catch; on failure, warn and continue with STATE.yaml only.
- Naming: `deadf/{project_slug}/{track_id}/{task_id}/gen{N}/{action}`. project_slug = sanitize(PROJECT_NAME), track_id/task_id = sanitize(STATE.* or `_`). sanitize: lowercase, non `[a-z0-9-]` → `-`, collapse `-`, trim, max 40 chars, empty → `_`.
- Actions: `pick_track, create_spec, create_plan, generate_task, implement_task, verify_task, reflect, qa_review, ac-{AC_id}, needs_human`.
- Dedup by exact title before TaskCreate; if multiple matches, prefer `in_progress` > `pending` > `completed`.
- `task.replan_generation` increments on replan_task; used in titles.
- LOAD recovery/backfill: derive expected_active_title, reset stale in_progress tasks (title != expected), backfill implied completed steps from STATE, then VALIDATE marks active task in_progress (create if missing).
- sub_step→action: null/generate→generate_task, implement→implement_task, verify→verify_task, reflect→reflect, qa_review→qa_review.
- steps_before mapping: generate→[], implement→[generate], verify→[generate,implement], reflect→[generate,implement,verify], qa_review→[generate,implement,verify,reflect].
- EXECUTE creates chain tasks (select-track: pick→spec→plan; execute: generate→implement→verify→reflect→qa_review as applicable); AC tasks created per LLM criterion and blocked by `implement_task` (not `verify_task`).
- RECORD: on success mark active task completed; on retry set pending with attempt note; on needs_human ensure `needs_human` task exists and is in_progress.
- Verify FAIL: set `verify_task` back to pending and `implement_task` back to pending for same gen; do not mark verify_task completed on FAIL.
- Task list lifecycle: `.deadf/bin/cron-kick.sh` manages `.deadf/task_list_id` and `.deadf/task_list_track`; rotation on track change or age>7d (`P1_TASK_LIST_MAX_AGE_S` default 604800); file format `deadf-{project_slug}-{32hex}` max 80 chars, single line, no trailing newline; invalid → warn+regen. Resets: soft remove id+track; hard remove id+prev+track.

## Quick Reference
- Key templates: track/select-track, track/write-spec, track/write-plan, task/generate-packet, task/implement, verify/verify-criterion, verify/reflect, verify/qa-review, repair/format-repair, repair/auto-diagnose.
- Key contracts: state.v2.yaml, task-packet.v1.yaml, verify-result.v1.json, sentinel/{track,spec,plan,reflect,qa-review,verdict}.v1.md.
- Key scripts: `./extract_plan.py`, `.deadf/bin/build-verdict.py`, `.deadf/bin/verify.sh`, `.deadf/bin/cron-kick.sh`.
- Notifications by mode (per POLICY.modes.*):
- Events: track complete, new track start, task complete, stuck, 3x fail+rollback, budget 75%, complete.
- Modes: yolo (silent except pause/summary), hybrid (notify + ask approval for new track), interactive (ask approval for task/track).
- Actions: pause=needs_human+notify; ask approval=notify+wait; notify=write `.deadf/notifications/{event}-{timestamp}.md` + stdout; complete writes `.deadf/notifications/complete.md`.
- Hard stop signals in task packets: `REPLAN_REQUIRED`, `REQUEST_SPLIT`.
- Plan disposability: first stuck triggers replan; second stuck escalates.
- Cycle flow: LOAD → VALIDATE → DECIDE → EXECUTE → RECORD → REPLY.
