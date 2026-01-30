#!/bin/bash
set -uo pipefail

usage() {
    cat <<'USAGE'
Usage: P12_CONFIRM.sh [--project <dir>] [--dry-run]

Interactive confirmation of P12 living docs.
USAGE
}

PROJECT_PATH="."
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

P12_DIR="$PROJECT_PATH/.deadf/p12"
OUT_DIR="$P12_DIR/out"
DONE_MARKER="$P12_DIR/P12_DONE"
UNVERIFIED_MARKER="$P12_DIR/P12_UNVERIFIED"

DOCS=(
    TECH_STACK.md
    PATTERNS.md
    PITFALLS.md
    RISKS.md
    WORKFLOW.md
    PRODUCT.md
    GLOSSARY.md
)

if [[ ! -d "$OUT_DIR" ]]; then
    echo "Missing P12 output directory: $OUT_DIR" >&2
    exit 1
fi

edit_doc() {
    local src="$1"
    local dest="$2"
    local tmp
    tmp="$(mktemp)"
    cp "$src" "$tmp"
    if [[ -n "${EDITOR:-}" ]]; then
        "$EDITOR" "$tmp"
    else
        echo "EDITOR not set. Enter replacement content; finish with Ctrl-D." >&2
        cat > "$tmp"
    fi
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[dry-run] Would write edited content to: $dest"
    else
        cp "$tmp" "$dest"
        echo "Wrote: $dest"
    fi
    rm -f "$tmp"
}

SKIPPED=()

for doc in "${DOCS[@]}"; do
    src="$OUT_DIR/$doc"
    dest="$PROJECT_PATH/$doc"

    if [[ ! -f "$src" ]]; then
        echo "Missing candidate doc: $src" >&2
        SKIPPED+=("$doc")
        continue
    fi

    echo ""
    echo "===== $doc ====="
    cat "$src"

    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[dry-run] Would prompt: [C]onfirm / [E]dit / [S]kip"
        echo "[dry-run] Would write to: $dest"
        continue
    fi

    while true; do
        read -r -p "[C]onfirm / [E]dit / [S]kip: " choice
        case "$choice" in
            C|c)
                cp "$src" "$dest"
                echo "Wrote: $dest"
                break
                ;;
            E|e)
                edit_doc "$src" "$dest"
                break
                ;;
            S|s)
                SKIPPED+=("$doc")
                echo "Skipped: $doc"
                break
                ;;
            *)
                echo "Please choose C, E, or S."
                ;;
        esac
    done
 done

if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] Would write marker: $DONE_MARKER"
    if [[ ${#SKIPPED[@]} -gt 0 ]]; then
        echo "[dry-run] Would write unverified list: $UNVERIFIED_MARKER"
    fi
    exit 0
fi

mkdir -p "$P12_DIR"
if [[ ${#SKIPPED[@]} -gt 0 ]]; then
    printf '%s\n' "${SKIPPED[@]}" > "$UNVERIFIED_MARKER"
fi

touch "$DONE_MARKER"
echo "P12 confirm complete: $DONE_MARKER"
