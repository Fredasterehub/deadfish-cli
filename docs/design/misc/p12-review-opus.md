# P12 Review — Opus 4.5 QA

**Date:** 2025-07-25  
**Reviewer:** Claude Opus 4.5 (sub-agent)  
**Scope:** Full P12 implementation (8 micro-tasks by GPT-5.2-Codex)  
**Canonical spec:** `.pipe/p12-design-unified.md`

---

## VERDICT: NEEDS_FIXES

Two critical issues, two high issues, several medium. Core architecture is solid and well-implemented. Fixes are surgical — no redesign needed.

---

## Findings

### CRITICAL-1: ralph.sh calls undefined functions `notify` and `print_summary`

**File:** `ralph.sh` lines 415-417  
**Impact:** P12 init failure handler will crash with "command not found"

```bash
# Line 413-417:
log_err "P12 init runner failed"
set_phase_needs_human
notify "p12-init-failed" "P12 init runner failed. Run: .pipe/p12-init.sh --project \"$PROJECT_PATH\""
release_lock
print_summary    # <-- undefined
```

Neither `notify` nor `print_summary` are defined anywhere in ralph.sh. The existing ralph.sh functions are: `log`, `log_err`, `acquire_lock`, `release_lock`, `cleanup`, `on_exit`, `collect_descendants`, `read_field`, `get_*`, `update_state_field`, `set_phase_needs_human`, `set_cycle_timed_out`, `require_state_update`, `validate_state`, `rotate_logs`, `generate_cycle_id`, `stat_perms`.

**Fix:** Replace with existing ralph.sh patterns:
```bash
log_err "P12 init runner failed"
set_phase_needs_human
release_lock
exit 1
```
Or define `notify`/`print_summary` if the rest of ralph.sh needs them (but they don't exist pre-P12 either, so this looks like Codex hallucinated functions).

---

### CRITICAL-2: P12_INJECT.sh awk variable passing corrupts content with backslashes

**File:** `P12_INJECT.sh` lines 131-138  
**Impact:** YAML content containing backslashes (regex patterns, Windows paths, escape sequences) will be corrupted in the brownfield context block injected into P2.

The `escape_awk_repl` function doubles `&` and `\` for gsub replacement safety, but `awk -v` also interprets escape sequences, consuming one escaping layer. The two levels of interpretation are not properly accounted for.

**Chain:**  
`\` in YAML → `\\` after escape_awk_repl → `\` after awk `-v` interpretation → treated as escape char by gsub → **content corruption**

**Fix:** Use awk's `ENVIRON` or `getline` from file instead of `-v`:
```bash
export P12_TECH="$TECH_YAML"
export P12_PROD="$PRODUCT_YAML"
export P12_OQ="$OPEN_QUESTIONS"
awk '
    { gsub(/\{\{TECH_STACK_YAML\}\}/, ENVIRON["P12_TECH"])
      gsub(/\{\{PRODUCT_YAML\}\}/, ENVIRON["P12_PROD"])
      gsub(/\{\{OPEN_QUESTIONS\}\}/, ENVIRON["P12_OQ"])
      print }
' "$TEMPLATE_FILE"
```
`ENVIRON` does NOT interpret escape sequences.

**Note:** For typical living docs YAML (no backslashes), the current code works. But this is a brownfield tool — real-world codebases will have backslashes in paths, regexes, and CI configs.

---

### HIGH-1: P12_DETECT.sh does not short-circuit on returning scenario

**File:** `P12_DETECT.sh` lines 180-201  
**Spec says:** "Returning: checked first, highest priority"  
**Implementation:** Returning check happens AFTER all signal computation (source file counting, find operations for deps/CI/docker/tests).

The final output order is correct (returning → brownfield → greenfield), so **results are not wrong**. But for returning projects (which have `.deadf/seed/P2_DONE` + `STATE.yaml`), the script needlessly runs expensive `find` operations across the entire tree.

**Fix:** Move the returning check right after resolving `PROJECT_PATH`, before signal computation:
```bash
# Check returning FIRST (highest priority, cheapest check)
if [[ -f "$PROJECT_PATH/.deadf/seed/P2_DONE" && -f "$PROJECT_PATH/STATE.yaml" ]]; then
    printf '{"type":"returning","signals":[],"depth":1,"src_count":0}\n'
    exit 2
fi
```

**Severity note:** This doesn't produce wrong results, just wastes time. Upgraded to HIGH because the spec explicitly calls this out as "highest priority" and it's a simple fix.

---

### HIGH-2: P12_MAP.sh synthesizer prompt injection doesn't match SYNTHESIZER.md format

**File:** `P12_MAP.sh` lines ~160-170  
**Issue:** The script prepends `<<<FILE:...>>>` marker format instructions before SYNTHESIZER.md content, but SYNTHESIZER.md itself says:

> Write each file. Use exactly these filenames: 1. TECH_STACK.md ...

These are potentially conflicting instructions to the LLM. The synthesizer prompt also uses `awk` to replace `{YAML analysis from mapper agent}` placeholder, but SYNTHESIZER.md wraps this in `<analysis>` tags. The awk replacement is a plain text match, not tag-aware.

**Risk:** LLM may produce markdown format (per SYNTHESIZER.md) instead of `<<<FILE:...>>>` marker format (per prepended instruction), causing `parse_marked_output` to find no files → fallback docs always used.

**Fix:** Either:
(a) Update SYNTHESIZER.md to specify the `<<<FILE:...>>>` marker format directly, OR
(b) Add a second parser that handles markdown-based output (each `# TECH_STACK.md` header as separator)

---

### MEDIUM-1: P12_COLLECT.sh entry point file matching too broad

**File:** `P12_COLLECT.sh` line ~120  
**Pattern:** `-name "main.*" -o -name "index.*" -o -name "app.*"`  
**Issue:** Matches `main.css`, `index.html`, `app.scss`, `app.config.js` — any file starting with main/index/app regardless of type.

**Fix:** Restrict to source file extensions:
```bash
-name "main.ts" -o -name "main.js" -o -name "main.py" -o -name "main.go" -o -name "main.rs" \
-o -name "index.ts" -o -name "index.js" -o -name "index.py" \
-o -name "app.ts" -o -name "app.js" -o -name "app.py" -o -name "app.rb"
```

---

### MEDIUM-2: p12-budget-check.sh token estimation direction

**File:** `p12-budget-check.sh` line 30  
**Code:** `tokens=$(( words * 4 / 3 ))`  
**Spec says:** "1 token ≈ 0.75 words" → tokens = words / 0.75 = words × 4/3

The math is technically correct per the spec formula. However, the conventional estimate is ~1.3 tokens per word for English, meaning the spec's "1 token ≈ 0.75 words" gives `tokens = words / 0.75`, which is what's implemented. This will **over-estimate** token count (conservative), which is the safe direction. No fix needed but noting for awareness.

---

### MEDIUM-3: P12_INJECT.sh exits fatally when TECH_STACK.md or PRODUCT.md missing

**File:** `P12_INJECT.sh` lines 103-109  
**Spec says:** "P12 failure is NEVER fatal. Always degrade to greenfield brainstorm."  
**Code:** `exit 1` on missing files.

The caller (`p2-brainstorm.sh`) does check the exit code and fails too (`exit 1`). This means a partially-completed P12 (e.g., mapping succeeded but confirmation skipped TECH_STACK.md) will block P2 entirely instead of degrading to greenfield.

**Fix:** P12_INJECT.sh should output an empty/minimal context block on missing files, or p2-brainstorm.sh should catch the failure and fall back to greenfield mode.

---

### MEDIUM-4: P12_CONFIRM.sh writes unverified marker but always writes DONE marker

**File:** `P12_CONFIRM.sh` lines 107-114  
**Issue:** If the operator skips ALL 7 docs, both `P12_UNVERIFIED` (listing all 7) and `P12_DONE` are written. Downstream code checks `P12_DONE` to decide brownfield mode — it will enter brownfield mode with no usable docs.

**Fix:** If all docs skipped, don't write `P12_DONE`, or write it with a flag indicating no docs were confirmed.

---

### MEDIUM-5: CLAUDE.md P12 documentation is minimal

**File:** `CLAUDE.md`  
**Spec says (micro-task 7):** "CLAUDE.md documents P12 phase"  
**Reality:** Only 2 references — line 185 (operator instruction to run p12-init.sh) and line 190 (note about P12_DONE marker). No documentation of:
- What P12 is (codebase mapper / brownfield detection)
- The 7 living docs or their purpose
- How living docs feed into downstream phases
- The smart loading map concept

**Fix:** Add a "## P12: Codebase Mapper" section to CLAUDE.md explaining the phase, its outputs, and how they integrate.

---

### MEDIUM-6: P12_MAP.sh `claude --print` may not be valid CLI syntax

**File:** `P12_MAP.sh` line ~139  
**Code:** `claude --print < "$prompt_file" > "$ANALYSIS_FILE"`  
**Risk:** `claude --print` reads from stdin — this works with the Claude CLI's `--print` flag that outputs to stdout without interactive mode. However, the prompt is the entire MAPPER_AGENT.md + raw evidence concatenated, which could exceed context limits for large codebases.

No cap on evidence size is enforced before sending to Claude. The 500-entry tree cap in P12_COLLECT.sh helps, but dependency files (100 lines each × N manifests) + configs + docs could still be very large.

**Fix:** Add a total evidence size cap in P12_MAP.sh before sending to Claude (e.g., truncate concatenated evidence at 100KB).

---

### LOW-1: P12_DETECT.sh requires bash 4+ (associative arrays)

**File:** `P12_DETECT.sh` line 78  
**Code:** `declare -A lang_seen=()`  
**Impact:** Will fail on macOS with default bash 3.2. Linux systems are fine.

**Fix:** Document bash 4+ requirement, or use a simpler counting method.

---

### LOW-2: p12-init.sh JSON parsing is fragile

**File:** `p12-init.sh` line 79  
**Code:** `sed -n 's/.*"depth"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p'`  
**Issue:** Regex-based JSON parsing. Works for the simple P12_DETECT.sh output but fragile.

**Fix:** Use `jq` if available, fall back to sed. Or since the JSON is always on one line in a known format, this is acceptable for MVP.

---

### LOW-3: P12_COLLECT.sh find commands may produce no output silently

**File:** `P12_COLLECT.sh` various `while IFS= read` loops  
**Issue:** If no matching files found, the loop body never executes — this is correct behavior but no diagnostic is logged.

---

### LOW-4: Missing `--dry-run` support in P12_COLLECT.sh

**File:** `P12_COLLECT.sh`  
**Spec (micro-task 2):** Doesn't explicitly require `--dry-run`, but it's inconsistent with the other P12 scripts that all support it.

---

## What's Good

1. **Architecture is clean.** The detect → collect → map → confirm → inject pipeline follows the spec faithfully. Each script has a single responsibility.

2. **All scripts pass `bash -n`.** Zero syntax errors across 8 files.

3. **Consistent argument parsing.** Every script uses the same `while [[ $# -gt 0 ]]` / `case` pattern with proper `--help`, missing-value checks, and positional fallback.

4. **Graceful degradation in P12_MAP.sh.** The fallback analysis → fallback docs chain is well-implemented. LLM failure → deterministic skeleton → pipeline continues. The `write_fallback_analysis` YAML is comprehensive.

5. **LIVING_DOCS.tmpl is clever.** Using the same `<<<FILE:...>>>` marker format for both LLM output and the fallback template means one parser (`parse_marked_output`) handles both paths.

6. **Evidence collection is thorough.** P12_COLLECT.sh covers tree, deps, configs, docs, CI, and entry points — all with sensible line caps and noise exclusion.

7. **P2 brownfield integration is well-wired.** `p2-brainstorm.sh` gained `--context-mode`, `--context-files`, auto-detection from `P12_DONE`, and proper injection via P12_INJECT.sh. The template substitution approach keeps P2_MAIN.md untouched.

8. **Interactive confirmation flow.** P12_CONFIRM.sh's section-by-section C/E/S flow with `$EDITOR` support and skip tracking is user-friendly.

9. **All files are executable.** Permissions are correctly set (755) on all scripts.

10. **p12-init.sh returning flow.** The [C]ontinue / [R]efresh / Re-[B]rainstorm interactive choice matches spec exactly.

11. **Prompt quality.** MAPPER_AGENT.md has the full YAML output contract. BROWNFIELD_P2.md has all 4 adjusted questions plus the template placeholders. SYNTHESIZER.md enforces the <5000t budget with per-doc targets.

---

## Summary Table

| # | Severity | File | Issue |
|---|----------|------|-------|
| 1 | **CRITICAL** | ralph.sh | Calls undefined `notify` and `print_summary` functions |
| 2 | **CRITICAL** | P12_INJECT.sh | awk `-v` + gsub double-interpretation corrupts backslashes |
| 3 | **HIGH** | P12_DETECT.sh | Returning check not short-circuited (spec: "highest priority") |
| 4 | **HIGH** | P12_MAP.sh | Synthesizer prompt format conflict (markers vs markdown) |
| 5 | MEDIUM | P12_COLLECT.sh | Entry point matching too broad (`main.*` etc.) |
| 6 | MEDIUM | p12-budget-check.sh | Token estimation noted (correct but worth documenting) |
| 7 | MEDIUM | P12_INJECT.sh | Fatal exit on missing docs violates graceful degradation spec |
| 8 | MEDIUM | P12_CONFIRM.sh | Writes P12_DONE even when all docs skipped |
| 9 | MEDIUM | CLAUDE.md | P12 phase barely documented |
| 10 | MEDIUM | P12_MAP.sh | No evidence size cap before LLM call |
| 11 | LOW | P12_DETECT.sh | Requires bash 4+ (associative arrays) |
| 12 | LOW | p12-init.sh | Regex-based JSON parsing (fragile) |
| 13 | LOW | P12_COLLECT.sh | No diagnostics when no files found |
| 14 | LOW | P12_COLLECT.sh | Missing `--dry-run` (inconsistent with other scripts) |

---

## Recommendation

**Fix CRITICALs and HIGHs before merge.** The undefined function calls in ralph.sh (CRITICAL-1) will crash at runtime. The awk escaping issue (CRITICAL-2) will corrupt brownfield context for real-world codebases. The synthesizer format mismatch (HIGH-2) may cause the mapping phase to always fall back to skeleton docs.

MEDIUMs can be addressed in a fast-follow — none block the happy path for typical projects.

The implementation is fundamentally sound. The architecture, separation of concerns, error handling patterns, and spec compliance are all strong. These are integration bugs, not design flaws.
