#!/bin/bash
set -uo pipefail

usage() {
    cat <<'USAGE'
Usage: P12_COLLECT.sh [--project <dir>] [--depth <n>]

Collects raw evidence into .deadf/p12/evidence/.
USAGE
}

PROJECT_PATH="."
DEPTH=1

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

FIND_MAX_DEPTH=4
if [[ "$DEPTH" -ge 2 ]]; then
    FIND_MAX_DEPTH=4
fi

EVIDENCE_DIR="$PROJECT_PATH/.deadf/p12/evidence"

if ! mkdir -p "$EVIDENCE_DIR"; then
    echo "Failed to create evidence dir: $EVIDENCE_DIR" >&2
    exit 1
fi

EXCLUDE_DIRS=(.git node_modules vendor dist build .deadf .venv __pycache__ .next .cache)
PRUNE_ARGS=()
for d in "${EXCLUDE_DIRS[@]}"; do
    PRUNE_ARGS+=( -name "$d" -o )
 done
PRUNE_ARGS+=( -false )

safe_name() {
    printf '%s' "$1" | tr '/ ' '__'
}

write_snippet() {
    local src="$1"
    local out="$2"
    local limit="$3"
    head -n "$limit" "$src" > "$out"
}

# tree.txt (depth 4, capped 500 entries)
(
    cd "$PROJECT_PATH" || exit 1
    find . -maxdepth "$FIND_MAX_DEPTH" \
        \( -type d \( "${PRUNE_ARGS[@]}" \) -prune \) -o -print \
        | sed 's|^\./||' \
        | grep -v '^\.$' \
        | sort \
        | head -n 500
) > "$EVIDENCE_DIR/tree.txt"

# deps-*.txt
DEP_FILES=(package.json Cargo.toml go.mod requirements.txt pyproject.toml Gemfile pom.xml build.gradle composer.json mix.exs)
DEP_FIND_ARGS=()
for f in "${DEP_FILES[@]}"; do
    DEP_FIND_ARGS+=( -name "$f" -o )
done
DEP_FIND_ARGS+=( -false )
while IFS= read -r f; do
    rel="${f#$PROJECT_PATH/}"
    out="$EVIDENCE_DIR/deps-$(safe_name "$rel").txt"
    write_snippet "$f" "$out" 100
 done < <(
    find "$PROJECT_PATH" -maxdepth "$FIND_MAX_DEPTH" \
        \( -type d \( "${PRUNE_ARGS[@]}" \) -prune \) -o \
        -type f \( "${DEP_FIND_ARGS[@]}" \) -print | sort
 )

# config-*.txt
while IFS= read -r f; do
    rel="${f#$PROJECT_PATH/}"
    out="$EVIDENCE_DIR/config-$(safe_name "$rel").txt"
    write_snippet "$f" "$out" 50
 done < <(
    find "$PROJECT_PATH" -maxdepth "$FIND_MAX_DEPTH" \
        \( -type d \( "${PRUNE_ARGS[@]}" \) -prune \) -o \
        -type f \( \
            -name "tsconfig.json" -o -name "tsconfig.*.json" \
            -o -name ".eslintrc" -o -name ".eslintrc.*" -o -name "eslint.config.*" \
            -o -name "vite.config.*" -o -name "webpack.config.*" -o -name "rollup.config.*" \
            -o -name "babel.config.*" -o -name ".babelrc" -o -name ".babelrc.*" \
            -o -name "jest.config.*" -o -name "vitest.config.*" \
            -o -name "pytest.ini" -o -name "setup.cfg" -o -name "tox.ini" \
            -o -name ".prettierrc" -o -name ".prettierrc.*" -o -name ".editorconfig" -o -name ".nvmrc" \
        \) -print | sort
 )

# doc-*.md
while IFS= read -r f; do
    rel="${f#$PROJECT_PATH/}"
    out="$EVIDENCE_DIR/doc-$(safe_name "$rel").md"
    write_snippet "$f" "$out" 200
 done < <(
    find "$PROJECT_PATH" -maxdepth "$FIND_MAX_DEPTH" \
        \( -type d \( "${PRUNE_ARGS[@]}" \) -prune \) -o \
        -type f \( -iname "README.md" -o -iname "CONTRIBUTING.md" -o -iname "ARCHITECTURE.md" -o -iname "DESIGN.md" \) -print | sort
 )

# ci-*.yml
ci_files=()
if [[ -d "$PROJECT_PATH/.github/workflows" ]]; then
    while IFS= read -r f; do
        ci_files+=("$f")
     done < <(find "$PROJECT_PATH/.github/workflows" -type f \( -name "*.yml" -o -name "*.yaml" \) -print | sort)
fi
for f in "$PROJECT_PATH/.gitlab-ci.yml" "$PROJECT_PATH/Jenkinsfile" "$PROJECT_PATH/.circleci/config.yml"; do
    if [[ -f "$f" ]]; then
        ci_files+=("$f")
    fi
 done

for f in "${ci_files[@]}"; do
    rel="${f#$PROJECT_PATH/}"
    out="$EVIDENCE_DIR/ci-$(safe_name "$rel").yml"
    write_snippet "$f" "$out" 80
 done

# entry-*.txt (main/index/app)
while IFS= read -r f; do
    rel="${f#$PROJECT_PATH/}"
    out="$EVIDENCE_DIR/entry-$(safe_name "$rel").txt"
    write_snippet "$f" "$out" 80
 done < <(
    find "$PROJECT_PATH" -maxdepth "$FIND_MAX_DEPTH" \
        \( -type d \( "${PRUNE_ARGS[@]}" \) -prune \) -o \
        -type f \( \
            -name "main.ts" -o -name "main.js" -o -name "main.py" -o -name "main.go" -o -name "main.rs" \
            -o -name "index.ts" -o -name "index.js" -o -name "index.py" \
            -o -name "app.ts" -o -name "app.js" -o -name "app.py" -o -name "app.rb" \
        \) -print | sort
 )

exit 0
