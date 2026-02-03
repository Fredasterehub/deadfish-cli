# P7 Post-Fix Review (GPT-5.2-Codex)

Scope: verify three applied fixes in:
- `CLAUDE.md`
- `.pipe/p2-codex-prompt.md`
- `.pipe/p7/P7_IMPLEMENT_TASK.md`

Convention comparison source:
- `.pipe/p6/P6_GENERATE_TASK.md`

Date: 2026-02-02

---

## Fix 1 — HIGH (blocking): Over-escaped quotes in `codex exec` command

**Claimed change**
- BEFORE: `-c \"model_reasoning_effort=\\\"high\\\"\"`
- AFTER: `-c 'model_reasoning_effort="high"'`

**Verification**
- `CLAUDE.md:370` uses `codex exec -m gpt-5.2-codex -c 'model_reasoning_effort="high"' --approval-mode full-auto "<implementation prompt>"`.
- `CLAUDE.md:804` (Model Dispatch Reference) matches the same command.
- `.pipe/p2-codex-prompt.md:621` uses the same corrected command.
- `.pipe/p2-codex-prompt.md:1009` (Model Dispatch Reference) matches the same command.
- Search in these two files shows no remaining `\\\"...`-style over-escaping for `model_reasoning_effort`.

**Result: PASS**

---

## Fix 2 — MEDIUM: Guardrail numbering normalized in P7 template

**Claimed change**
- BEFORE: `999, 9999, 99999, ...`
- AFTER: `99999, 999999, 9999999, ...` (match P6 convention)

**Verification**
- `.pipe/p6/P6_GENERATE_TASK.md` guardrails use `99999`, `999999`, `9999999`.
- `.pipe/p7/P7_IMPLEMENT_TASK.md` guardrails now use `99999`, `999999`, `9999999`, … (continuing by powers of 10), aligning with the P6 numbering base.

**Result: PASS**

---

## Fix 3 — MEDIUM: `max_diff` reference in P7 template

**Claimed change**
- BEFORE: directive computed inline: `ESTIMATED_DIFF × 3`
- AFTER: directive references precomputed `max_diff`

**Verification**
- `.pipe/p6/P6_GENERATE_TASK.md` task packet format includes `max_diff: <3 × ESTIMATED_DIFF>` under `## ESTIMATED_DIFF`.
- `.pipe/p7/P7_IMPLEMENT_TASK.md:11` now states: `keep total diff ≤ max_diff`.
- `.pipe/p7/P7_IMPLEMENT_TASK.md:19` reinforces this: `Diff cap: treat max_diff as a hard ceiling.`

**Result: PASS**

---

## New Findings / Regressions

### LOW: Other P7 planning artifacts still mention `ESTIMATED_DIFF × 3` and old numbering
- Examples found outside the modified template include `.pipe/p7-codex-prompt.md` and `.pipe/p7/plan-*.md` referring to `ESTIMATED_DIFF × 3` and older guardrail numbering.
- If these files are intentionally historical/one-shot prompts (not consumed by the pipeline), this is informational only. If they are still used operationally, they should be aligned to `max_diff` + P6-style numbering.

---

## Overall Verdict

**CLEAN**
