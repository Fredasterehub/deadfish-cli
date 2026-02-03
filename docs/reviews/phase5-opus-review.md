# Phase 5 QA Review — New Artifacts

**Reviewer:** Claude Opus (sub-agent)
**Date:** 2026-02-03T00:22 EST
**Verdict:** NEEDS_FIXES

---

## 1. manifest.yaml — ✅ CLEAN

- **File count:** 52 entries. Matches exactly the 52 files found on disk via `find .deadf/{bin,contracts,templates} -type f`.
- **Hash format:** All 52 hashes are 64 hex chars (SHA-256). ✓
- **Hash spot-check (3 files):**
  | File | Manifest hash | `sha256sum` | Match? |
  |------|--------------|-------------|--------|
  | `bin/lint-templates.py` | `b9164f9a…68f6ba` | `b9164f9a…68f6ba` | ✅ |
  | `contracts/sentinel/diagnostic.v1.md` | `dab4c187…c65bc4f` | `dab4c187…c65bc4f` | ✅ |
  | `templates/repair/auto-diagnose.md` | `4668082e…052a9c8` | `4668082e…052a9c8` | ✅ |
- **Includes lint-templates.py?** Yes ✓
- **Includes diagnostic.v1.md?** Yes ✓
- **Disk ↔ manifest diff:** Empty (perfect match) ✓

**Minor observation:** Manifest includes `.deadf/bin/__pycache__/parse-blocks.cpython-313.pyc`. Bytecache files are regenerated on each Python run and platform-specific. Consider excluding `__pycache__/` from the manifest.

**Severity:** Low / cosmetic. Not blocking.

---

## 2. lint-templates.py — ⚠️ NEEDS_FIX (1 bug)

### Positive
- **Stdlib only:** Imports are `argparse`, `re`, `sys`, `pathlib` — all stdlib. No PyYAML or external deps. ✓
- **Manifest parsing:** Uses regex `r"^\s*-\s+path:\s*(.+?)\s*$"` — correct for this simple YAML structure. ✓
- **Sentinel ref detection:** `r"<<<([A-Z0-9_]+):V(\d+):"` — correctly extracts block type and version from openers. Skips `END_` blocks. ✓
- **Run output:** All 52 manifest files present, 7 template→grammar links verified, exit code 0. ✓

### Bug: Double-escaped regex on line ~70

```python
has_marker = re.search(r"<<<[A-Z0-9_]+:V\\d+:", text) is not None
```

The `\\d` in the raw string becomes the literal characters `\d` instead of the digit character class `\d`. This means the `has_marker` check **never matches**, so the orphaned-template warning (for templates that have sentinel-like syntax but no extractable refs) is dead code.

**Impact:** The orphaned-template warning path is unreachable. The main sentinel extraction (line ~30) uses the correct regex `r"<<<([A-Z0-9_]+):V(\d+):"` so all real drift detection works fine. Only this supplementary check is broken.

**Fix:** Change `\\d` to `\d`:
```python
has_marker = re.search(r"<<<[A-Z0-9_]+:V\d+:", text) is not None
```

**Severity:** Medium. Functional bug, but in a supplementary warning path — core drift detection is unaffected.

---

## 3. diagnostic.v1.md — ✅ CLEAN

- **Structure:** Well-formed sentinel grammar doc. Documents opener/closer regexes, two modes (FIXED, MISMATCH), field table for MISMATCH, and a working example. ✓
- **auto-diagnose.md cross-check:** The template uses both `<<<DIAGNOSTIC:V1:FIXED>>>` and `<<<DIAGNOSTIC:V1:MISMATCH>>>` with matching closers. The grammar covers both modes. ✓
- **Field alignment:** Template asks for `COMPONENT`, `EXPLANATION`, `SUGGESTED_FIX` — grammar specifies exactly these three fields with matching constraints (quoted, single-line, ≤500 chars). ✓
- **Opener regex in grammar:** `^<<<DIAGNOSTIC:V1:(FIXED|MISMATCH)>>>$` — matches the template's usage. ✓

No issues.

---

## 4. track.yaml — ✅ CLEAN

- `id: restructure` ✓
- `name: "Pipeline Restructure v2"` ✓
- `status: in-progress` ✓
- `task_count: 7` (phases 1–7) ✓
- `task_current: 5` (we are on phase 5) ✓
- `plan_path: .deadf/tracks/restructure/plan.md` — file exists on disk ✓
- `spec_path: null` with comment explaining restructure had no formal spec ✓
- `created_at: "2026-02-02T00:00:00Z"` — plausible ✓

No issues.

---

## 5. index.md — ✅ CLEAN

- Markdown table format, single entry for `restructure` track. ✓
- Append-only friendly: header + separator + data rows; new tracks just add rows. ✓
- Data matches track.yaml (ID, name, status, 7 tasks, 2026-02-02 created). ✓

No issues.

---

## Summary

| # | File | Verdict | Issues |
|---|------|---------|--------|
| 1 | manifest.yaml | ✅ CLEAN | Minor: __pycache__ inclusion (LOW) |
| 2 | lint-templates.py | ⚠️ NEEDS_FIX | Double-escaped regex bug (MEDIUM) |
| 3 | diagnostic.v1.md | ✅ CLEAN | — |
| 4 | track.yaml | ✅ CLEAN | — |
| 5 | index.md | ✅ CLEAN | — |

**Overall: NEEDS_FIXES** — one medium-severity bug in lint-templates.py (line ~70 double-escaped `\\d`). Everything else is clean.
