#!/bin/bash
set -uo pipefail

usage() {
    cat <<'USAGE'
Usage: p2-brainstorm.sh [--project <path>] [--force] [--dry-run] [--context-mode greenfield|brownfield] [--context-files <comma-separated>]

Runs the P2 brainstorm interactive session using Codex.

Options:
  --project <path>   Project root (default: .)
  --force            Re-run even if .deadf/seed/P2_DONE exists
  --dry-run          Validate inputs and exit without launching Codex
  --context-mode     greenfield|brownfield (default: auto)
  --context-files    Comma-separated file paths to use for context injection
  -h, --help         Show this help
USAGE
}

PROJECT_PATH="."
FORCE=0
DRY_RUN=0
CONTEXT_MODE="auto"
CONTEXT_FILES=""

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
        --force)
            FORCE=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        --context-mode)
            if [[ -z "${2:-}" ]]; then
                echo "Missing value for --context-mode" >&2
                exit 1
            fi
            CONTEXT_MODE="$2"
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
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown arg: $1" >&2
            usage >&2
            exit 1
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

PROMPT_FILE="$PROJECT_PATH/.deadf/templates/bootstrap/seed-project-docs.md"
PROMPT_DIR="$(dirname "$PROMPT_FILE")"
SEED_DIR="$PROJECT_PATH/.deadf/seed"
P2_DONE="$SEED_DIR/P2_DONE"
VISION_FILE="$PROJECT_PATH/VISION.md"
ROADMAP_FILE="$PROJECT_PATH/ROADMAP.md"
P12_DONE="$PROJECT_PATH/.deadf/p12/P12_DONE"
TECH_STACK_FILE="$PROJECT_PATH/TECH_STACK.md"
PRODUCT_FILE="$PROJECT_PATH/PRODUCT.md"

if [[ -f "$P2_DONE" && "$FORCE" -ne 1 ]]; then
    echo "P2 already completed: $P2_DONE"
    exit 0
fi

if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "Missing prompt template: $PROMPT_FILE" >&2
    exit 1
fi

if ! mkdir -p "$SEED_DIR"; then
    echo "Failed to create seed dir: $SEED_DIR" >&2
    exit 1
fi

command -v codex &>/dev/null || { echo "codex CLI required but not found" >&2; exit 1; }

case "$CONTEXT_MODE" in
    auto|greenfield|brownfield)
        ;;
    *)
        echo "Invalid --context-mode: $CONTEXT_MODE (expected greenfield|brownfield|auto)" >&2
        exit 1
        ;;
esac

if [[ "$CONTEXT_MODE" == "auto" ]]; then
    if [[ -n "$CONTEXT_FILES" ]]; then
        CONTEXT_MODE="brownfield"
    elif [[ -f "$P12_DONE" && -f "$TECH_STACK_FILE" && -f "$PRODUCT_FILE" ]]; then
        CONTEXT_MODE="brownfield"
    else
        CONTEXT_MODE="greenfield"
    fi
fi

INJECT_SCRIPT="$PROJECT_PATH/.deadf/bin/init-inject.sh"

if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] Context mode: $CONTEXT_MODE"
    if [[ "$CONTEXT_MODE" == "brownfield" ]]; then
        echo "[dry-run] Would inject context via: $INJECT_SCRIPT"
        if [[ -n "$CONTEXT_FILES" ]]; then
            echo "[dry-run] Context files: $CONTEXT_FILES"
        else
            echo "[dry-run] Context files: $TECH_STACK_FILE, $PRODUCT_FILE, $PROJECT_PATH/WORKFLOW.md"
        fi
        if [[ -x "$INJECT_SCRIPT" || -f "$INJECT_SCRIPT" ]]; then
            "$INJECT_SCRIPT" --project "$PROJECT_PATH" ${CONTEXT_FILES:+--context-files "$CONTEXT_FILES"} --dry-run || true
        fi
    else
        echo "[dry-run] Would not inject context"
    fi
    echo "[dry-run] Would run: codex -m gpt-5.2 --cd '$PROJECT_PATH' < '<prompt_file>'"
    exit 0
fi

prompt=""
if [[ "$CONTEXT_MODE" == "brownfield" ]]; then
    if [[ ! -f "$INJECT_SCRIPT" ]]; then
        echo "Missing injector script: $INJECT_SCRIPT" >&2
        exit 1
    fi
    if ! context_block="$("$INJECT_SCRIPT" --project "$PROJECT_PATH" ${CONTEXT_FILES:+--context-files "$CONTEXT_FILES"} )"; then
        echo "Failed to build brownfield context" >&2
        exit 1
    fi
    prompt+="$context_block"$'\n\n'
fi

prompt+="$(cat "$PROMPT_FILE")"
missing_subprompts=()
for f in "$PROMPT_DIR"/P2_{A,A2,B,C,D,E,F,G}.md; do
    if [[ -f "$f" ]]; then
        prompt+=$'\n\n'"$(cat "$f")"
    else
        missing_subprompts+=("$(basename "$f")")
    fi
done
if [[ ${#missing_subprompts[@]} -gt 0 ]]; then
    echo "Warning: missing sub-prompts: ${missing_subprompts[*]}" >&2
fi

prompt_file="$(mktemp)"
trap 'rm -f "$prompt_file"' EXIT
printf '%s\n' "$prompt" > "$prompt_file"

codex -m gpt-5.2 --cd "$PROJECT_PATH" < "$prompt_file"
exit_code=$?

if [[ "$exit_code" -ne 0 ]]; then
    echo "Codex session failed with exit code $exit_code" >&2
    exit "$exit_code"
fi

if [[ ! -s "$VISION_FILE" || ! -s "$ROADMAP_FILE" ]]; then
    echo "P2 outputs missing or empty: VISION.md and/or ROADMAP.md" >&2
    exit 1
fi

touch "$P2_DONE"
echo "P2 complete: $P2_DONE"
