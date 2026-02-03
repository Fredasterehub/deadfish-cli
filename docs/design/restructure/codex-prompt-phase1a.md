# Phase 1a: Unified Sentinel Parser (`parse-blocks.py`)

## Task

Create `.deadf/contracts/sentinel/` grammar specs AND `.deadf/bin/parse-blocks.py` — a unified sentinel block parser that replaces the current `extract_plan.py` (which only handles PLAN blocks).

## Deliverables

1. **6 grammar spec files** in `.deadf/contracts/sentinel/`:
   - `track.v1.md` — TRACK block grammar
   - `spec.v1.md` — SPEC block grammar
   - `plan.v1.md` — PLAN block grammar (extracted from current CLAUDE.md + extract_plan.py)
   - `verdict.v1.md` — VERDICT block grammar
   - `reflect.v1.md` — REFLECT block grammar
   - `qa-review.v1.md` — QA_REVIEW block grammar

2. **`parse-blocks.py`** in `.deadf/bin/` — unified parser with subcommands:
   ```
   parse-blocks.py track     --nonce ABC123 < output.txt
   parse-blocks.py spec      --nonce ABC123 < output.txt
   parse-blocks.py plan      --nonce ABC123 < output.txt
   parse-blocks.py verdict   --nonce ABC123 --criterion AC1 < output.txt
   parse-blocks.py reflect   --nonce ABC123 < output.txt
   parse-blocks.py qa-review --nonce ABC123 < output.txt
   ```

3. **Golden test fixtures** in `tests/fixtures/sentinels/`:
   - `plan-valid.txt`, `plan-invalid.txt`, `plan-multi-task.txt`
   - `track-valid.txt`, `track-invalid.txt`
   - `spec-valid.txt`
   - `verdict-valid.txt`
   - `reflect-valid.txt`
   - `qa-review-valid.txt`

4. **Backward-compat shim**: `extract_plan.py` becomes a thin wrapper that calls `parse-blocks.py plan "$@"`.

## Existing Code Reference

The current `extract_plan.py` is at repo root. It handles PLAN blocks only. Its parsing infrastructure (nonce validation, quoted-value unescaping, KV parsing, section headers, list items, field validation) is solid and should be **reused/generalized**, not rewritten from scratch.

## Block Grammar Specs (from current CLAUDE.md)

### TRACK Block
```
<<<TRACK:V1:NONCE={nonce}>>>
TRACK_ID=<bare>
NAME="<quoted>"
PHASE=<bare>
GOAL="<quoted>"
REQUIREMENTS=<comma-separated bare list>
ESTIMATED_TASKS=<positive integer>
PHASE_COMPLETE=<true|false>    # optional
PHASE_BLOCKED=<true|false>     # optional
REASONS="<quoted>"             # required if PHASE_BLOCKED=true
<<<END_TRACK:NONCE={nonce}>>>
```

### SPEC Block
```
<<<SPEC:V1:NONCE={nonce}>>>
TRACK_ID=<bare>
TITLE="<quoted>"
SCOPE=
  <2-space indented multi-line>
APPROACH=
  <2-space indented multi-line>
CONSTRAINTS=
  <2-space indented multi-line>
SUCCESS_CRITERIA:
- id=SC<n> text="<quoted>"
DEPENDENCIES:
- "<quoted dependency description>"
ESTIMATED_TASKS=<positive integer>
<<<END_SPEC:NONCE={nonce}>>>
```

### PLAN Block (existing — keep extract_plan.py's grammar exactly)
```
<<<PLAN:V1:NONCE={nonce}>>>
TASK_ID=<bare>
TITLE="<quoted>"
SUMMARY=
  <2-space indented multi-line>
FILES:
- path=<bare> action=<add|modify|delete> rationale="<quoted>"
ACCEPTANCE:
- id=AC<n> text="<quoted testable statement>"
ESTIMATED_DIFF=<positive integer>
NOTES=                         # optional
  <2-space indented multi-line>
<<<END_PLAN:NONCE={nonce}>>>
```

### VERDICT Block
```
<<<VERDICT:V1:{criterion_id}:NONCE={nonce}>>>
ANSWER=YES|NO
REASON="<quoted, ≤500 chars, single line>"
<<<END_VERDICT:{criterion_id}:NONCE={nonce}>>>
```
Note: VERDICT has an extra `{criterion_id}` in the sentinel delimiters.

### REFLECT Block
```
<<<REFLECT:V1:NONCE={nonce}>>>
UPDATES:
- doc=<TECH_STACK|PATTERNS|PITFALLS|RISKS|PRODUCT|WORKFLOW|GLOSSARY> action=<append|replace_section|noop> section="<quoted>" content="<quoted>"
SCRATCH=
  <2-space indented multi-line, YAML>
<<<END_REFLECT:NONCE={nonce}>>>
```

### QA_REVIEW Block
```
<<<QA_REVIEW:V1:NONCE={nonce}>>>
VERDICT=PASS|FAIL
RISK=LOW|MEDIUM|HIGH
C0=PASS|FAIL
C1=PASS|FAIL
C2=PASS|FAIL
C3=PASS|FAIL
C4=PASS|FAIL
C5=PASS|FAIL
FINDINGS_COUNT=<non-negative integer>
FINDINGS:
- severity=CRITICAL|MAJOR|MINOR category=C0|C1|C2|C3|C4|C5 file="<path>" issue="<quoted>"
REMEDIATION_COUNT=<non-negative integer>
REMEDIATION:
- file="<path>" action="<quoted>"
NOTES="<quoted, ≤500 chars>"
<<<END_QA_REVIEW:NONCE={nonce}>>>
```

## Architecture Requirements

1. **Shared parsing core**: Factor out common logic from extract_plan.py:
   - CRLF normalization
   - Sentinel delimiter location (opener/closer regex matching)
   - Nonce validation (exactly-one-block, nonce match)
   - Payload extraction
   - Block size cap (16KB)
   - KV line parsing, quoted-value unescaping, section headers, list items, continuation lines

2. **Per-block-type validation**: Each block type has:
   - Its own opener/closer regex pattern
   - Its own field allowlist + required fields
   - Its own section definitions (which fields are sections with list items)
   - Its own multiline field definitions
   - Its own per-field value constraints

3. **Subcommand dispatch**: `argparse` with subcommands. Each subcommand registers its block-type-specific config and calls the shared parser.

4. **Exit codes**: 0 = valid (JSON on stdout), 1 = parse error (diagnostic on stderr), 2 = nonce mismatch.

5. **JSON output**: Structured, camelCase or snake_case keys (match existing extract_plan.py convention: snake_case).

6. **Grammar files**: Each `.deadf/contracts/sentinel/*.v1.md` should be human-readable Markdown that documents the exact grammar for that block type. Include: delimiter regexes, field table (name, type, required/optional, constraints), examples.

## Constraints

- Python 3 stdlib only (no external dependencies)
- Single file for the parser (`.deadf/bin/parse-blocks.py`)
- Must pass all golden fixtures
- Reuse extract_plan.py's proven parsing patterns (unescape_quoted, parse_value, split_tokens, parse_item_kv, validate_path)
- VERDICT block: the `--criterion` arg provides the expected criterion_id in the delimiters
- PLAN validation must be identical to current extract_plan.py (don't regress)

## Directory Setup

Create these directories if they don't exist:
- `.deadf/bin/`
- `.deadf/contracts/sentinel/`
- `tests/fixtures/sentinels/`
