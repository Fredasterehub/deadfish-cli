## Verdict: NEEDS_REVISION

## Findings

- **(CRITICAL) Auto-load + `@import` assumptions are overstated / under-specified.**
  - The synthesis hinges on two behaviors: (1) Claude Code auto-loading `.claude/rules/*.md`, and (2) “`@import` on-demand” loading `.claude/imports/**` during a cycle.
  - The current binding contract in `CLAUDE.md` v2.4.2 does not mention `.claude/` at all and is written assuming explicit file reads plus explicit `.pipe/...` paths. Unless Claude Code *actually* has a guaranteed auto-load mechanism for `.claude/rules/` and a guaranteed `@import` file-inclusion mechanism in non-interactive `claude --print` runs, the proposed split can silently fail (missing action specs/grammars at runtime).
  - Required fix in the synthesis: rewrite the split as a **contract-level deterministic LOAD rule** (“always read `.claude/rules/*.md` in Step 1; when action X chosen, explicitly read `.claude/imports/actions/X.md`; when parsing block Y, explicitly read `.claude/imports/grammars/Y.md`”), and treat `@import` as optional sugar (if supported), not a dependency.

- **(HIGH) “Best of both plans” merge is directionally right, but it drops/contradicts some GPT‑5.2 details without calling it out.**
  - Good merge: on-demand imports (GPT‑5.2) + eliminate `.pipe/` in favor of `templates/` + `scripts/` + `docs/` (Opus) + “fix tools before moving paths” ordering (GPT‑5.2).
  - Missing from synthesis (but important from GPT‑5.2 plan): explicit path-scoped rules (frontmatter `paths:`) to prevent global rule pollution; and keeping `.pipe/` as a “runtime vs workbench” split (instead, synthesis adopts Opus’s “delete `.pipe/` entirely”). That’s fine, but the synthesis should explicitly justify why the `.pipe/runtime` approach is rejected.

- **(MEDIUM) File structure is mostly clean, but one axis needs tightening: “repo layout” vs “deployed `.deadf/` layout”.**
  - The synthesis is consistent internally (rules/imports vs templates/scripts vs docs/tests), but it should explicitly declare **one canonical mapping**:
    - repo `templates/**` → deployed `.deadf/templates/**`
    - repo `scripts/**` → deployed `.deadf/scripts/**`
    - repo `CLAUDE.md` / `.claude/**` → deployed `.deadf/` (yes/no, and if yes: exact destination and load behavior)
  - Without this, target projects can drift (e.g., updates to templates exist in deadfish-cli but never get copied into a target project’s `.deadf/`).

- **(MEDIUM) Phase ordering is realistic, but it underestimates “dual-path compatibility” work.**
  - “Fix tools before restructuring files” is correct, but eliminating `.pipe/` while tool fixes are underway will likely require **temporary compatibility shims** (wrappers or symlinks) or a carefully staged move to avoid breaking ongoing cycles.
  - The synthesis should explicitly plan a “compat window” (e.g., keep `.pipe/` wrappers pointing to `templates/` and `scripts/` until Phase 6 cleanup).

- **(HIGH) Risks missed / under-emphasized.**
  - Parser/tooling contracts are tightly coupled to templates and sentinel grammars; moving grammars out of templates into `.claude/imports/grammars/` risks divergence unless there is a single source of truth and tests enforce it.
  - The validation checklist includes `grep -rn '\.pipe/' . = 0`, but if historical docs are preserved (design/reviews), that constraint may be unrealistic or counterproductive (it either forces rewriting history artifacts or moving them out of tree). The check should be scoped to “runtime + contract + scripts”, not “entire repo”.
  - “Counts” checks (`wc -l` caps) are helpful but can be gamed; the real risk is *token volume in typical cycles*. Consider measuring actual loaded context in a representative cycle (LOAD set) rather than line counts alone.

- **(MEDIUM) `.deadf/` deployment model is acknowledged but not fully operationalized.**
  - The synthesis includes Fred’s directive and the high-level “copy into `.deadf/`” model, but it doesn’t specify:
    - the authoritative deploy/update command (script name, inputs, idempotency),
    - versioning/migrations for `.deadf/` contents across pipeline upgrades,
    - how a target project pins or updates the pipeline version safely.

## Summary

The synthesis largely does merge the strongest strategic ideas (tool-first ordering + on-demand imports + semantic naming + eliminating `.pipe/` clutter), but it currently treats Claude Code auto-load/`@import` behavior as guaranteed when it isn’t established by the current contract. Revise the synthesis to make loading action specs/grammars a deterministic contract requirement (independent of UI conveniences), and add a concrete `.deadf/` deploy/update mechanism + explicit repo↔deployed mapping. With those changes, the overall restructure plan becomes coherent and executable.

