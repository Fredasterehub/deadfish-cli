#!/bin/bash
set -uo pipefail

PROJECT_PATH="."

if [[ ${#} -gt 1 ]]; then
    echo "Usage: p12-budget-check.sh [project_dir]" >&2
    exit 1
fi

if [[ ${#} -eq 1 ]]; then
    PROJECT_PATH="$1"
fi

if [[ ! -d "$PROJECT_PATH" ]]; then
    echo "Project path does not exist: $PROJECT_PATH" >&2
    exit 1
fi

if ! PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"; then
    echo "Failed to resolve project path: $PROJECT_PATH" >&2
    exit 1
fi

DOCS=(
    TECH_STACK.md
    PATTERNS.md
    PITFALLS.md
    RISKS.md
    WORKFLOW.md
    PRODUCT.md
    GLOSSARY.md
)

missing=0
for doc in "${DOCS[@]}"; do
    if [[ ! -f "$PROJECT_PATH/$doc" ]]; then
        echo "Missing doc: $PROJECT_PATH/$doc" >&2
        missing=1
    fi
 done

if [[ "$missing" -ne 0 ]]; then
    echo "Budget check failed: required docs missing" >&2
    exit 1
fi

total_tokens=0
for doc in "${DOCS[@]}"; do
    words=$(wc -w < "$PROJECT_PATH/$doc")
    tokens=$(( words * 4 / 3 ))
    total_tokens=$(( total_tokens + tokens ))
    printf '%s: words=%s tokens~=%s\n' "$doc" "$words" "$tokens"
 done

printf 'TOTAL tokens~=%s\n' "$total_tokens"

if [[ "$total_tokens" -lt 5000 ]]; then
    exit 0
fi

exit 2
