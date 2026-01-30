#!/bin/bash
set -uo pipefail

usage() {
    cat <<'USAGE'
Usage: p12-init.sh [--project <dir>] [--dry-run]

Entrypoint for P12 detection, mapping, confirmation, and P2 handoff.
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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P12_DIR="$SCRIPT_DIR/p12"
DETECT_SCRIPT="$P12_DIR/P12_DETECT.sh"
MAP_SCRIPT="$P12_DIR/P12_MAP.sh"
CONFIRM_SCRIPT="$P12_DIR/P12_CONFIRM.sh"
P2_SCRIPT="$SCRIPT_DIR/p2-brainstorm.sh"

if [[ ! -f "$DETECT_SCRIPT" ]]; then
    echo "Missing P12 detect script: $DETECT_SCRIPT" >&2
    exit 1
fi

DETECT_OUTPUT="$($DETECT_SCRIPT "$PROJECT_PATH")"
detect_rc=$?

case "$detect_rc" in
    0) SCENARIO="brownfield" ;;
    1) SCENARIO="greenfield" ;;
    2) SCENARIO="returning" ;;
    *)
        echo "P12 detect failed (exit $detect_rc). Output:" >&2
        echo "$DETECT_OUTPUT" >&2
        exit 1
        ;;
 esac

depth="$(printf '%s\n' "$DETECT_OUTPUT" | sed -n 's/.*"depth"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p')"
if [[ -z "$depth" ]]; then
    depth=1
fi

echo "P12 detect: $SCENARIO (depth=$depth)"

run_map_confirm() {
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[dry-run] Would run: $MAP_SCRIPT --project '$PROJECT_PATH' --depth $depth"
        echo "[dry-run] Would run: $CONFIRM_SCRIPT --project '$PROJECT_PATH'"
        return 0
    fi

    if ! "$MAP_SCRIPT" --project "$PROJECT_PATH" --depth "$depth"; then
        echo "P12 map failed" >&2
        exit 1
    fi

    if ! "$CONFIRM_SCRIPT" --project "$PROJECT_PATH"; then
        echo "P12 confirm failed" >&2
        exit 1
    fi
}

run_p2() {
    local mode="$1"
    local force_flag="$2"
    if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "[dry-run] Would run: $P2_SCRIPT --project '$PROJECT_PATH' --context-mode $mode $force_flag"
        return 0
    fi

    if ! "$P2_SCRIPT" --project "$PROJECT_PATH" --context-mode "$mode" $force_flag; then
        echo "P2 brainstorm failed" >&2
        exit 1
    fi
}

if [[ "$SCENARIO" == "greenfield" ]]; then
    run_p2 "greenfield" ""
    exit 0
fi

if [[ "$SCENARIO" == "brownfield" ]]; then
    run_map_confirm
    run_p2 "brownfield" ""
    exit 0
fi

# Returning flow
if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "[dry-run] Returning project detected. Would prompt: [C]ontinue / [R]efresh map / Re-[B]rainstorm"
    echo "[dry-run] Continue: skip P12 and P2"
    echo "[dry-run] Refresh: run P12 map + confirm"
    echo "[dry-run] Re-brainstorm: run P2 in brownfield mode"
    exit 0
fi

while true; do
    read -r -p "Returning project detected. [C]ontinue / [R]efresh map / Re-[B]rainstorm: " choice
    case "$choice" in
        C|c)
            echo "Returning: continue (skipping P12 and P2)"
            exit 0
            ;;
        R|r)
            run_map_confirm
            exit 0
            ;;
        B|b)
            run_p2 "brownfield" "--force"
            exit 0
            ;;
        *)
            echo "Please choose C, R, or B."
            ;;
    esac
 done
