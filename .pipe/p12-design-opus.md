# P12 Design — Codebase Mapper / Brownfield Detection

> Authored by Claude Opus 4.5 (subagent). Sources: FINAL_PLAN_v5.1.md, CLAUDE.md, P2_MAIN.md, p2-brainstorm.sh, ralph.sh, METHODOLOGY.md, PROMPT_OPTIMIZATION.md, ANALYSIS.md, GPT52-ANALYSIS.md.

---

## 1. Implementability Assessment of FINAL_PLAN_v5.1

### Directly Implementable (Phase 1 MVP)

| Feature | Spec Reference | Notes |
|---------|---------------|-------|
| Brownfield detection heuristics | "2+ signals: .git, source files, deps, CI" | Simple bash/shell checks. No ambiguity. |
| Single-pass mapper | "general analysis" | One Claude sub-agent reads tree + key files, outputs structured YAML. |
| Machine-optimized doc generation | YAML format, TECH_STACK.md example | The example format in v5.1 is directly usable as an output template. |
| Existing doc intake (README distillation) | "hints not truth" | Read README/docs, extract claims, mark as `confidence: unverified`. |
| Interactive confirmation flow | "per-category validation" | Present each doc section, ask operator yes/edit/skip. |
| Context budget enforcement | "ALL living docs combined < 5000 tokens" | Hard-cap with `tiktoken` or word-count heuristic (1 token ≈ 0.75 words). |
| Preflight display | "Detected: [greenfield\|brownfield\|returning]" | Print detection result + signal list before proceeding. |
| Seamless transition to P2 | "What do you want to do?" → brainstorm | After confirmation, invoke P2 with enriched context injected. |

### Needs Refinement

| Feature | Issue | Proposed Refinement |
|---------|-------|-------------------|
| **Living doc targets** | v5.1 lists 10 docs (VISION through GLOSSARY) but also says "No new files by default. Sections inside existing docs." These conflict — if brownfield detection creates TECH_STACK.md etc., those ARE new files. | **Resolution:** P12 creates `.deadf/seed/CODEBASE_MAP.md` as ONE file with sections (tech_stack, patterns, pitfalls, risks, workflow, product, glossary). This feeds P2 as context. P2 then creates VISION.md and ROADMAP.md. Post-P2, the orchestrator splits relevant sections into per-track smart-loading docs IF the combined budget allows. This keeps P12 output as a single artifact and avoids premature file proliferation. |
| **Dynamic analysis depth (1-4 passes)** | v5.1 says "Orchestrator picks depth" but doesn't define the heuristic for choosing 1 vs 2 vs 3 vs 4 passes, nor what each pass covers. | **Resolution:** Define explicit depth triggers. See §3.2 below. MVP ships with depth 1 (single-pass) only. Depth 2-4 are Phase 2 work. |
| **Git history signals** | "Hot vs stale files for confidence" — useful but expensive (git log parsing across entire repo). | **Resolution:** Phase 2. MVP uses `git log --oneline -1` for repo age and `git log --diff-filter=M --since="3 months" --name-only` for hot files. Cap at 500 files. |
| **Smart loading per track type** | The track-type→doc mapping table is clean but happens AFTER P12, during execution. P12 doesn't know what tracks will be selected. | **Resolution:** P12 doesn't implement smart loading. P12 produces the map. Smart loading is the orchestrator's job during `select-track` phase. P12 just ensures the map exists and is within budget. |
| **Multi-model mapper agents** | "Claude sub-agents for mapping, GPT-5.2 for planning" — sub-agents via Task tool can't access MCP (per CLAUDE.md §Sub-Agent MCP Restriction). | **Resolution:** Claude sub-agents for analysis (via Task tool). GPT-5.2 for doc synthesis (via `codex exec`). The mapper sub-agents do read-only analysis; GPT-5.2 produces the final structured output. |
| **Returning flow** | "Restart / Refine / Continue" — requires detecting `.deadf/` exists with prior state. | **Resolution:** Phase 2. MVP detects returning (`.deadf/seed/P2_DONE` exists + STATE.yaml exists) and offers three choices, but the actual refine/continue logic is deferred. |
| **Parallel mapper agents** | v5.1 says "dynamic count" but doesn't spec how to partition work. | **Resolution:** Phase 2. Partition by concern: (1) structure+stack, (2) patterns+architecture, (3) risks+pitfalls, (4) product+workflow. Each is a Task tool sub-agent. |

### Out of Scope for P12

| Feature | Why |
|---------|-----|
| Change-impact heuristics | Execution-phase concern, not init-phase. |
| Ownership signals | Requires git blame analysis — Phase 2 at earliest. |
| Smart loading per track type | Orchestrator concern during `select-track`, not P12. |

---

## 2. Integration with Existing P2 Flow

### Current Flow (without P12)

```
ralph.sh kicks cycle
  → phase: research
  → orchestrator checks P2_DONE
  → if missing: set phase: needs_human, instruct operator to run p2-brainstorm.sh
  → operator runs p2-brainstorm.sh
  → codex -m gpt-5.2 runs P2_MAIN.md (interactive brainstorm)
  → produces VISION.md + ROADMAP.md
  → touches .deadf/seed/P2_DONE
  → orchestrator advances to select-track
```

### New Flow (with P12)

```
deadfish init <name> [--path <dir>]
  │
  ├── P12 Preflight Detection
  │   ├── Scan signals → classify greenfield / brownfield / returning
  │   ├── Display: "Detected: brownfield (signals: .git, package.json, src/, .github/)"
  │   └── Confirm with operator: "Proceed with codebase mapping? [Y/n]"
  │
  ├── IF greenfield:
  │   └── Skip to P2 (no mapping needed)
  │
  ├── IF brownfield:
  │   ├── P12 Mapping Phase
  │   │   ├── Read tree structure (find/fd, depth-limited)
  │   │   ├── Read key files (package.json, Cargo.toml, go.mod, requirements.txt, etc.)
  │   │   ├── Read existing docs (README.md, CONTRIBUTING.md, docs/*.md)
  │   │   ├── [Phase 2: Git history analysis]
  │   │   ├── Claude sub-agent(s): analyze → structured findings
  │   │   └── GPT-5.2: synthesize → CODEBASE_MAP.md (YAML, <5000 tokens)
  │   │
  │   ├── P12 Confirmation Phase
  │   │   ├── Present each section to operator
  │   │   ├── Operator: confirm / edit / skip per section
  │   │   └── Write final .deadf/seed/CODEBASE_MAP.md
  │   │
  │   └── Transition to P2
  │       ├── Inject CODEBASE_MAP.md as context into P2 prompt
  │       ├── P2 brainstorm runs with "You're working with an EXISTING codebase" framing
  │       └── P2 produces VISION.md + ROADMAP.md (informed by map)
  │
  └── IF returning:
      ├── Display: "Found existing deadf(ish) state"
      ├── Offer: [R]estart / Re[f]ine / [C]ontinue
      └── [Phase 2: implement each option]
```

### Entry Point

P12 is NOT a cycle action. It runs BEFORE the loop starts.

**Why:** The cycle protocol (CLAUDE.md) is designed for the autonomous loop. P12 is interactive (requires operator confirmation) and runs once. Putting it inside the cycle protocol would require a new phase (`preflight`) and complicate the DECIDE table unnecessarily.

**Instead:** P12 is a **pre-loop script** called by `deadfish init` (or equivalent). It:
1. Runs detection + mapping
2. Writes `.deadf/seed/CODEBASE_MAP.md`
3. Passes control to `p2-brainstorm.sh` (which already handles P2)

### Handoff to P2

The P2 brainstorm prompt (`P2_MAIN.md`) already has a "Quick Mode Trigger" for users who know what they want. For brownfield, we need a parallel injection:

**New: P2 Brownfield Context Block** — injected at the TOP of the P2 prompt when CODEBASE_MAP.md exists:

```markdown
## Existing Codebase Context

This project has an EXISTING codebase. The following map was confirmed by the operator.
Use this as ground truth for the brainstorm — do NOT re-discover what's already known.
Focus brainstorm on: what to BUILD NEXT, not what already exists.

<codebase_map>
{contents of CODEBASE_MAP.md}
</codebase_map>

Adjust your Phase 1 SETUP questions:
- Skip "What are we building?" — reference the map.
- Ask: "What do you want to ADD or CHANGE?"
- Ask: "What's the biggest pain point in the current codebase?"
- Keep questions 3-5 as-is.
```

This injection happens in `p2-brainstorm.sh` (or its P12-aware wrapper), not in P2_MAIN.md itself.

### Context Enrichment Chain

```
P12 Detection → P12 Mapping → P12 Confirmation → CODEBASE_MAP.md
                                                        ↓
                                              P2 Brainstorm (enriched)
                                                        ↓
                                              VISION.md + ROADMAP.md
                                                        ↓
                                              select-track (smart loading from map)
                                                        ↓
                                              execute (track-relevant sections loaded)
```

---

## 3. Proposed Architecture

### 3.1 File Structure

```
.pipe/
├── p12/
│   ├── P12_DETECT.sh          # Brownfield detection (pure bash, no LLM)
│   ├── P12_MAP.sh             # Orchestrates mapping (calls sub-agents + GPT-5.2)
│   ├── P12_CONFIRM.sh         # Interactive confirmation (operator-facing)
│   ├── P12_INJECT.sh          # Injects map into P2 prompt
│   ├── prompts/
│   │   ├── MAPPER_AGENT.md    # Claude sub-agent prompt (analysis)
│   │   ├── SYNTHESIZER.md     # GPT-5.2 prompt (doc generation)
│   │   └── BROWNFIELD_P2.md   # P2 context injection template
│   └── templates/
│       └── CODEBASE_MAP.tmpl  # Output template (YAML skeleton)
├── p2/
│   └── (existing P2 files)
└── p12-init.sh                # Top-level entry point (calls detect → map → confirm → P2)
```

### 3.2 Detection Heuristics (P12_DETECT.sh)

Pure bash. No LLM needed. Returns exit code + JSON to stdout.

```bash
#!/bin/bash
# P12_DETECT.sh — Brownfield detection heuristics
# Exit codes: 0=brownfield, 1=greenfield, 2=returning, 3=error
# Stdout: JSON { "type": "brownfield|greenfield|returning", "signals": [...], "depth": 1-4 }

PROJECT_PATH="${1:-.}"

signals=()
score=0

# Returning detection (highest priority)
if [[ -f "$PROJECT_PATH/.deadf/seed/P2_DONE" && -f "$PROJECT_PATH/STATE.yaml" ]]; then
    echo '{"type":"returning","signals":[".deadf/seed/P2_DONE","STATE.yaml"],"depth":0}'
    exit 2
fi

# Signal detection
[[ -d "$PROJECT_PATH/.git" ]]                                    && signals+=(".git")           && score=$((score + 1))
[[ -f "$PROJECT_PATH/package.json" || -f "$PROJECT_PATH/Cargo.toml" || \
   -f "$PROJECT_PATH/go.mod" || -f "$PROJECT_PATH/requirements.txt" || \
   -f "$PROJECT_PATH/pyproject.toml" || -f "$PROJECT_PATH/Gemfile" || \
   -f "$PROJECT_PATH/pom.xml" || -f "$PROJECT_PATH/build.gradle" || \
   -f "$PROJECT_PATH/composer.json" || -f "$PROJECT_PATH/mix.exs" ]] \
                                                                  && signals+=("deps")          && score=$((score + 1))

src_count=$(find "$PROJECT_PATH" -maxdepth 3 -type f \
    \( -name '*.ts' -o -name '*.js' -o -name '*.py' -o -name '*.rs' \
       -o -name '*.go' -o -name '*.java' -o -name '*.rb' -o -name '*.ex' \
       -o -name '*.cs' -o -name '*.cpp' -o -name '*.c' -o -name '*.swift' \
       -o -name '*.kt' -o -name '*.scala' -o -name '*.php' \) \
    -not -path '*/node_modules/*' -not -path '*/.git/*' -not -path '*/vendor/*' \
    -not -path '*/target/*' -not -path '*/dist/*' -not -path '*/__pycache__/*' \
    2>/dev/null | head -200 | wc -l)
[[ "$src_count" -gt 5 ]]                                         && signals+=("source_files:$src_count") && score=$((score + 1))

[[ -d "$PROJECT_PATH/.github" || -f "$PROJECT_PATH/.gitlab-ci.yml" || \
   -f "$PROJECT_PATH/Jenkinsfile" || -f "$PROJECT_PATH/.circleci/config.yml" || \
   -f "$PROJECT_PATH/bitbucket-pipelines.yml" ]]                  && signals+=("ci")            && score=$((score + 1))

[[ -f "$PROJECT_PATH/Dockerfile" || -f "$PROJECT_PATH/docker-compose.yml" || \
   -f "$PROJECT_PATH/docker-compose.yaml" ]]                      && signals+=("docker")        && score=$((score + 1))

[[ -f "$PROJECT_PATH/README.md" || -f "$PROJECT_PATH/readme.md" ]] && signals+=("readme")       && score=$((score + 1))

[[ -d "$PROJECT_PATH/tests" || -d "$PROJECT_PATH/test" || \
   -d "$PROJECT_PATH/__tests__" || -d "$PROJECT_PATH/spec" ]]     && signals+=("tests")         && score=$((score + 1))

# Depth calculation (for Phase 2 multi-pass)
# depth 1: small project (<50 source files, <5 signals)
# depth 2: medium project (50-200 files, 5-6 signals)
# depth 3: large project (200-1000 files, 6+ signals)
# depth 4: complex project (1000+ files, monorepo markers, multiple languages)
depth=1
[[ "$src_count" -gt 50  && "$score" -ge 5 ]] && depth=2
[[ "$src_count" -gt 200 && "$score" -ge 6 ]] && depth=3
[[ "$src_count" -gt 1000 ]]                   && depth=4

# Decision: 2+ signals = brownfield
if [[ "$score" -ge 2 ]]; then
    printf '{"type":"brownfield","signals":[%s],"depth":%d,"src_count":%d}\n' \
        "$(printf '"%s",' "${signals[@]}" | sed 's/,$//')" "$depth" "$src_count"
    exit 0
else
    printf '{"type":"greenfield","signals":[%s],"depth":%d,"src_count":%d}\n' \
        "$(printf '"%s",' "${signals[@]}" | sed 's/,$//')" "$depth" "$src_count"
    exit 1
fi
```

### 3.3 Mapping Phase (P12_MAP.sh)

Orchestrates data collection → analysis → synthesis.

**Step 1: Collect raw data (bash, no LLM)**

```bash
# Tree structure (depth-limited, filtered)
find "$PROJECT_PATH" -maxdepth 4 -not -path '*/node_modules/*' \
    -not -path '*/.git/*' -not -path '*/vendor/*' -not -path '*/target/*' \
    -not -path '*/dist/*' -not -path '*/__pycache__/*' \
    -not -path '*/.next/*' -not -path '*/build/*' | head -500 > "$WORK_DIR/tree.txt"

# Dependency files (read first 100 lines of each)
for f in package.json Cargo.toml go.mod requirements.txt pyproject.toml Gemfile \
         pom.xml build.gradle composer.json mix.exs; do
    [[ -f "$PROJECT_PATH/$f" ]] && head -100 "$PROJECT_PATH/$f" > "$WORK_DIR/deps-$(basename $f)"
done

# Config files
for f in tsconfig.json .eslintrc* .prettierrc* jest.config* vitest.config* \
         webpack.config* vite.config* next.config* .env.example Makefile; do
    found=$(find "$PROJECT_PATH" -maxdepth 2 -name "$f" -type f 2>/dev/null | head -1)
    [[ -n "$found" ]] && head -50 "$found" > "$WORK_DIR/config-$(basename "$found")"
done

# Existing docs (README, CONTRIBUTING, etc.)
for f in README.md readme.md CONTRIBUTING.md docs/README.md ARCHITECTURE.md; do
    [[ -f "$PROJECT_PATH/$f" ]] && head -200 "$PROJECT_PATH/$f" > "$WORK_DIR/doc-$(basename $f)"
done

# CI config
for f in .github/workflows/*.yml .github/workflows/*.yaml .gitlab-ci.yml Jenkinsfile; do
    found=$(find "$PROJECT_PATH" -path "*/$f" -type f 2>/dev/null | head -3)
    for ff in $found; do
        head -80 "$ff" > "$WORK_DIR/ci-$(basename "$ff")"
    done
done

# Entry points (heuristic: main/index/app files)
for f in src/index.ts src/main.ts src/app.ts index.js app.js main.py app.py \
         src/main.rs src/lib.rs cmd/main.go main.go lib/application.rb; do
    [[ -f "$PROJECT_PATH/$f" ]] && head -80 "$PROJECT_PATH/$f" > "$WORK_DIR/entry-$(basename $f)"
done
```

**Step 2: Claude sub-agent analysis**

Dispatch via Task tool (CLI) or sessions_spawn (pipeline). The sub-agent receives the collected raw data and produces structured analysis.

**Step 3: GPT-5.2 synthesis**

Takes the structured analysis and produces the final CODEBASE_MAP.md in the target format.

### 3.4 Prompt Templates

#### MAPPER_AGENT.md (Claude sub-agent — analysis)

```markdown
# Codebase Analysis Agent

You are analyzing an existing codebase to produce a structured technical map.
You receive raw data (file tree, dependency files, configs, docs, entry points).
You produce a structured analysis — NOT prose. YAML only.

## Input
<raw_data>
{collected files from Step 1, concatenated with headers}
</raw_data>

## Output Contract
Produce EXACTLY this YAML structure. Every field required. Use "unknown" for genuinely undetectable items. Be conservative — only assert what the evidence directly supports.

```yaml
tech_stack:
  runtime: {language}@{version or "unknown"}
  framework: {name}@{version or "unknown"}
  db: {type or "none"}
  cache: {type or "none"}
  auth: {method or "unknown"}
  test: {framework or "none"}
  build: {tool or "none"}
  pm: {package_manager or "unknown"}
  files:
    entry: {path}
    routes: {path or "n/a"}
    models: {path or "n/a"}
    config: {path or "n/a"}
  external: {list of external services/APIs detected}
  commands:
    dev: {command or "unknown"}
    build: {command or "unknown"}
    test: {command or "unknown"}
    lint: {command or "unknown"}
  env:
    required: [{list from .env.example or "unknown"}]
    config: {env file path or "none"}
  ci:
    runner: {platform or "none"}
    deploy: {method or "unknown"}

patterns:
  architecture: {monolith|microservices|serverless|hybrid|unknown}
  code_style: {key conventions observed}
  testing: {strategy observed: unit|integration|e2e|none}
  state_management: {approach or "n/a"}
  error_handling: {approach observed}
  naming: {conventions observed}

pitfalls:
  - {each: one-line description of a code smell, anti-pattern, or technical debt signal}

risks:
  - {each: one-line description of a systemic risk, security concern, or fragility}

product:
  purpose: {one sentence from README or "unknown"}
  features: [{list of features detected from code structure}]
  architecture_notes: {key structural observation}

workflow:
  branching: {git branching strategy detected or "unknown"}
  ci_pipeline: {summary of CI steps or "none"}
  deploy_target: {detected deployment target or "unknown"}

glossary:
  - term: {domain term}
    meaning: {definition inferred from code/docs}
```

## Rules
1. Evidence-based ONLY. If you can't see it in the data, mark "unknown".
2. README claims are HINTS, not TRUTH. Cross-reference with actual files.
3. Prefer specific paths over generic descriptions.
4. If a section has no evidence, use minimal defaults (don't fabricate).
5. Pitfalls and risks: be genuinely critical. "Looks good" is not allowed.
6. Keep total output under 3000 tokens.
```

#### SYNTHESIZER.md (GPT-5.2 — final doc generation)

```markdown
# Codebase Map Synthesizer

You receive a structured analysis of an existing codebase (YAML format).
Your job: produce the final CODEBASE_MAP.md that will be loaded as context
throughout the development pipeline.

## Input
<analysis>
{output from MAPPER_AGENT}
</analysis>

## Constraints
- Output MUST be valid YAML in a markdown code fence
- Total output MUST be under 5000 tokens (hard limit — pipeline context budget)
- Every claim must trace to the analysis input (no fabrication)
- Machine-optimized: dense, scannable, no prose paragraphs
- Use the EXACT section structure below

## Output Format

```markdown
# CODEBASE_MAP

Generated: {ISO-8601 timestamp}
Confidence: {high|medium|low} (based on evidence quality)

## tech_stack
{YAML block — copied/refined from analysis}

## patterns
{YAML block — copied/refined from analysis}

## pitfalls
{YAML list — copied/refined from analysis}

## risks
{YAML list — copied/refined from analysis}

## product
{YAML block — copied/refined from analysis}

## workflow
{YAML block — copied/refined from analysis}

## glossary
{YAML list — copied/refined from analysis}
```

## Rules
1. Preserve all "unknown" markers — do NOT guess.
2. If analysis is sparse, produce a sparse map. Sparse > wrong.
3. Merge duplicate entries.
4. Sort pitfalls/risks by severity (most critical first).
5. Output ONLY the markdown document. No preamble, no explanation.
```

#### BROWNFIELD_P2.md (P2 context injection)

```markdown
## Existing Codebase Context

This is a BROWNFIELD project. An existing codebase has been mapped and confirmed by the operator.

<codebase_map>
{CODEBASE_MAP.md contents}
</codebase_map>

### Modified Phase 1 (SETUP) Instructions

The standard 5 setup questions change for brownfield:

1. ~~What are we building?~~ → "I see an existing {tech_stack.framework} project. What do you want to ADD or CHANGE?"
2. ~~Who needs this?~~ → Keep as-is (users may change for new features)
3. ~~What's the pain?~~ → "What's the biggest pain point in the CURRENT codebase?"
4. ~~Constraints?~~ → Add: "Any existing technical debt you want to address? (See pitfalls section)"
5. ~~Success in 90 days?~~ → Keep as-is

### Brainstorm Adjustments
- Reference the codebase map when the operator mentions existing features
- Anti-bias: don't anchor on existing architecture — explore alternatives too
- When organizing ideas (Phase 4), tag each as: new_feature | enhancement | refactor | fix
- VISION.md should acknowledge existing codebase context
- ROADMAP.md should include a "codebase health" track if pitfalls/risks warrant it
```

### 3.5 Confirmation Flow (P12_CONFIRM.sh)

Interactive, operator-facing. Presents each section of the generated map and asks for confirmation.

```bash
#!/bin/bash
# P12_CONFIRM.sh — Interactive confirmation of codebase map
# Reads CODEBASE_MAP.md, presents section-by-section, writes confirmed version

MAP_FILE="$1"
CONFIRMED_FILE="$2"

sections=("tech_stack" "patterns" "pitfalls" "risks" "product" "workflow" "glossary")

echo "═══════════════════════════════════════════════"
echo "  P12 Codebase Map — Confirmation"
echo "═══════════════════════════════════════════════"
echo ""

for section in "${sections[@]}"; do
    echo "── $section ──"
    # Extract section content (between ## headers)
    sed -n "/^## $section$/,/^## /p" "$MAP_FILE" | head -n -1
    echo ""
    echo "[A]ccept / [E]dit / [S]kip? "
    read -r choice
    case "$choice" in
        [Ee])
            echo "Opening in \$EDITOR..."
            # Extract section to temp file, open editor, replace
            ;;
        [Ss])
            echo "Skipped $section"
            # Mark section as unconfirmed
            ;;
        *)
            echo "Accepted $section"
            ;;
    esac
    echo ""
done

# Write confirmed map
cp "$MAP_FILE" "$CONFIRMED_FILE"
echo "✅ Codebase map confirmed: $CONFIRMED_FILE"
```

### 3.6 Top-Level Entry Point (p12-init.sh)

```bash
#!/bin/bash
# p12-init.sh — P12 brownfield detection + mapping + P2 transition
# This is the deadfish init entry point

set -uo pipefail

PROJECT_PATH="${1:-.}"
FORCE="${2:-0}"
PIPE_DIR="$PROJECT_PATH/.pipe/p12"
SEED_DIR="$PROJECT_PATH/.deadf/seed"
WORK_DIR="$PROJECT_PATH/.deadf/p12-work"

# ── Step 1: Detection ──
echo "🔍 Scanning project..."
detection=$("$PIPE_DIR/P12_DETECT.sh" "$PROJECT_PATH")
detect_rc=$?
detect_type=$(echo "$detection" | jq -r '.type')

echo ""
echo "═══════════════════════════════════════════════"
echo "  deadf(ish) — Project Detection"
echo "  Type: $detect_type"
echo "  Signals: $(echo "$detection" | jq -r '.signals | join(", ")')"
echo "═══════════════════════════════════════════════"
echo ""

case "$detect_rc" in
    0)  # Brownfield
        echo "Proceed with codebase mapping? [Y/n] "
        read -r yn
        [[ "$yn" =~ ^[Nn] ]] && { echo "Skipping mapping. Running as greenfield."; detect_type="greenfield"; }
        ;;
    1)  # Greenfield
        echo "Clean project detected. Proceeding to brainstorm."
        ;;
    2)  # Returning
        echo "Existing deadf(ish) state found."
        echo "[R]estart / Re[f]ine / [C]ontinue? "
        read -r choice
        case "$choice" in
            [Rr]) rm -rf "$SEED_DIR" "$PROJECT_PATH/STATE.yaml" ;;
            [Ff]) echo "Refine flow not yet implemented. Continuing." ;;
            [Cc]) echo "Resuming pipeline."; exit 0 ;;
        esac
        ;;
    *)  echo "Detection error"; exit 1 ;;
esac

# ── Step 2: Mapping (brownfield only) ──
if [[ "$detect_type" == "brownfield" ]]; then
    echo ""
    echo "📊 Mapping codebase..."
    mkdir -p "$WORK_DIR" "$SEED_DIR"
    
    "$PIPE_DIR/P12_MAP.sh" "$PROJECT_PATH" "$WORK_DIR" "$SEED_DIR/CODEBASE_MAP.md"
    map_rc=$?
    
    if [[ "$map_rc" -ne 0 ]]; then
        echo "⚠️  Mapping failed. Falling back to greenfield brainstorm."
    else
        # ── Step 3: Confirmation ──
        echo ""
        "$PIPE_DIR/P12_CONFIRM.sh" "$SEED_DIR/CODEBASE_MAP.md" "$SEED_DIR/CODEBASE_MAP.md"
    fi
fi

# ── Step 4: Transition to P2 ──
echo ""
echo "🧠 Starting brainstorm session..."

if [[ -f "$SEED_DIR/CODEBASE_MAP.md" ]]; then
    # Inject brownfield context into P2
    "$PIPE_DIR/P12_INJECT.sh" "$PROJECT_PATH" "$SEED_DIR/CODEBASE_MAP.md"
fi

# Run P2
"$PROJECT_PATH/.pipe/p2-brainstorm.sh" --project "$PROJECT_PATH"
```

---

## 4. Modular Architecture — Transport Targets

### Core Principle: Separate Concerns

```
┌─────────────────────────────────────────┐
│  TRANSPORT-AGNOSTIC (shared)            │
│                                         │
│  • Detection logic (P12_DETECT.sh)      │
│  • Data collection (bash scripts)       │
│  • Prompt templates (*.md)              │
│  • Output format (CODEBASE_MAP.md)      │
│  • Confirmation protocol (questions)    │
│  • Token budget enforcement             │
│  • P2 injection template                │
└─────────────────────────────────────────┘
          │            │            │
    ┌─────┴──┐   ┌────┴───┐  ┌────┴───┐
    │ CLI    │   │Pipeline│  │ Skill  │
    │Target  │   │Target  │  │Target  │
    └────────┘   └────────┘  └────────┘
```

### What's Transport-Agnostic

| Component | Why Shared |
|-----------|-----------|
| `P12_DETECT.sh` | Pure bash, reads filesystem, returns JSON. Works everywhere. |
| Data collection scripts | Pure bash, reads filesystem. Works everywhere. |
| `prompts/MAPPER_AGENT.md` | Prompt text. Model-agnostic, transport-agnostic. |
| `prompts/SYNTHESIZER.md` | Prompt text. |
| `prompts/BROWNFIELD_P2.md` | Prompt text. |
| `templates/CODEBASE_MAP.tmpl` | Output format spec. |
| Token budget enforcement | Word-count heuristic or `tiktoken`. Pure computation. |

### What Needs Transport Variants

| Component | CLI (deadfish-cli) | Pipeline (Clawdbot) | Skill (portable) |
|-----------|-------------------|---------------------|-------------------|
| **Sub-agent dispatch** | Task tool (native Claude Code) | `sessions_spawn` (Clawdbot) | Skill-native agent spawn |
| **GPT-5.2 dispatch** | `codex exec -m gpt-5.2` | Codex MCP or `codex exec` via `exec` tool | Skill-native model call |
| **Interactive confirmation** | stdin/stdout (terminal) | Discord message + reaction/reply | Skill-native UI |
| **File I/O** | Direct filesystem | Filesystem (sandbox) | Skill-defined storage |
| **P2 transition** | Call `p2-brainstorm.sh` | Signal ralph.sh / set state | Skill-defined flow |
| **Error display** | stderr + exit code | Discord message | Skill-native error |

### Target Implementation Details

#### Target 1: deadfish-cli (Claude Code CLI + codex exec)

This is the primary target. P12 runs as a bash script invoked by the operator (or by a future `deadfish init` command).

```bash
# Sub-agent dispatch (analysis)
claude --print --allowedTools "Read,Glob,Grep" \
    "$(cat prompts/MAPPER_AGENT.md | sed "s/{collected files}/$RAW_DATA/")"

# GPT-5.2 dispatch (synthesis)  
codex exec -m gpt-5.2 --skip-git-repo-check \
    "$(cat prompts/SYNTHESIZER.md | sed "s/{output from MAPPER_AGENT}/$ANALYSIS/")"

# Interactive confirmation
# Direct stdin/stdout (terminal)

# P2 transition
./p2-brainstorm.sh --project "$PROJECT_PATH"
```

#### Target 2: deadfish-pipeline (Clawdbot + sessions_spawn)

P12 runs as part of the Clawdbot agent's response to a `deadfish init` command.

```
# Sub-agent dispatch (analysis)
sessions_spawn with MAPPER_AGENT.md prompt

# GPT-5.2 dispatch (synthesis)
exec tool: codex exec -m gpt-5.2 ...

# Interactive confirmation
message tool: send each section to Discord channel
Wait for operator reply (accept/edit/skip per section)

# P2 transition
Set state, signal ralph equivalent, or directly invoke P2 runner
```

#### Target 3: deadfish skill (portable)

P12 is a skill function that can be loaded into any agent context.

```
# The skill exposes:
p12_detect(project_path) → {type, signals, depth}
p12_map(project_path, raw_data) → analysis_yaml
p12_synthesize(analysis_yaml) → codebase_map_md
p12_confirm(codebase_map_md) → confirmed_map_md  # delegates to host UI
p12_inject(confirmed_map_md, p2_prompt) → enriched_p2_prompt
```

The skill provides the logic; the host provides the transport (sub-agent spawning, model calls, UI).

---

## 5. Implementation Micro-Tasks

### Phase 1: MVP (shipped as one PR, but atomic sub-tasks)

#### MT-1: Detection Script
- **Files:** `.pipe/p12/P12_DETECT.sh`
- **Scope:** Brownfield detection heuristics, JSON output, exit codes
- **Test:** Run against known greenfield/brownfield/returning dirs
- **Acceptance:** Correctly classifies ≥5 test projects

#### MT-2: Data Collection Script
- **Files:** `.pipe/p12/P12_COLLECT.sh`
- **Scope:** Gather tree, deps, configs, docs, CI, entry points into work dir
- **Test:** Run against a real project, verify collected files are non-empty and capped
- **Acceptance:** Collects all signal types, respects depth/count limits

#### MT-3: Mapper Agent Prompt
- **Files:** `.pipe/p12/prompts/MAPPER_AGENT.md`
- **Scope:** Claude sub-agent prompt for codebase analysis
- **Test:** Feed collected data from a known project, verify YAML output is parseable and accurate
- **Acceptance:** Produces valid YAML, all sections present, no fabrication

#### MT-4: Synthesizer Prompt
- **Files:** `.pipe/p12/prompts/SYNTHESIZER.md`
- **Scope:** GPT-5.2 prompt for final doc generation
- **Test:** Feed mapper output, verify CODEBASE_MAP.md format and token count
- **Acceptance:** Output < 5000 tokens, valid markdown+YAML, matches template

#### MT-5: Mapping Orchestrator
- **Files:** `.pipe/p12/P12_MAP.sh`
- **Scope:** Calls collect → mapper agent → synthesizer, handles failures
- **Test:** End-to-end on a real project
- **Acceptance:** Produces CODEBASE_MAP.md or exits with clear error

#### MT-6: Confirmation Flow
- **Files:** `.pipe/p12/P12_CONFIRM.sh`
- **Scope:** Interactive section-by-section confirmation (stdin/stdout)
- **Test:** Manual test with sample map
- **Acceptance:** Accept/edit/skip works for each section, writes confirmed file

#### MT-7: P2 Injection
- **Files:** `.pipe/p12/P12_INJECT.sh`, `.pipe/p12/prompts/BROWNFIELD_P2.md`
- **Scope:** Injects CODEBASE_MAP.md into P2 prompt assembly
- **Test:** Verify enriched prompt contains map and modified setup questions
- **Acceptance:** p2-brainstorm.sh receives enriched prompt when map exists

#### MT-8: Entry Point + Integration
- **Files:** `.pipe/p12-init.sh`, modifications to `ralph.sh` (P2 block)
- **Scope:** Wire detect → map → confirm → P2 transition. Update ralph.sh's research phase block.
- **Test:** Full flow: init on brownfield project → map → confirm → P2 starts with context
- **Acceptance:** End-to-end greenfield and brownfield paths work

### Phase 2: Multi-Pass + Polish (future)

#### MT-9: Git History Analysis
- **Files:** `.pipe/p12/P12_GIT_SIGNALS.sh`
- **Scope:** Hot/stale file detection, repo age, commit frequency
- **Acceptance:** Adds confidence scores to map sections

#### MT-10: Parallel Mapper Agents
- **Files:** Modify `P12_MAP.sh`, add per-concern prompts
- **Scope:** 2-4 parallel sub-agents (structure, patterns, risks, product)
- **Acceptance:** Faster analysis, merged output matches single-pass quality

#### MT-11: Returning Flow
- **Files:** `.pipe/p12/P12_RETURNING.sh`
- **Scope:** Restart/Refine/Continue logic with state management
- **Acceptance:** Each option works correctly with existing STATE.yaml

#### MT-12: Dynamic Depth
- **Files:** Modify `P12_MAP.sh`
- **Scope:** Depth 2-4 passes based on detection heuristics
- **Acceptance:** Larger projects get deeper analysis automatically

---

## 6. Target Differences Summary

| Aspect | deadfish-cli | deadfish-pipeline | deadfish-skill |
|--------|-------------|-------------------|----------------|
| **Invocation** | `./p12-init.sh <path>` | Operator sends `/deadf:init` → Clawdbot handles | Host calls `p12_detect()` etc. |
| **Sub-agent spawn** | `claude --print` (CLI) or Task tool | `sessions_spawn` (Clawdbot native) | Host-provided agent API |
| **GPT-5.2 call** | `codex exec -m gpt-5.2` | `exec` tool → `codex exec` | Host-provided model API |
| **Operator interaction** | Terminal stdin/stdout | Discord messages + reactions | Host-provided UI |
| **File access** | Direct filesystem | Sandbox filesystem | Host-provided storage |
| **P2 handoff** | Calls `p2-brainstorm.sh` | Sets state + signals loop | Returns enriched prompt |
| **Error handling** | stderr + exit codes | Discord error messages | Return error objects |
| **Concurrency** | Sequential (single terminal) | Async (Discord polling) | Host-defined |
| **Session state** | Filesystem (`.deadf/p12-work/`) | Filesystem + session state | Host-provided state |

### What Stays Identical Across All Targets

1. Detection heuristics (same signals, same thresholds, same classification)
2. Data collection (same files read, same limits applied)
3. Prompt templates (same text, same output contracts)
4. Output format (CODEBASE_MAP.md is identical regardless of target)
5. Token budget (< 5000 tokens, always)
6. Confirmation protocol (same questions, different UI)
7. P2 injection template (same brownfield context block)

### Implementation Priority

1. **deadfish-cli first** — this is the primary development target, Fred uses it directly
2. **Pipeline adaptation second** — mostly transport swaps (sessions_spawn for Task tool, Discord for stdin)
3. **Skill extraction third** — factor out transport-agnostic functions into importable modules

---

## Appendix A: CODEBASE_MAP.md Example Output

For a typical Express + TypeScript project:

```markdown
# CODEBASE_MAP

Generated: 2026-07-18T14:30:00Z
Confidence: high

## tech_stack
```yaml
runtime: node@20
framework: express@4.18
db: postgres@16/prisma
cache: redis@7
auth: jwt/passport
test: vitest
build: tsup
pm: pnpm
files:
  entry: src/index.ts
  routes: src/routes/
  models: prisma/schema.prisma
  config: src/config/
external:
  - stripe (payments)
  - sendgrid (email)
commands:
  dev: pnpm dev
  build: pnpm build
  test: pnpm test
  lint: pnpm lint
env:
  required: [DATABASE_URL, JWT_SECRET, STRIPE_SECRET_KEY]
  optional: [REDIS_URL, SENTRY_DSN]
  config: .env.example
ci:
  runner: github-actions
  deploy: docker/railway
```

## patterns
```yaml
architecture: monolith
code_style: "ESM, barrel exports, zod validation"
testing: "unit + integration (vitest + supertest)"
state_management: n/a (stateless API)
error_handling: "centralized middleware, custom AppError class"
naming: "camelCase vars, PascalCase types, kebab-case files"
```

## pitfalls
```yaml
- No rate limiting on auth endpoints
- Prisma client instantiated per-request (should be singleton)
- .env.example has stale entries (DEPRECATED_KEY still listed)
- No input validation on PUT /users/:id
- Test coverage gaps in error paths
```

## risks
```yaml
- No CORS configuration (defaults to open)
- JWT tokens never expire (no exp claim)
- Database migrations not in CI pipeline
- No health check endpoint for deployment
```

## product
```yaml
purpose: "SaaS billing dashboard for freelancers"
features: [user auth, invoice CRUD, stripe checkout, email notifications, PDF export]
architecture_notes: "REST API serving React SPA (separate repo)"
```

## workflow
```yaml
branching: "main + feature branches, squash merge"
ci_pipeline: "lint → test → build → deploy (on main push)"
deploy_target: "Railway (Docker)"
```

## glossary
```yaml
- term: Invoice
  meaning: "Billable document sent to client, tracks payment status"
- term: Workspace
  meaning: "Tenant-level isolation unit (one freelancer = one workspace)"
```
```

**Token count:** ~650 tokens (well within 5000 budget, leaving room for complex projects).

---

## Appendix B: Integration Points with ralph.sh

The ralph.sh research phase block currently does:

```bash
if [[ "$PHASE" == "research" && ! -f "$PROJECT_PATH/.deadf/seed/P2_DONE" ]]; then
    log "P2 brainstorm required — launching .pipe/p2-brainstorm.sh"
    if ! "$PROJECT_PATH/.pipe/p2-brainstorm.sh" --project "$PROJECT_PATH"; then
        ...
    fi
fi
```

With P12, this becomes:

```bash
if [[ "$PHASE" == "research" && ! -f "$PROJECT_PATH/.deadf/seed/P2_DONE" ]]; then
    # P12: Run brownfield detection + mapping before P2
    if [[ ! -f "$PROJECT_PATH/.deadf/seed/P12_DONE" ]]; then
        log "P12 codebase detection — launching .pipe/p12-init.sh"
        if ! "$PROJECT_PATH/.pipe/p12-init.sh" "$PROJECT_PATH"; then
            log_err "P12 detection/mapping failed"
            # Graceful degradation: skip mapping, proceed to P2 anyway
            log "Falling back to greenfield brainstorm"
        fi
        touch "$PROJECT_PATH/.deadf/seed/P12_DONE"
    fi
    
    log "P2 brainstorm required — launching .pipe/p2-brainstorm.sh"
    if ! "$PROJECT_PATH/.pipe/p2-brainstorm.sh" --project "$PROJECT_PATH"; then
        ...
    fi
fi
```

Key design: P12 failure is NOT fatal. If mapping fails, we fall back to greenfield brainstorm. The operator still gets value — they just don't get the enriched context. This matches v5.1's "graceful degradation on agent failure" requirement.

---

*P12 Design v1.0 — Claude Opus 4.5 subagent. Ready for review.*
