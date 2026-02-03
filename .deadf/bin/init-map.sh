#!/bin/bash
set -uo pipefail

usage() {
    cat <<'USAGE'
Usage: P12_MAP.sh [--project <dir>] [--depth <n>] [--dry-run]

Orchestrates P12 mapping: collect -> analyze -> synthesize -> write docs.
USAGE
}

PROJECT_PATH="."
DEPTH=1
DRY_RUN=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --project)
            if [[ -z "${2:-}" ]]; then
                echo "Missing value for --project" >&2
                exit 1
            fi
            PROJECT_PATH="$2"
            shift 2
            ;;
        --depth)
            if [[ -z "${2:-}" ]]; then
                echo "Missing value for --depth" >&2
                exit 1
            fi
            DEPTH="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            if [[ "$PROJECT_PATH" == "." ]]; then
                PROJECT_PATH="$1"
                shift
            else
                echo "Unknown arg: $1" >&2
                usage >&2
                exit 1
            fi
            ;;
    esac
 done

if [[ ! -d "$PROJECT_PATH" ]]; then
    echo "Project path does not exist: $PROJECT_PATH" >&2
    exit 1
fi

if ! PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"; then
    echo "Failed to resolve project path: $PROJECT_PATH" >&2
    exit 1
fi

if [[ "$DEPTH" -lt 1 ]]; then
    DEPTH=1
fi
if [[ "$DEPTH" -gt 2 ]]; then
    DEPTH=2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPT_DIR="$SCRIPT_DIR/prompts"
TEMPLATE_FILE="$SCRIPT_DIR/templates/LIVING_DOCS.tmpl"

P12_DIR="$PROJECT_PATH/.deadf/p12"
EVIDENCE_DIR="$P12_DIR/evidence"
OUT_DIR="$P12_DIR/out"
ANALYSIS_FILE="$P12_DIR/analysis.yaml"
SYNTH_OUTPUT="$P12_DIR/synth.txt"

log() {
    printf '%s\n' "$*" >&2
}

TMP_FILES=()
cleanup() {
    for f in "${TMP_FILES[@]}"; do
        rm -f "$f"
    done
}
trap cleanup EXIT

write_fallback_analysis() {
    cat <<'YAML' > "$ANALYSIS_FILE"
p12_analysis:
  tech_stack:
    runtime: unknown
    framework: unknown
    db: none
    cache: none
    auth: unknown
    test: none
    build: none
    pm: unknown
    files:
      entry: unknown
      routes: n/a
      models: n/a
    external: []
    commands:
      dev: unknown
      build: unknown
      test: unknown
      lint: unknown
    env:
      required: [unknown]
      config: none
    ci:
      runner: none
      deploy: unknown
  architecture:
    style: unknown
    modules: []
    entry_points: []
  patterns:
    code_style: unknown
    naming: unknown
    testing: unknown
    folder_structure: unknown
  pitfalls:
    tech_debt: []
    dangerous_areas: []
  risks:
    security: []
    config: []
  product:
    features: []
    api_endpoints: []
  glossary:
    terms: []
  open_questions:
    - Unable to infer details from evidence
  confidence:
    overall: low
    notes: ["fallback: analysis unavailable"]
YAML
}

parse_marked_output() {
    local input="$1"
    local outdir="$2"
    awk -v outdir="$outdir" '
        BEGIN { in_file=0; file=""; path="" }
        /^<<<FILE:/ {
            file=$0
            sub(/^<<<FILE:/, "", file)
            sub(/>>>$/, "", file)
            if (file ~ /\\// || file ~ /\\.\\./) {
                in_file=0
                file=""
                path=""
                next
            }
            path=outdir "/" file
            print "" > path
            in_file=1
            next
        }
        /^<<<END_FILE>>>/ {
            in_file=0
            file=""
            path=""
            next
        }
        {
            if (in_file && path != "") {
                print $0 >> path
            }
        }
    ' "$input"
}

# Fallback parser: handles markdown-headed output if LLM ignores marker format (HIGH-2 fix)
# Looks for "# TECH_STACK.md", "# PATTERNS.md", etc. as section separators
parse_markdown_output() {
    local input="$1"
    local outdir="$2"
    local known_docs="TECH_STACK.md PATTERNS.md PITFALLS.md RISKS.md WORKFLOW.md PRODUCT.md GLOSSARY.md"
    awk -v outdir="$outdir" -v docs="$known_docs" '
        BEGIN {
            split(docs, arr, " ")
            for (i in arr) known[arr[i]]=1
            file=""; path=""
        }
        /^#[[:space:]]+[A-Z_]+\.md/ {
            f=$2
            if (f in known) {
                file=f
                path=outdir "/" file
                print "" > path
                next
            }
        }
        {
            if (file != "" && path != "") {
                print $0 >> path
            }
        }
    ' "$input"
}

write_fallback_docs() {
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        log "Warning: missing template file: $TEMPLATE_FILE"
        return 0
    fi
    parse_marked_output "$TEMPLATE_FILE" "$OUT_DIR"
}

if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] Would create: $P12_DIR"
    log "[dry-run] Would run: $SCRIPT_DIR/P12_COLLECT.sh --project '$PROJECT_PATH' --depth $DEPTH"
    log "[dry-run] Would analyze evidence via claude (if available)"
    log "[dry-run] Would synthesize docs via codex (if available)"
    log "[dry-run] Would write docs to: $OUT_DIR"
    exit 0
fi

mkdir -p "$P12_DIR" "$OUT_DIR"

if [[ -x "$SCRIPT_DIR/P12_COLLECT.sh" ]]; then
    if ! "$SCRIPT_DIR/P12_COLLECT.sh" --project "$PROJECT_PATH" --depth "$DEPTH"; then
        log "Warning: P12_COLLECT.sh failed; continuing with partial evidence"
    fi
else
    log "Warning: P12_COLLECT.sh not found or not executable"
fi

analysis_ok=0
if command -v claude >/dev/null 2>&1; then
    if [[ -f "$PROMPT_DIR/MAPPER_AGENT.md" ]]; then
        prompt_file="$(mktemp)"
        TMP_FILES+=("$prompt_file")
        evidence_tmp="$(mktemp)"
        TMP_FILES+=("$evidence_tmp")
        if [[ -d "$EVIDENCE_DIR" ]]; then
            while IFS= read -r f; do
                printf '### %s\n' "$(basename "$f")" >> "$evidence_tmp"
                cat "$f" >> "$evidence_tmp"
                printf '\n\n' >> "$evidence_tmp"
            done < <(find "$EVIDENCE_DIR" -type f -maxdepth 1 -print | sort)
        else
            printf '### no-evidence\nNo evidence collected.\n' > "$evidence_tmp"
        fi

        max_bytes=102400
        evidence_size=$(wc -c < "$evidence_tmp")
        if [[ "$evidence_size" -gt "$max_bytes" ]]; then
            truncated_tmp="$(mktemp)"
            TMP_FILES+=("$truncated_tmp")
            head -c "$max_bytes" "$evidence_tmp" > "$truncated_tmp"
            mv "$truncated_tmp" "$evidence_tmp"
            printf '\n[TRUNCATED: evidence exceeded 100KB limit. Analysis based on first 100KB.]\n' >> "$evidence_tmp"
        fi

        {
            cat "$PROMPT_DIR/MAPPER_AGENT.md"
            printf '\n<raw_data>\n'
            cat "$evidence_tmp"
            printf '</raw_data>\n'
        } > "$prompt_file"
        if claude --print < "$prompt_file" > "$ANALYSIS_FILE"; then
            if [[ -s "$ANALYSIS_FILE" ]]; then
                analysis_ok=1
            fi
        fi
    else
        log "Warning: missing mapper prompt: $PROMPT_DIR/MAPPER_AGENT.md"
    fi
else
    log "Warning: claude CLI not found; using fallback analysis"
fi

if [[ "$analysis_ok" -ne 1 ]]; then
    log "Warning: analysis unavailable; writing fallback analysis"
    write_fallback_analysis
fi

synth_ok=0
if command -v codex >/dev/null 2>&1; then
    if [[ -f "$PROMPT_DIR/SYNTHESIZER.md" ]]; then
        synth_prompt="$(mktemp)"
        TMP_FILES+=("$synth_prompt")
        {
            printf 'IMPORTANT: Output with file markers. Use this exact format per doc:\n'
            printf '<<<FILE:TECH_STACK.md>>>\n...\n<<<END_FILE>>>\n\n'
            awk -v analysis_file="$ANALYSIS_FILE" '
                { if ($0 ~ /\{YAML analysis from mapper agent\}/) {
                    while ((getline line < analysis_file) > 0) print line
                    close(analysis_file)
                } else {
                    print
                } }
            ' "$PROMPT_DIR/SYNTHESIZER.md"
        } > "$synth_prompt"
        if codex -m gpt-5.2 --cd "$PROJECT_PATH" < "$synth_prompt" > "$SYNTH_OUTPUT"; then
            parse_marked_output "$SYNTH_OUTPUT" "$OUT_DIR"
            # HIGH-2 fix: if marker parser found nothing, try markdown header parser
            if [[ ! -s "$OUT_DIR/TECH_STACK.md" ]]; then
                log "Warning: marker parser found no docs; trying markdown header parser"
                parse_markdown_output "$SYNTH_OUTPUT" "$OUT_DIR"
            fi
            synth_ok=1
        else
            log "Warning: codex synthesis failed; using fallback docs"
        fi
    else
        log "Warning: missing synthesizer prompt: $PROMPT_DIR/SYNTHESIZER.md"
    fi
else
    log "Warning: codex CLI not found; using fallback docs"
fi

if [[ "$synth_ok" -ne 1 ]]; then
    write_fallback_docs
else
    missing=0
    for f in TECH_STACK.md PATTERNS.md PITFALLS.md RISKS.md WORKFLOW.md PRODUCT.md GLOSSARY.md; do
        if [[ ! -s "$OUT_DIR/$f" ]]; then
            missing=1
            break
        fi
    done
    if [[ "$missing" -eq 1 ]]; then
        log "Warning: synthesized docs incomplete; using fallback docs"
        write_fallback_docs
    fi
fi

exit 0
