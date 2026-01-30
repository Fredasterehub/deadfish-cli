#!/bin/bash
set -uo pipefail

usage() {
    cat <<'USAGE'
Usage: P12_INJECT.sh [--project <dir>] [--context-files <comma-separated>] [--dry-run]

Renders the Existing Codebase Context block for P2 (brownfield).
USAGE
}

PROJECT_PATH="."
CONTEXT_FILES=""
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
        --context-files)
            if [[ -z "${2:-}" ]]; then
                echo "Missing value for --context-files" >&2
                exit 1
            fi
            CONTEXT_FILES="$2"
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_FILE="$SCRIPT_DIR/prompts/BROWNFIELD_P2.md"

TECH_FILE="$PROJECT_PATH/TECH_STACK.md"
PRODUCT_FILE="$PROJECT_PATH/PRODUCT.md"
WORKFLOW_FILE="$PROJECT_PATH/WORKFLOW.md"
OPENQ_FILE="$PROJECT_PATH/.deadf/p12/open_questions.txt"

if [[ -n "$CONTEXT_FILES" ]]; then
    IFS=',' read -r -a files <<< "$CONTEXT_FILES"
    for f in "${files[@]}"; do
        [[ -n "$f" ]] || continue
        if [[ "$f" != /* ]]; then
            f="$PROJECT_PATH/$f"
        fi
        base="$(basename "$f")"
        case "$base" in
            TECH_STACK.md) TECH_FILE="$f" ;;
            PRODUCT.md) PRODUCT_FILE="$f" ;;
            WORKFLOW.md) WORKFLOW_FILE="$f" ;;
            open_questions.txt) OPENQ_FILE="$f" ;;
        esac
    done
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] Template: $TEMPLATE_FILE"
    echo "[dry-run] TECH_STACK: $TECH_FILE"
    echo "[dry-run] PRODUCT: $PRODUCT_FILE"
    echo "[dry-run] WORKFLOW: $WORKFLOW_FILE"
    if [[ -f "$OPENQ_FILE" ]]; then
        echo "[dry-run] OPEN_QUESTIONS: $OPENQ_FILE"
    else
        echo "[dry-run] OPEN_QUESTIONS: (from WORKFLOW)"
    fi
    exit 0
fi

if [[ ! -f "$TEMPLATE_FILE" ]]; then
    echo "Missing template: $TEMPLATE_FILE" >&2
    exit 1
fi

extract_yaml_block() {
    local file="$1"
    awk '
        BEGIN { in=0 }
        /^```yaml/ { in=1; next }
        /^```/ { if (in) exit }
        { if (in) print }
    ' "$file"
}

extract_open_questions() {
    local file="$1"
    local yaml
    yaml="$(extract_yaml_block "$file")"
    if [[ -z "$yaml" ]]; then
        return 0
    fi
    printf '%s\n' "$yaml" | awk '
        BEGIN { in=0; indent=-1 }
        /^[[:space:]]*open_questions[[:space:]]*:/ {
            in=1
            match($0, /^[[:space:]]*/)
            indent=RLENGTH
            next
        }
        {
            if (in) {
                if ($0 ~ /^[[:space:]]*$/) next
                match($0, /^[[:space:]]*/)
                cur=RLENGTH
                if (cur <= indent) exit
                print
            }
        }
    '
}

# Graceful degradation: missing docs → emit minimal context block, don't fatal (MEDIUM-3 fix)
if [[ ! -f "$TECH_FILE" ]]; then
    echo "Warning: Missing TECH_STACK file: $TECH_FILE — degrading to minimal context" >&2
    TECH_YAML="# No tech stack data available (P12 incomplete)"
else
    TECH_YAML="$(extract_yaml_block "$TECH_FILE")"
fi
if [[ ! -f "$PRODUCT_FILE" ]]; then
    echo "Warning: Missing PRODUCT file: $PRODUCT_FILE — degrading to minimal context" >&2
    PRODUCT_YAML="# No product data available (P12 incomplete)"
else
    PRODUCT_YAML="$(extract_yaml_block "$PRODUCT_FILE")"
fi

if [[ -z "$TECH_YAML" ]]; then
    echo "Warning: Empty YAML from: $TECH_FILE — using placeholder" >&2
    TECH_YAML="# Tech stack data unavailable"
fi
if [[ -z "$PRODUCT_YAML" ]]; then
    echo "Warning: Empty YAML from: $PRODUCT_FILE — using placeholder" >&2
    PRODUCT_YAML="# Product data unavailable"
fi

OPEN_QUESTIONS=""
if [[ -f "$OPENQ_FILE" && -s "$OPENQ_FILE" ]]; then
    OPEN_QUESTIONS="$(cat "$OPENQ_FILE")"
else
    if [[ -f "$WORKFLOW_FILE" ]]; then
        OPEN_QUESTIONS="$(extract_open_questions "$WORKFLOW_FILE")"
    fi
fi
if [[ -z "$OPEN_QUESTIONS" ]]; then
    OPEN_QUESTIONS="unknown"
fi

# Use ENVIRON to avoid awk -v backslash interpretation (CRITICAL-2 fix)
export P12_TECH="$TECH_YAML"
export P12_PROD="$PRODUCT_YAML"
export P12_OQ="$OPEN_QUESTIONS"

awk '
    { gsub(/\{\{TECH_STACK_YAML\}\}/, ENVIRON["P12_TECH"])
      gsub(/\{\{PRODUCT_YAML\}\}/, ENVIRON["P12_PROD"])
      gsub(/\{\{OPEN_QUESTIONS\}\}/, ENVIRON["P12_OQ"])
      print }
' "$TEMPLATE_FILE"
