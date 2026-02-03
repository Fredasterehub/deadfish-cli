# Restructuring Synthesis v1

> **Synthesized by:** Opus 4.5 (orchestrator)
> **Sources:** plan-opus.md + plan-gpt52.md + Fred's `.deadf/` directive
> **Date:** 2026-02-02

---

## The Big Decision: Auto-Load vs On-Demand Import

**Opus says:** Put everything in `.claude/rules/` (auto-loaded). ~940 lines across 11 files always in context.

**GPT-5.2 says:** Keep `.claude/rules/` tiny (~200-300 lines, invariants only). Put action specs and grammars in `.claude/imports/` and use `@import` on-demand — only load what the current action needs.

**Decision: GPT-5.2's approach wins.** Rationale:
- Auto-loading 940 lines defeats the purpose of shrinking CLAUDE.md — you'd burn the same ~12-15K tokens
- `@import` means a cycle running `implement_task` only loads the implement action spec, not all 14 action specs
- Claude Code's `@import` is exactly designed for this: "load when needed, not always"
- `.claude/rules/` should contain ONLY invariants that apply to every single cycle

**Hybrid approach:**
- `.claude/rules/` (~200 lines total): core invariants, state locking, safety, output contract
- `.claude/imports/actions/`: full action specs (~30-60 lines each), imported by DECIDE step
- `.claude/imports/grammars/`: sentinel format specs, imported when parsing
- `templates/`: prompt bodies for worker models (separate from orchestrator instructions)

---

## Fred's Directive: Target Project `.deadf/`

When deadfish deploys to a target project, EVERYTHING pipeline-related lives under `.deadf/`:
- Runtime state: `.deadf/tracks/`, `.deadf/logs/`, `.deadf/seed/`, locks
- Deployed templates: `.deadf/templates/` (copied from deadfish-cli repo)
- Deployed scripts: `.deadf/scripts/` (copied from deadfish-cli repo)

The deadfish-cli repo itself uses clean top-level directories (`templates/`, `scripts/`). Deployment copies them into `.deadf/`.

---

## A) CLAUDE.md — Target ≤250 lines

### What Stays (~250 lines):

```
1. Identity + role boundaries                    ~20 lines
2. Cycle Protocol skeleton (6 steps, brief)      ~40 lines  
3. DECIDE table (full, precedence-ordered)       ~30 lines
4. Action dispatch rule:                         ~15 lines
   "Before executing action X, read @.claude/imports/actions/X.md"
5. Grammar dispatch rule:                        ~10 lines
   "When parsing block type Y, read @.claude/imports/grammars/Y.md"
6. State Write Authority table                   ~20 lines
7. Model Dispatch Reference table                ~25 lines
8. IO contract (final token rules)               ~10 lines
9. Quick Reference (cycle flow diagram)          ~15 lines
```

### What Moves:

| Destination | Content | Est. Lines |
|-------------|---------|-----------|
| `.claude/rules/core.md` | Role boundaries, one-cycle-one-action, no-improvisation | ~40 |
| `.claude/rules/state-locking.md` | Lock discipline, atomic write pattern, flock rules | ~40 |
| `.claude/rules/safety.md` | Blocked paths, no-secrets, tool restrictions | ~30 |
| `.claude/rules/output-contract.md` | Last-line token, no-prose-outside-blocks | ~20 |
| `.claude/rules/imports-index.md` | Action→file + grammar→file mapping tables | ~30 |
| `.claude/imports/actions/seed-docs.md` | Full seed_docs + P12 spec | ~40 |
| `.claude/imports/actions/pick-track.md` | Full pick_track spec | ~25 |
| `.claude/imports/actions/create-spec.md` | Full create_spec spec | ~25 |
| `.claude/imports/actions/create-plan.md` | Full create_plan spec | ~30 |
| `.claude/imports/actions/generate-task.md` | Full generate_task spec | ~50 |
| `.claude/imports/actions/implement-task.md` | Full implement_task spec | ~40 |
| `.claude/imports/actions/verify-task.md` | Full verify_task spec | ~80 |
| `.claude/imports/actions/reflect.md` | Full reflect spec | ~30 |
| `.claude/imports/actions/qa-review.md` | Full qa_review spec | ~60 |
| `.claude/imports/actions/recovery.md` | retry/replan/rollback/escalate/summarize | ~50 |
| `.claude/imports/grammars/plan-v1.md` | PLAN sentinel grammar + parser contract | ~30 |
| `.claude/imports/grammars/track-v1.md` | TRACK sentinel grammar | ~20 |
| `.claude/imports/grammars/spec-v1.md` | SPEC sentinel grammar | ~20 |
| `.claude/imports/grammars/verdict-v1.md` | VERDICT sentinel grammar | ~20 |
| `.claude/imports/grammars/reflect-v1.md` | REFLECT sentinel grammar | ~20 |
| `.claude/imports/grammars/qa-review-v1.md` | QA_REVIEW sentinel grammar | ~25 |
| `.claude/imports/tools/launcher.md` | Kick details, dual-lock, task list lifecycle | ~50 |
| `.claude/imports/tools/task-management.md` | Task naming, recovery algorithm, gate rule | ~120 |
| `.claude/imports/tools/escalation-p10.md` | 3-tier escalation protocol | ~80 |

---

## B) File Structure — deadfish-cli Repo

```
deadfish-cli/
├── CLAUDE.md                          # ≤250 lines (lean skeleton)
├── .claude/
│   ├── rules/                         # auto-loaded (~160 lines total)
│   │   ├── core.md
│   │   ├── state-locking.md
│   │   ├── safety.md
│   │   ├── output-contract.md
│   │   └── imports-index.md
│   └── imports/                       # on-demand via @import (~700 lines total)
│       ├── actions/
│       │   ├── seed-docs.md
│       │   ├── pick-track.md
│       │   ├── create-spec.md
│       │   ├── create-plan.md
│       │   ├── generate-task.md
│       │   ├── implement-task.md
│       │   ├── verify-task.md
│       │   ├── reflect.md
│       │   ├── qa-review.md
│       │   └── recovery.md
│       ├── grammars/
│       │   ├── plan-v1.md
│       │   ├── track-v1.md
│       │   ├── spec-v1.md
│       │   ├── verdict-v1.md
│       │   ├── reflect-v1.md
│       │   └── qa-review-v1.md
│       └── tools/
│           ├── launcher.md
│           ├── task-management.md
│           └── escalation-p10.md
│
├── templates/                         # prompt bodies for worker models
│   ├── kick/
│   │   └── cycle-kick.md
│   ├── research/
│   │   ├── brainstorm-main.md
│   │   └── brainstorm-[a-g].md
│   ├── select-track/
│   │   ├── pick-track.md
│   │   ├── create-spec.md
│   │   └── create-plan.md
│   ├── execute/
│   │   ├── generate-task.md
│   │   └── implement-task.md
│   ├── verify/
│   │   └── verify-criterion.md
│   ├── reflect/
│   │   └── reflect.md
│   ├── repair/
│   │   ├── format-repair.md
│   │   └── auto-diagnose.md
│   ├── qa/
│   │   └── qa-review.md
│   └── init/
│       ├── mapper-agent.md
│       ├── synthesizer.md
│       ├── brownfield-brainstorm.md
│       └── living-docs.tmpl
│
├── scripts/                           # executable tooling
│   ├── ralph.sh
│   ├── verify.sh
│   ├── cron-kick.sh
│   ├── assemble-kick.sh              # shared kick assembly (ralph + cron-kick use)
│   ├── extract-sentinel.py           # was extract_plan.py (extended)
│   ├── build-verdict.py              # was build_verdict.py
│   ├── brainstorm.sh
│   ├── init.sh
│   ├── init-detect.sh
│   ├── init-collect.sh
│   ├── init-map.sh
│   ├── init-confirm.sh
│   ├── init-inject.sh
│   └── budget-check.sh
│
├── docs/                              # design artifacts (not runtime)
│   ├── design/
│   ├── reviews/
│   └── analysis/
│
├── tests/                             # fixtures and test results
│   ├── fixtures/
│   │   └── sentinels/                 # golden files for parser tests
│   └── integration-test-results.md
│
├── POLICY.yaml
├── ROADMAP.md
├── VISION.md
├── METHODOLOGY.md
├── PROMPT_OPTIMIZATION.md
├── README.md
├── llms.txt
├── .mcp.json
├── examples/
└── .gitignore
```

---

## C) Semantic Naming

| Old ID | Old Name | New Name | Template Path | Action Spec Path |
|--------|----------|----------|--------------|-----------------|
| P1 | Cycle Kick | `cycle-kick` | `templates/kick/cycle-kick.md` | `.claude/imports/tools/launcher.md` |
| P2 | Brainstorm | `seed-docs` | `templates/research/brainstorm-*.md` | `.claude/imports/actions/seed-docs.md` |
| P3 | Pick Track | `pick-track` | `templates/select-track/pick-track.md` | `.claude/imports/actions/pick-track.md` |
| P4 | Create Spec | `create-spec` | `templates/select-track/create-spec.md` | `.claude/imports/actions/create-spec.md` |
| P5 | Create Plan | `create-plan` | `templates/select-track/create-plan.md` | `.claude/imports/actions/create-plan.md` |
| P6 | Generate Task | `generate-task` | `templates/execute/generate-task.md` | `.claude/imports/actions/generate-task.md` |
| P7 | Implement Task | `implement-task` | `templates/execute/implement-task.md` | `.claude/imports/actions/implement-task.md` |
| P8 | Verify (script) | `verify` | — (script) | — |
| P9 | Verify Criterion | `verify-criterion` | `templates/verify/verify-criterion.md` | `.claude/imports/actions/verify-task.md` |
| P9.5 | Reflect | `reflect` | `templates/reflect/reflect.md` | `.claude/imports/actions/reflect.md` |
| P10 | Format Repair | `format-repair` / `auto-diagnose` | `templates/repair/*.md` | `.claude/imports/tools/escalation-p10.md` |
| P11 | QA Review | `qa-review` | `templates/qa/qa-review.md` | `.claude/imports/actions/qa-review.md` |
| P12 | Init/Brownfield | `init` / `codebase-map` | `templates/init/*.md` | `.claude/imports/actions/seed-docs.md` |

**P-numbers preserved only in:** `PROMPT_OPTIMIZATION.md` (historical reference) and `docs/` artifacts.

**Migration:** `git mv` for rename tracking → separate commit for reference updates.

---

## D) Contract/Tool Reconciliation

### Priority Order (both plans agree):

1. **`verify.sh`** — task file discovery + parsing fixes (blocks e2e)
2. **`extract_plan.py` → `extract-sentinel.py`** — TRACK/SPEC/multi-task PLAN (blocks select-track)
3. **`ralph.sh` kick unification** — shared `assemble-kick.sh` (correctness)
4. **`POLICY.yaml` cleanup** — remove bot-era refs (cosmetic)

### verify.sh Fixes:
- Add `VERIFY_TASK_FILE` env var / `--task-file` flag
- Auto-derive from STATE.yaml: `.deadf/tracks/{track.id}/tasks/TASK_{NNN}.md`
- Dual-pattern ESTIMATED_DIFF parsing (inline + header)
- Dual-pattern file path extraction (`path=` + `- path:`)
- Fallback to `TASK.md` for backward compat

### extract-sentinel.py:
- `--block-type plan|track|spec` argument
- Per-type field validation
- Multi-task PLAN support (`TASK_COUNT` + `TASK[N]:` sections)
- `extract_plan.py` becomes thin wrapper for backward compat
- Golden fixture tests in `tests/fixtures/sentinels/`

### ralph.sh:
- Extract kick assembly into `scripts/assemble-kick.sh`
- ralph calls assemble-kick → gets canonical kick message
- ralph becomes ONLY a loop wrapper (iterations, timeouts, backoff)
- Optional `RALPH_MODE=remote` for dispatch command (non-default)

---

## E) Implementation Phases

| Phase | Scope | Depends | Risk | Effort | Commits |
|-------|-------|---------|------|--------|---------|
| 0 | Baseline: fixtures + current behavior docs | — | LOW | 0.5d | 1 |
| 1 | Tool fixes (verify.sh + extract-sentinel.py) | Phase 0 | HIGH | 2d | 2 |
| 2 | Launcher unification (assemble-kick.sh + ralph) | Phase 0 | MEDIUM | 0.5d | 1 |
| 3 | CLAUDE.md split + .claude/ structure | Phase 1,2 | LOW | 1d | 1 |
| 4 | File restructure (templates/ + scripts/ + docs/) | Phase 3 | MEDIUM | 1d | 2 |
| 5 | Semantic naming + reference updates | Phase 4 | LOW | 0.5d | 1 |
| 6 | Cleanup: remove old paths, update README | Phase 5 | LOW | 0.5d | 1 |

**Total: ~6 days, 9 commits**

**Key ordering insight (from GPT-5.2):** Fix tools BEFORE restructuring files. Otherwise you're fixing tools at old paths and then moving them, creating double churn.

**Git strategy:** Short-lived branches per phase, `git mv` for renames, tag milestones.

---

## F) Validation Checklist (post-restructure)

- [ ] `wc -l CLAUDE.md` ≤ 300
- [ ] `cat .claude/rules/*.md | wc -l` ≤ 200
- [ ] `ls .claude/imports/actions/*.md | wc -l` = 10
- [ ] `ls .claude/imports/grammars/*.md | wc -l` = 6
- [ ] `grep -rn '\.pipe/' . --include='*.md' --include='*.sh' --include='*.py'` = 0 matches
- [ ] `python3 scripts/extract-sentinel.py plan --nonce ABC123 < tests/fixtures/sentinels/plan.txt` works
- [ ] `python3 scripts/extract-sentinel.py track --nonce ABC123 < tests/fixtures/sentinels/track.txt` works
- [ ] `VERIFY_TASK_FILE=<path> scripts/verify.sh` reads correct file
- [ ] `scripts/assemble-kick.sh` produces valid kick message
- [ ] `ralph.sh` calls `assemble-kick.sh` (no inline kick assembly)
- [ ] No `clawdbot` references in POLICY.yaml
- [ ] One full cycle completes end-to-end (integration test)

---

*Synthesis v1 — ready for GPT-5.2 review*
