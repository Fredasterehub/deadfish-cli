# Restructure Track — Task Plan

## Tasks (6 total, phases 1b through 7)

### phase-1b: verify.sh fixes
- Switch from grep-based sentinel parsing → call `parse-blocks.py`
- YAML-frontmatter task parsing via `yq v4+` instead of grep
- Task file discovery via STATE.yaml (`track.task_current`, `track.id`) instead of hardcoded paths
- Fix all 3 contract/tool mismatches from GPT-5.2 codebase analysis
- **AC:** verify.sh runs clean on a sample task packet; no grep for sentinel patterns; yq parses frontmatter

### phase-2: Launcher unification (kick.sh)
- Unify ralph.sh + cron-kick.sh into single `kick.sh` entrypoint
- kick.sh reads STATE.yaml, dispatches one action, updates state
- Move to `.deadf/bin/kick.sh`
- **AC:** `kick.sh` runs one cycle end-to-end; ralph.sh becomes thin wrapper calling kick.sh

### phase-3: File layout migration (.pipe → .deadf)
- Move all pipeline files from `.pipe/` to `.deadf/` per synthesis layout
- Update all internal references (paths in scripts, CLAUDE.md, etc.)
- Templates get semantic names (no P-numbers in filenames)
- **AC:** No file references `.pipe/`; all tools find their deps under `.deadf/`

### phase-4: CLAUDE.md split
- Rewrite CLAUDE.md as ≤300 line binder
- Extract invariants to `.claude/rules/` (core.md, state-locking.md, safety.md, output-contract.md)
- Explicit `read` calls in CLAUDE.md for contracts and templates
- **AC:** CLAUDE.md ≤300 lines; `wc -l` confirms; all rules files exist and are referenced

### phase-5: New artifacts
- manifest.yaml (passive — file list + hashes)
- lint-templates.py (template ↔ contract drift checker)
- track.yaml per-track metadata
- tracks/index.md overview
- **AC:** manifest.yaml lists all .deadf/ files with sha256; lint-templates.py runs clean

### phase-6: Validation suite
- test-parsers.sh golden test runner (all fixtures)
- test-templates.sh template lint runner
- Integration test: full cycle on mock project
- **AC:** All test scripts exit 0; CI-ready

### phase-7: Cleanup
- Remove `.pipe/` directory (archive design docs to `docs/`)
- Remove old P-numbered files
- Update README.md, llms.txt
- Final git tag `restructure-v2-complete`
- **AC:** No `.pipe/` in tree; git clean; tag exists
