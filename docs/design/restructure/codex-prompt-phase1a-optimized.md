Implement a unified sentinel-block parser (`.deadf/bin/parse-blocks.py`) plus grammar docs, fixtures, and a backward-compat wrapper that replaces the current PLAN-only parser.

## Scope / Deliverables
Create all of the following (create directories if missing):
- `.deadf/bin/parse-blocks.py` (single-file, stdlib-only)
- `.deadf/contracts/sentinel/track.v1.md`
- `.deadf/contracts/sentinel/spec.v1.md`
- `.deadf/contracts/sentinel/plan.v1.md`
- `.deadf/contracts/sentinel/verdict.v1.md`
- `.deadf/contracts/sentinel/reflect.v1.md`
- `.deadf/contracts/sentinel/qa-review.v1.md`
- Golden fixtures in `tests/fixtures/sentinels/`:
  - `plan-valid.txt`, `plan-invalid.txt`, `plan-multi-task.txt`
  - `track-valid.txt`, `track-invalid.txt`
  - `spec-valid.txt`
  - `verdict-valid.txt`
  - `reflect-valid.txt`
  - `qa-review-valid.txt`
- Backward-compat shim: change `extract_plan.py` to a thin wrapper that executes `parse-blocks.py plan` with the same CLI surface (`--nonce ...` reading stdin, JSON to stdout on success).

## Sentinel Block Grammars (MUST implement exactly)

### TRACK (V1)
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

### SPEC (V1)
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

### PLAN (V1) (keep identical validation semantics to existing `extract_plan.py`)
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

### VERDICT (V1)
```
<<<VERDICT:V1:{criterion_id}:NONCE={nonce}>>>
ANSWER=YES|NO
REASON="<quoted, ≤500 chars, single line>"
<<<END_VERDICT:{criterion_id}:NONCE={nonce}>>>
```
Notes:
- VERDICT delimiters include an extra `{criterion_id}` segment.
- `parse-blocks.py verdict` MUST require `--criterion` and it is the expected `criterion_id` in the delimiters.

### REFLECT (V1)
```
<<<REFLECT:V1:NONCE={nonce}>>>
UPDATES:
- doc=<TECH_STACK|PATTERNS|PITFALLS|RISKS|PRODUCT|WORKFLOW|GLOSSARY> action=<append|replace_section|noop> section="<quoted>" content="<quoted>"
SCRATCH=
  <2-space indented multi-line, YAML>
<<<END_REFLECT:NONCE={nonce}>>>
```

### QA_REVIEW (V1)
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

## CLI Surface (MUST match)
Implement `.deadf/bin/parse-blocks.py` with `argparse` subcommands:
```
parse-blocks.py track     --nonce ABC123 < output.txt
parse-blocks.py spec      --nonce ABC123 < output.txt
parse-blocks.py plan      --nonce ABC123 < output.txt
parse-blocks.py verdict   --nonce ABC123 --criterion AC1 < output.txt
parse-blocks.py reflect   --nonce ABC123 < output.txt
parse-blocks.py qa-review --nonce ABC123 < output.txt
```

Exit codes (hard requirement):
- `0`: valid block found and validated; emit JSON to stdout
- `1`: parse/validation error; emit actionable diagnostic to stderr
- `2`: nonce mismatch (i.e., block nonce exists but doesn’t equal `--nonce`)

## Architecture Requirements (shared core + per-block config)
- Shared parsing core extracted/generalized from the existing PLAN parser:
  - CRLF normalization
  - Sentinel delimiter location (opener/closer regex matching)
  - Exactly-one-block enforcement (by opener/closer matches)
  - Nonce validation (opener nonce == closer nonce; and equals `--nonce`)
  - Payload extraction
  - Block size cap: 16KB payload
  - KV parsing, quoted-value decoding, section headers, list items, multiline fields, continuation lines
- Per-block-type validation is configured, not copy/pasted:
  - opener/closer regex
  - allowlist + required fields
  - which keys are sections with list items
  - which keys are multiline fields
  - per-field constraints (including length caps)
- JSON output keys use `snake_case` (match existing `extract_plan.py` convention).

## Hard Rules (do not violate)
- Python 3 stdlib only; no external deps.
- Parser is a single file: `.deadf/bin/parse-blocks.py`.
- PLAN parsing/validation behavior must remain identical to the existing `extract_plan.py` (no regressions).
- Reuse the existing parsing patterns and helpers (quoted unescaping, token splitting for list items, key/value parsing, path validation) rather than rewriting from scratch.
- VERDICT requires `--criterion` and uses it to validate delimiters.
- Golden fixtures must cover valid + invalid cases and multi-task/extra content noise; parser must pass them.
- Grammar docs in `.deadf/contracts/sentinel/*.v1.md` must be human-readable Markdown and document delimiter regexes, a field table (name/type/required/constraints), and at least one example block.

## Existing code to reuse/generalize (verbatim)
```py
#!/usr/bin/env python3
"""extract_plan.py — Sentinel plan parser for the deadf(ish) pipeline v2.4.2.

Reads raw LLM output from stdin, extracts a sentinel-delimited plan block,
validates it against the v2.4.2 grammar spec, and emits structured JSON to stdout.

Exit 0: Valid plan extracted (JSON on stdout)
Exit 1: Parse failure (actionable error on stderr)
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from typing import Any

# ---------------------------------------------------------------------------
# Sentinel regexes (line-anchored, exact per spec)
# ---------------------------------------------------------------------------
PLAN_OPENER = re.compile(r'^<<<PLAN:V1:NONCE=([0-9A-F]{6})>>>\s*$')
PLAN_CLOSER = re.compile(r'^<<<END_PLAN:NONCE=([0-9A-F]{6})>>>\s*$')

# ---------------------------------------------------------------------------
# Field allowlists
# ---------------------------------------------------------------------------
ALLOWED_TOP_LEVEL = frozenset({
    "TASK_ID", "TITLE", "SUMMARY", "FILES",
    "ACCEPTANCE", "ESTIMATED_DIFF", "NOTES",
})
REQUIRED_FIELDS = frozenset({
    "TASK_ID", "TITLE", "SUMMARY", "FILES",
    "ACCEPTANCE", "ESTIMATED_DIFF",
})
SECTION_FIELDS = frozenset({"FILES", "ACCEPTANCE"})
MULTILINE_FIELDS = frozenset({"SUMMARY", "NOTES"})

FILES_REQUIRED_KEYS = frozenset({"path", "action", "rationale"})
ACCEPTANCE_REQUIRED_KEYS = frozenset({"id", "text"})
VALID_ACTIONS = frozenset({"add", "modify", "delete"})

# ---------------------------------------------------------------------------
# Heuristic vague verbs (warning, not rejection)
# ---------------------------------------------------------------------------
VAGUE_VERBS = frozenset({
    "improve", "optimize", "enhance", "better",
    "cleanup", "refactor",
})

# ---------------------------------------------------------------------------
# Regexes for validation
# ---------------------------------------------------------------------------
RE_TOP_KEY = re.compile(r'^[A-Z][A-Z0-9_]*$')
RE_ITEM_KEY = re.compile(r'^[a-z][a-z_]*$')
RE_SECTION_HEADER = re.compile(r'^([A-Z_]+):$')
RE_KV_LINE = re.compile(r'^([A-Z][A-Z0-9_]*)=(.*)')
RE_PATH = re.compile(r'^[a-zA-Z0-9_./-]+$')
RE_AC_ID = re.compile(r'^AC[0-9]+$')
RE_NONCE = re.compile(r'^[0-9A-F]{6}$')


# ---------------------------------------------------------------------------
# Errors
# ---------------------------------------------------------------------------
class ParseError(Exception):
    """Parse error with optional line number."""
    def __init__(self, msg: str, line: int | None = None) -> None:
        self.line = line
        if line is not None:
            super().__init__(f"line {line}: {msg}")
        else:
            super().__init__(msg)


# ---------------------------------------------------------------------------
# Quoted-value unescaping
# ---------------------------------------------------------------------------
_ESCAPES = {"\\": "\\", '"': '"', "n": "\n", "t": "\t", "r": "\r"}


def unescape_quoted(raw: str, line: int | None = None) -> str:
    """Unescape a quoted value (without surrounding quotes).

    Processes: ``\\\\``, ``\\"``, ``\\n``, ``\\t``, ``\\r``.
    Raises ParseError on invalid escapes or unmatched quotes.
    """
    out: list[str] = []
    i = 0
    while i < len(raw):
        ch = raw[i]
        if ch == '"':
            raise ParseError("unescaped quote inside quoted value", line)
        if ch == '\\':
            i += 1
            if i >= len(raw):
                raise ParseError("unterminated escape sequence", line)
            esc = raw[i]
            if esc not in _ESCAPES:
                raise ParseError(f"invalid escape \\{esc}", line)
            out.append(_ESCAPES[esc])
        else:
            out.append(ch)
        i += 1
    return "".join(out)


def parse_value(raw: str, line: int | None = None) -> tuple[str, bool]:
    """Parse a raw value string. Returns (decoded_value, is_quoted)."""
    stripped = raw.strip()
    if stripped.startswith('"'):
        if not stripped.endswith('"') or len(stripped) < 2:
            raise ParseError("unmatched quote in value", line)
        inner = stripped[1:-1]
        return unescape_quoted(inner, line), True
    return stripped, False


# ---------------------------------------------------------------------------
# Token splitting for list items (handles quoted strings)
# ---------------------------------------------------------------------------
def split_tokens(s: str, line: int | None = None) -> list[str]:
    """Split string into tokens by unquoted whitespace."""
    tokens: list[str] = []
    i = 0
    n = len(s)
    while i < n:
        # skip whitespace
        while i < n and s[i] in (' ', '\t'):
            i += 1
        if i >= n:
            break
        # collect token
        start = i
        while i < n and (s[i] not in (' ', '\t')):
            if s[i] == '"':
                i += 1
                while i < n and s[i] != '"':
                    if s[i] == '\\':
                        i += 1  # skip escaped char
                    i += 1
                if i >= n:
                    raise ParseError("unterminated quoted string in token", line)
                i += 1  # skip closing quote
            else:
                i += 1
        tokens.append(s[start:i])
    return tokens


def parse_item_kv(
    s: str,
    line: int | None = None,
    required_quoted_keys: set[str] | None = None,
) -> dict[str, str]:
    """Parse a list item into key=value pairs with unescaped values."""
    tokens = split_tokens(s, line)
    result: dict[str, str] = {}
    required_quoted_keys = required_quoted_keys or set()
    for tok in tokens:
        eq = tok.find('=')
        if eq < 0:
            raise ParseError(f"expected key=value, got '{tok}'", line)
        key = tok[:eq]
        raw_val = tok[eq + 1:]
        if not RE_ITEM_KEY.match(key):
            raise ParseError(
                f"invalid item key '{key}' (must match ^[a-z][a-z_]*$)", line
            )
        if key in result:
            raise ParseError(f"duplicate item key '{key}'", line)
        val, is_quoted = parse_value(raw_val, line)
        if key in required_quoted_keys and not is_quoted:
            raise ParseError(f"{key} must be quoted", line)
        result[key] = val
    return result


# ---------------------------------------------------------------------------
# Path safety check
# ---------------------------------------------------------------------------
def validate_path(path: str, line: int | None = None) -> None:
    """Validate a file path per spec."""
    if not RE_PATH.match(path):
        raise ParseError(f"invalid path characters: '{path}'", line)
    if path.startswith('/'):
        raise ParseError(f"absolute path not allowed: '{path}'", line)
    parts = path.split('/')
    if '..' in parts:
        raise ParseError(f"path traversal not allowed: '{path}'", line)


# ---------------------------------------------------------------------------
# Main parsing logic (Steps 7-12)
# ---------------------------------------------------------------------------
def parse_payload(payload_lines: list[str]) -> dict[str, Any]:
    """Parse the block payload lines into a structured plan dict."""
    fields: dict[str, Any] = {}
    seen_keys: set[str] = set()
    files_items: list[dict[str, str]] = []
    acceptance_items: list[dict[str, str]] = []
    warnings: list[str] = []

    current_section: str | None = None
    pending_multiline: str | None = None
    pending_multiline_line: int | None = None
    multiline_parts: list[str] = []

    def _flush_multiline() -> None:
        nonlocal pending_multiline, pending_multiline_line, multiline_parts
        if pending_multiline is not None:
            if pending_multiline == "SUMMARY":
                if len(multiline_parts) == 0:
                    raise ParseError(
                        "SUMMARY must have at least one continuation line",
                        pending_multiline_line,
                    )
            joined = "\n".join(multiline_parts)
            if pending_multiline == "SUMMARY" and len(joined.strip()) == 0:
                raise ParseError(
                    "SUMMARY cannot be empty",
                    pending_multiline_line,
                )
            fields[pending_multiline] = joined
            pending_multiline = None
            pending_multiline_line = None
            multiline_parts = []

    for idx, raw_line in enumerate(payload_lines, start=1):
        # Step 7: classify each line

        # Tab at start → error
        if raw_line.startswith('\t'):
            raise ParseError("tab character at start of line", idx)

        # Blank line (0 chars) → skip; ends any active continuation
        if len(raw_line) == 0:
            _flush_multiline()
            # NOTE: do NOT reset current_section here — spec says blank lines
            # are just skipped, sections end only at next field header or sentinel
            continue

        # Continuation line (2+ leading spaces)
        if raw_line.startswith('  '):
            if pending_multiline is not None:
                # Strip exactly 2 spaces
                multiline_parts.append(raw_line[2:])
                continue
            raise ParseError("unexpected continuation (no active multi-line field)", idx)

        # If we get here with non-continuation, flush any pending multi-line
        _flush_multiline()

        # List item
        if raw_line.startswith('- '):
            if current_section is None:
                raise ParseError("list item outside section", idx)
            item_text = raw_line[2:]

            # Raw line length check
            if current_section == "FILES":
                if len(raw_line) > 1000:
                    raise ParseError("FILES line exceeds 1000 chars", idx)
                kv = parse_item_kv(item_text, idx, required_quoted_keys={"rationale"})
                unknown = set(kv.keys()) - FILES_REQUIRED_KEYS
                if unknown:
                    raise ParseError(f"unknown FILES keys: {sorted(unknown)}", idx)
                missing = FILES_REQUIRED_KEYS - set(kv.keys())
                if missing:
                    raise ParseError(f"missing FILES keys: {sorted(missing)}", idx)
                validate_path(kv["path"], idx)
                if kv["action"] not in VALID_ACTIONS:
                    raise ParseError(
                        f"invalid action '{kv['action']}' (must be add/modify/delete)", idx
                    )
                if "\n" in kv["rationale"] or "\r" in kv["rationale"]:
                    raise ParseError("rationale must be single-line", idx)
                if len(kv["rationale"]) > 300:
                    raise ParseError("rationale exceeds 300 chars", idx)
                files_items.append(kv)

            elif current_section == "ACCEPTANCE":
                if len(raw_line) > 600:
                    raise ParseError("ACCEPTANCE line exceeds 600 chars", idx)
                kv = parse_item_kv(item_text, idx, required_quoted_keys={"text"})
                unknown = set(kv.keys()) - ACCEPTANCE_REQUIRED_KEYS
                if unknown:
                    raise ParseError(f"unknown ACCEPTANCE keys: {sorted(unknown)}", idx)
                missing = ACCEPTANCE_REQUIRED_KEYS - set(kv.keys())
                if missing:
                    raise ParseError(f"missing ACCEPTANCE keys: {sorted(missing)}", idx)
                ac_id = kv["id"]
                if not RE_AC_ID.match(ac_id):
                    raise ParseError(f"invalid AC id '{ac_id}' (must match ^AC[0-9]+$)", idx)
                text = kv["text"]
                if len(text) == 0:
                    raise ParseError("acceptance text is empty", idx)
                if "\n" in text or "\r" in text:
                    raise ParseError("acceptance text must be single-line", idx)
                if len(text) > 400:
                    raise ParseError("acceptance text exceeds 400 chars", idx)
                # Check duplicate AC ids
                if any(a["id"] == ac_id for a in acceptance_items):
                    raise ParseError(f"duplicate acceptance id '{ac_id}'", idx)
                acceptance_items.append(kv)

                # Heuristic warning for vague verbs
                text_lower = text.lower()
                for verb in sorted(VAGUE_VERBS):
                    if re.search(rf'\b{re.escape(verb)}\b', text_lower):
                        warnings.append(
                            f"{ac_id} uses vague verb '{verb}' without metrics"
                        )
                        break
            continue

        # Section header (FILES: or ACCEPTANCE:)
        m_section = RE_SECTION_HEADER.match(raw_line)
        if m_section:
            key = m_section.group(1)
            if not RE_TOP_KEY.match(key):
                raise ParseError(f"invalid field name '{key}'", idx)
            if key not in ALLOWED_TOP_LEVEL:
                raise ParseError(f"unknown field '{key}'", idx)
            if key not in SECTION_FIELDS:
                raise ParseError(f"'{key}' cannot be a section header", idx)
            if key in seen_keys:
                raise ParseError(f"duplicate field '{key}'", idx)
            seen_keys.add(key)
            current_section = key
            continue

        # Key=value line
        m_kv = RE_KV_LINE.match(raw_line)
        if m_kv:
            key = m_kv.group(1)
            raw_val = m_kv.group(2)
            if key not in ALLOWED_TOP_LEVEL:
                raise ParseError(f"unknown field '{key}'", idx)
            if key in SECTION_FIELDS:
                raise ParseError(f"'{key}' must be a section header (use '{key}:')", idx)
            if key in seen_keys:
                raise ParseError(f"duplicate field '{key}'", idx)
            seen_keys.add(key)
            current_section = None

            # Check for multi-line start
            if key == "SUMMARY":
                if raw_val.strip() != '':
                    raise ParseError("SUMMARY must be multi-line (use SUMMARY=)", idx)
                pending_multiline = key
                pending_multiline_line = idx
                multiline_parts = []
                continue
            if key in MULTILINE_FIELDS and raw_val.strip() == '':
                pending_multiline = key
                pending_multiline_line = idx
                multiline_parts = []
                continue

            # Parse value (bare or quoted)
            val, is_quoted = parse_value(raw_val, idx)
            if key == "TITLE" and not is_quoted:
                raise ParseError("TITLE must be quoted", idx)
            if key in {"TASK_ID", "ESTIMATED_DIFF"} and is_quoted:
                raise ParseError(f"{key} must be unquoted", idx)
            fields[key] = val
            continue

        # Unrecognized line
        raise ParseError(f"unrecognized line content", idx)

    # Flush any trailing multi-line
    _flush_multiline()

    # ---------------------------------------------------------------------------
    # Step 9: Validate required fields
    # ---------------------------------------------------------------------------
    missing_fields = REQUIRED_FIELDS - seen_keys
    if missing_fields:
        raise ParseError(f"missing required fields: {', '.join(sorted(missing_fields))}")

    # ---------------------------------------------------------------------------
    # Step 11: Per-field restrictions
    # ---------------------------------------------------------------------------
    task_id = fields.get("TASK_ID", "")
    title = fields.get("TITLE", "")
    summary = fields.get("SUMMARY", "")
    notes = fields.get("NOTES")
    est_raw = fields.get("ESTIMATED_DIFF", "")

    # ESTIMATED_DIFF must be a positive integer, max 10 chars
    if len(est_raw) > 10:
        raise ParseError(f"ESTIMATED_DIFF exceeds 10 chars ({len(est_raw)})")
    if not re.fullmatch(r'[1-9][0-9]*', est_raw):
        raise ParseError(
            f"ESTIMATED_DIFF must be a positive integer, got '{est_raw}'"
        )

    if len(files_items) == 0:
        raise ParseError("FILES must have at least 1 item")
    if len(acceptance_items) == 0:
        raise ParseError("ACCEPTANCE must have at least 1 item")

    # ---------------------------------------------------------------------------
    # Step 12: Length caps (Unicode codepoints on decoded strings)
    # ---------------------------------------------------------------------------
    if len(task_id) > 64:
        raise ParseError(f"TASK_ID exceeds 64 chars ({len(task_id)})")
    if len(title) > 200:
        raise ParseError(f"TITLE exceeds 200 chars ({len(title)})")
    if len(summary) > 4000:
        raise ParseError(f"SUMMARY exceeds 4000 chars ({len(summary)})")
    if notes is not None and len(notes) > 4000:
        raise ParseError(f"NOTES exceeds 4000 chars ({len(notes)})")
    if len(files_items) > 50:
        raise ParseError(f"FILES has {len(files_items)} items (max 50)")
    if len(acceptance_items) > 30:
        raise ParseError(f"ACCEPTANCE has {len(acceptance_items)} items (max 30)")

    # ---------------------------------------------------------------------------
    # Step 13: Build output
    # ---------------------------------------------------------------------------
    return {
        "task_id": task_id,
        "title": title,
        "summary": summary,
        "files": [
            {"path": f["path"], "action": f["action"], "rationale": f["rationale"]}
            for f in files_items
        ],
        "acceptance": [
            {"id": a["id"], "text": a["text"]}
            for a in acceptance_items
        ],
        "estimated_diff": int(est_raw),
        "notes": notes,
        "warnings": warnings,
    }


# ---------------------------------------------------------------------------
# Public API (for module use)
# ---------------------------------------------------------------------------
def extract_plan(raw_text: str, nonce: str) -> dict[str, Any]:
    """Extract a plan from raw LLM output.

    Args:
        raw_text: Raw text (may contain anything; only sentinel block is parsed).
        nonce: Expected 6-char uppercase hex nonce.

    Returns:
        Structured plan dict.

    Raises:
        ParseError: On any validation failure.
        ValueError: If nonce format is invalid.
    """
    if not RE_NONCE.match(nonce):
        raise ValueError(f"invalid nonce format: '{nonce}' (must match ^[0-9A-F]{{6}}$)")

    # Step 2: CRLF normalize
    text = raw_text.replace("\r\n", "\n").replace("\r", "")

    # Step 3: Locate sentinel lines
    lines = text.split("\n")
    opener_indices: list[int] = []
    closer_indices: list[int] = []
    opener_nonces: list[str] = []
    closer_nonces: list[str] = []

    for i, line in enumerate(lines):
        m = PLAN_OPENER.match(line)
        if m:
            opener_indices.append(i)
            opener_nonces.append(m.group(1))
        m = PLAN_CLOSER.match(line)
        if m:
            closer_indices.append(i)
            closer_nonces.append(m.group(1))

    # Step 4: Enforce exactly-one-block
    if len(opener_indices) != 1:
        raise ParseError(
            f"expected exactly 1 <<<PLAN: block, found {len(opener_indices)}"
        )
    if len(closer_indices) != 1:
        raise ParseError(
            f"expected exactly 1 <<<END_PLAN: block, found {len(closer_indices)}"
        )

    opener_idx = opener_indices[0]
    closer_idx = closer_indices[0]
    open_nonce = opener_nonces[0]
    close_nonce = closer_nonces[0]

    if opener_idx >= closer_idx:
        raise ParseError("opener must appear before closer")

    # Nonce validation
    if open_nonce != close_nonce:
        raise ParseError(
            f"nonce mismatch: opener={open_nonce}, closer={close_nonce}"
        )
    if open_nonce != nonce:
        raise ParseError(
            f"nonce mismatch: block={open_nonce}, expected={nonce}"
        )

    # Step 5: Extract payload
    payload_lines = lines[opener_idx + 1: closer_idx]

    # Step 6: Block size cap
    payload_text = "\n".join(payload_lines)
    if len(payload_text) > 16_000:
        raise ParseError(
            f"block content exceeds 16000 chars ({len(payload_text)})"
        )

    # Steps 7-12: Parse and validate
    return parse_payload(payload_lines)


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------
def main() -> None:
    """CLI entry point: reads stdin, writes JSON to stdout or error to stderr."""
    parser = argparse.ArgumentParser(
        description="Extract sentinel-delimited plan from LLM output"
    )
    parser.add_argument(
        "--nonce", required=True,
        help="Expected 6-char uppercase hex nonce (e.g. 4F2C9A)"
    )
    args = parser.parse_args()

    # Validate nonce format
    if not RE_NONCE.match(args.nonce):
        print(
            f"error: invalid --nonce format '{args.nonce}' "
            f"(must match ^[0-9A-F]{{6}}$)",
            file=sys.stderr,
        )
        sys.exit(1)

    raw_text = sys.stdin.read()

    try:
        result = extract_plan(raw_text, args.nonce)
    except (ParseError, ValueError) as exc:
        print(f"error: {exc}", file=sys.stderr)
        sys.exit(1)

    json.dump(result, sys.stdout, ensure_ascii=False, indent=None)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()

```

## Done when
- `python3 .deadf/bin/parse-blocks.py plan --nonce 4F2C9A < tests/fixtures/sentinels/plan-valid.txt` exits `0` and prints JSON.
- Each subcommand validates its own block type and rejects malformed inputs with exit `1` (stderr message).
- Nonce mismatch cases exit `2` (stderr message).
- All files listed in Deliverables exist with the expected content/format.
- `extract_plan.py` is a thin wrapper over `parse-blocks.py plan` (no duplicated PLAN parsing logic).
