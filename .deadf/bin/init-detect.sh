#!/bin/bash
set -uo pipefail

usage() {
    cat <<'USAGE'
Usage: P12_DETECT.sh [project_dir]

Detects project scenario (greenfield|brownfield|returning) using filesystem signals.
Outputs JSON to stdout.
USAGE
}

PROJECT_PATH="."

if [[ ${#} -gt 1 ]]; then
    usage >&2
    exit 1
fi

case "${1:-}" in
    -h|--help)
        usage
        exit 0
        ;;
    "")
        ;;
    *)
        PROJECT_PATH="$1"
        ;;
 esac

if [[ ! -d "$PROJECT_PATH" ]]; then
    echo "Project path does not exist: $PROJECT_PATH" >&2
    exit 3
fi

if ! PROJECT_PATH="$(cd "$PROJECT_PATH" && pwd)"; then
    echo "Failed to resolve project path: $PROJECT_PATH" >&2
    exit 3
fi

# Short-circuit: returning projects skip expensive signal computation (HIGH-1 fix)
if [[ -f "$PROJECT_PATH/.deadf/seed/P2_DONE" && -f "$PROJECT_PATH/STATE.yaml" ]]; then
    printf '{"type":"returning","signals":[],"depth":1,"src_count":0}\n'
    exit 2
fi

EXCLUDE_DIRS=(.git node_modules vendor dist build .deadf .venv __pycache__ .next .cache)
PRUNE_ARGS=()
for d in "${EXCLUDE_DIRS[@]}"; do
    PRUNE_ARGS+=( -name "$d" -o )
done
PRUNE_ARGS+=( -false )

find_sources() {
    find "$PROJECT_PATH" -maxdepth 3 \
        \( -type d \( "${PRUNE_ARGS[@]}" \) -prune \) -o \
        -type f \
        \( \
            -name "*.c" -o -name "*.h" -o -name "*.cc" -o -name "*.cpp" -o -name "*.cxx" -o -name "*.hpp" -o -name "*.hh" -o -name "*.hxx" \
            -o -name "*.m" -o -name "*.mm" -o -name "*.swift" \
            -o -name "*.java" -o -name "*.kt" -o -name "*.kts" -o -name "*.scala" \
            -o -name "*.go" -o -name "*.rs" \
            -o -name "*.py" -o -name "*.rb" -o -name "*.php" \
            -o -name "*.js" -o -name "*.jsx" -o -name "*.mjs" -o -name "*.cjs" \
            -o -name "*.ts" -o -name "*.tsx" -o -name "*.cs" -o -name "*.fs" -o -name "*.fsx" \
            -o -name "*.lua" -o -name "*.pl" -o -name "*.pm" \
            -o -name "*.sh" -o -name "*.bash" -o -name "*.zsh" -o -name "*.ps1" \
            -o -name "*.dart" -o -name "*.erl" -o -name "*.hrl" -o -name "*.ex" -o -name "*.exs" \
            -o -name "*.clj" -o -name "*.cljs" -o -name "*.cljc" -o -name "*.hs" -o -name "*.ml" -o -name "*.mli" \
            -o -name "*.sql" -o -name "*.html" -o -name "*.htm" -o -name "*.css" -o -name "*.scss" -o -name "*.sass" -o -name "*.less" -o -name "*.vue" -o -name "*.svelte" \
        \) -print
}

src_count=0
lang_count=0

declare -A lang_seen=()

while IFS= read -r f; do
    src_count=$((src_count + 1))
    ext="${f##*.}"
    lang=""
    case "$ext" in
        js|jsx|mjs|cjs) lang="javascript" ;;
        ts|tsx) lang="typescript" ;;
        py) lang="python" ;;
        go) lang="go" ;;
        rs) lang="rust" ;;
        java) lang="java" ;;
        kt|kts) lang="kotlin" ;;
        rb) lang="ruby" ;;
        php) lang="php" ;;
        cs) lang="csharp" ;;
        fs|fsx) lang="fsharp" ;;
        swift) lang="swift" ;;
        c|h) lang="c" ;;
        cc|cpp|cxx|hpp|hh|hxx) lang="cpp" ;;
        m|mm) lang="objc" ;;
        scala) lang="scala" ;;
        dart) lang="dart" ;;
        ex|exs) lang="elixir" ;;
        erl|hrl) lang="erlang" ;;
        clj|cljs|cljc) lang="clojure" ;;
        hs) lang="haskell" ;;
        ml|mli) lang="ocaml" ;;
        lua) lang="lua" ;;
        pl|pm) lang="perl" ;;
        sh|bash|zsh) lang="shell" ;;
        ps1) lang="powershell" ;;
        sql) lang="sql" ;;
        html|htm|css|scss|sass|less|vue|svelte) lang="web" ;;
        *) lang="" ;;
    esac
    if [[ -n "$lang" ]]; then
        lang_seen["$lang"]=1
    fi
 done < <(find_sources)

lang_count=${#lang_seen[@]}

sig_git=0
sig_source=0
sig_deps=0
sig_ci=0
sig_docker=0
sig_readme=0
sig_tests=0

if [[ -d "$PROJECT_PATH/.git" ]]; then
    sig_git=1
fi

if [[ "$src_count" -ge 5 ]]; then
    sig_source=1
fi

DEP_FILES=(package.json Cargo.toml go.mod requirements.txt pyproject.toml Gemfile pom.xml build.gradle composer.json mix.exs)
for f in "${DEP_FILES[@]}"; do
    if find "$PROJECT_PATH" -maxdepth 3 \
        \( -type d \( "${PRUNE_ARGS[@]}" \) -prune \) -o \
        -type f -name "$f" -print -quit | grep -q .; then
        sig_deps=1
        break
    fi
 done

if [[ -d "$PROJECT_PATH/.github/workflows" || -d "$PROJECT_PATH/.circleci" ]]; then
    sig_ci=1
fi
if [[ "$sig_ci" -eq 0 ]]; then
    if find "$PROJECT_PATH" -maxdepth 3 \
        \( -type d \( "${PRUNE_ARGS[@]}" \) -prune \) -o \
        -type f \( -name ".gitlab-ci.yml" -o -name "Jenkinsfile" \) -print -quit | grep -q .; then
        sig_ci=1
    fi
fi

if find "$PROJECT_PATH" -maxdepth 3 \
    \( -type d \( "${PRUNE_ARGS[@]}" \) -prune \) -o \
    -type f \( -name "Dockerfile" -o -name "docker-compose.yml" -o -name "docker-compose.yaml" \) -print -quit | grep -q .; then
    sig_docker=1
fi

if [[ -f "$PROJECT_PATH/README.md" ]]; then
    sig_readme=1
fi

if find "$PROJECT_PATH" -maxdepth 3 \
    \( -type d \( "${PRUNE_ARGS[@]}" \) -prune \) -o \
    -type d \( -name "tests" -o -name "test" -o -name "__tests__" -o -name "spec" \) -print -quit | grep -q .; then
    sig_tests=1
fi

signals=()
if [[ "$sig_git" -eq 1 ]]; then signals+=("sig_git"); fi
if [[ "$sig_source" -eq 1 ]]; then signals+=("sig_source"); fi
if [[ "$sig_deps" -eq 1 ]]; then signals+=("sig_deps"); fi
if [[ "$sig_ci" -eq 1 ]]; then signals+=("sig_ci"); fi
if [[ "$sig_docker" -eq 1 ]]; then signals+=("sig_docker"); fi
if [[ "$sig_readme" -eq 1 ]]; then signals+=("sig_readme"); fi
if [[ "$sig_tests" -eq 1 ]]; then signals+=("sig_tests"); fi

brownfield_score=$((sig_git + sig_source + sig_deps + sig_ci))

# Depth selection (MVP: 1-2 only)
depth=1
if [[ "$src_count" -ge 200 || "$sig_readme" -eq 0 || "$lang_count" -ge 2 ]]; then
    depth=2
fi

json_signals=""
if [[ ${#signals[@]} -gt 0 ]]; then
    json_signals="\"${signals[0]}\""
    for ((i=1; i<${#signals[@]}; i++)); do
        json_signals+=",\"${signals[$i]}\""
    done
fi

if [[ "$brownfield_score" -ge 2 ]]; then
    printf '{"type":"brownfield","signals":[%s],"depth":%s,"src_count":%s}\n' "$json_signals" "$depth" "$src_count"
    exit 0
fi

printf '{"type":"greenfield","signals":[%s],"depth":%s,"src_count":%s}\n' "$json_signals" "$depth" "$src_count"
exit 1
