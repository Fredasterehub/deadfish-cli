# Phase 7 QA Review — Final Cleanup

**Reviewer:** Claude Opus 4.5 (sub-agent)
**Date:** 2026-02-03
**Verdict:** ⚠️ NEEDS_FIXES

---

## Summary

Phase 7 is ~85% clean. The core goals are met (`.pipe/` removed from tracking, docs migrated, tests pass, README/llms.txt updated). However, two issues need attention before committing:

1. **19 files have AD (Added-then-Deleted) status** — data loss risk
2. **Changes are staged but NOT committed** — no Phase 7 commit exists yet

---

## Criteria Results

### 1. Is `.pipe/` fully gone from git tracking? ✅ PASS

```
$ git ls-files .pipe/ | wc -l
0
```

All `.pipe/` files are either deleted from tracking or gitignored. The two backward-compat wrappers (`p12-init.sh`, `p2-brainstorm.sh`) remain on disk but are properly gitignored.

### 2. Are design docs properly archived? ⚠️ PARTIAL

The `docs/` structure is well-organized:
- `docs/reviews/` — 19 review files ✅
- `docs/design/misc/` — 16 miscellaneous design docs ✅
- `docs/design/restructure/` — 15 restructure-specific docs ✅
- `docs/design/codex-prompts/` — only 2 of 14 files survive on disk ❌
- `docs/design/plans/` — directory doesn't exist on disk ❌
- `docs/design/syntheses/` — directory doesn't exist on disk ❌

**19 files are in git's staging area (index) but deleted from the working tree (AD status).** These files were staged for addition, then removed from disk. Categories:

| Directory | Files missing from disk |
|-----------|------------------------|
| `docs/design/codex-prompts/` | 12 files (p1, p6, p7, p9, p9.5, p10, p11, t01-t03, t04-t06, t07-t09, t10, task) |
| `docs/design/plans/` | 4 files (plan-conductor, plan-gpt52, plan-gsd, plan-opus) |
| `docs/design/syntheses/` | 3 files (synthesis-opus-orchestrator, synthesis-review-gpt52-r2, synthesis-review-gpt52) |

If committed as-is, the files would exist in the git commit (content is in the index), but the working tree would be inconsistent. These files likely need to be either:
- **Restored on disk** (`git checkout -- <path>` for each), or
- **Unstaged** if they were intentionally excluded

### 3. llms.txt paths correct? ✅ PASS

All references point to `.deadf/` paths. No stale `.pipe/` references. Structure is clean and accurate.

### 4. README.md updated? ✅ PASS

- Project structure section shows `.deadf/` layout correctly
- No `.pipe/` references anywhere in README
- "For LLMs" section references `.deadf/` paths
- All actor descriptions reference `.deadf/bin/` paths

### 5. Tests still pass? ✅ PASS

```
Parser tests:  13 passed, 0 failed
Template tests: 5 passed, 0 failed
```

### 6. No data loss? ⚠️ NEEDS VERIFICATION

The 19 AD-status files are the concern. Their content exists in git's index (staging area) but NOT on the filesystem. This needs resolution — either restore them to disk or confirm they were intentionally dropped.

### 7. .gitignore updated? ✅ PASS

Properly ignores `.pipe/` patterns for backward-compat wrappers and runtime state.

---

## Additional Notes

- **No commit exists yet** — all 110 files of changes (12,843 insertions, 2,670 deletions) are staged but uncommitted
- **Untracked file:** `.deadf/tracks/restructure/plan.md` — may need to be committed or gitignored

---

## Required Fixes

1. **Resolve 19 AD-status files** — either `git checkout --` to restore them on disk, or `git rm --cached` to unstage them if intentionally excluded
2. **Commit the Phase 7 changes** — the work is done but not persisted to git history

## Optional

3. Address `.deadf/tracks/restructure/plan.md` (untracked)
